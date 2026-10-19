#!/usr/bin/env python3
"""Real-TUI regression tests. Usage: python3 tests/terminal.py /path/to/bin/nvim."""

import argparse
import ctypes
import errno
import fcntl
import json
import os
from pathlib import Path
import platform
import pty
import re
import select
import signal
import socket
import struct
import subprocess
import sys
import tempfile
import termios
import threading
import time


class Failure(Exception):
    pass


def check(condition, message):
    if not condition:
        raise Failure(message)


def isolate_processes():
    """Keep Unix RPC working, but deny network sockets, including in plugins' jobs."""
    architectures = {
        "x86_64": (0xC000003E, 41),
        "aarch64": (0xC00000B7, 198),
    }
    check(
        sys.platform == "linux" and platform.machine() in architectures,
        "Network isolation requires Linux x86_64 or aarch64 (seccomp).",
    )
    check(Path("/proc/self/stat").is_file(), "Child-process cleanup requires /proc.")
    arch, socket_syscall = architectures[platform.machine()]

    class Instruction(ctypes.Structure):
        _fields_ = [
            ("code", ctypes.c_ushort),
            ("jt", ctypes.c_ubyte),
            ("jf", ctypes.c_ubyte),
            ("k", ctypes.c_uint),
        ]

    class Program(ctypes.Structure):
        _fields_ = [
            ("length", ctypes.c_ushort),
            ("instructions", ctypes.POINTER(Instruction)),
        ]

    # Validate the syscall ABI, then allow socket() only for AF_UNIX.
    instructions = (Instruction * 9)(
        Instruction(0x20, 0, 0, 4),
        Instruction(0x15, 1, 0, arch),
        Instruction(0x06, 0, 0, 0x80000000),
        Instruction(0x20, 0, 0, 0),
        Instruction(0x15, 0, 3, socket_syscall),
        Instruction(0x20, 0, 0, 16),
        Instruction(0x15, 1, 0, socket.AF_UNIX),
        Instruction(0x06, 0, 0, 0x00050000 | errno.ENETUNREACH),
        Instruction(0x06, 0, 0, 0x7FFF0000),
    )
    program = Program(len(instructions), instructions)
    libc = ctypes.CDLL(None, use_errno=True)
    libc.prctl.argtypes = [
        ctypes.c_int,
        ctypes.c_ulong,
        ctypes.c_void_p,
        ctypes.c_ulong,
        ctypes.c_ulong,
    ]
    # Adopt orphaned plugin jobs so teardown can kill and reap them as well.
    for option, value in ((36, 1), (38, 1), (22, 2)):
        argument = ctypes.byref(program) if option == 22 else None
        if libc.prctl(option, value, argument, 0, 0) != 0:
            raise Failure(f"prctl({option}) failed: {os.strerror(ctypes.get_errno())}")


STATE = """
local wins = {}
for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
  local buf = vim.api.nvim_win_get_buf(win)
  local pos = vim.api.nvim_win_get_position(win)
  wins[#wins + 1] = {
    id = win, name = vim.api.nvim_buf_get_name(buf), ft = vim.bo[buf].filetype,
    col = pos[2], width = vim.api.nvim_win_get_width(win),
    floating = vim.api.nvim_win_get_config(win).relative ~= '',
  }
end
return {
  started = vim.v.vim_did_enter == 1,
  name = vim.api.nvim_buf_get_name(0), ft = vim.bo.filetype,
  win = vim.api.nvim_get_current_win(), tab = vim.api.nvim_get_current_tabpage(),
  tabs = vim.api.nvim_list_tabpages(),
  columns = vim.o.columns, lines = vim.o.lines, wins = wins,
  uis = vim.api.nvim_list_uis(),
}
"""

ERROR_PATTERN = re.compile(
    r"\bE\d+:|Error detected|Error executing|stack traceback|"
    r"module ['\"][^\n]+['\"] not found",
    re.IGNORECASE,
)


def trees(state):
    return [win for win in state["wins"] if win["ft"] == "NvimTree"]


def layout(state, visible, file=None):
    sidebar = trees(state)
    correct = (
        len(sidebar) == 1
        and sidebar[0]["col"] == 0
        and sidebar[0]["width"] == 30
        and not sidebar[0]["floating"]
    )
    return (correct if visible else not sidebar) and (
        file is None or state["name"] == str(file)
    )


class Terminal:
    def __init__(self, executable, root):
        self.executable = executable
        self.root = root
        self.socket = root / "rpc.sock"
        self.process = None
        self.master = None
        self.reader = None
        self.stopping = threading.Event()
        self.output = bytearray()
        self.deadline = time.monotonic() + 150
        self.stage = "launch"
        self.env = {
            "PATH": os.environ.get("PATH", os.defpath),
            "TERM": "xterm-256color",
            "COLORTERM": "truecolor",
            "LANG": "C.UTF-8",
            "LC_ALL": "C.UTF-8",
            "SHELL": "/bin/sh",
            "HOME": str(root / "home"),
            "TMPDIR": str(root / "tmp"),
            "NVIM_LOG_FILE": str(root / "nvim.log"),
            "DBUS_SESSION_BUS_ADDRESS": f"unix:path={root}/no-session-bus",
            "SSH_ASKPASS": "/bin/false",
            "GIT_SSH_COMMAND": "/bin/false",
        }
        for kind in (
            "CONFIG_HOME",
            "DATA_HOME",
            "STATE_HOME",
            "CACHE_HOME",
            "RUNTIME_DIR",
        ):
            self.env[f"XDG_{kind}"] = str(root / kind.lower())
        for key in (
            "HOME",
            "TMPDIR",
            "XDG_CONFIG_HOME",
            "XDG_DATA_HOME",
            "XDG_STATE_HOME",
            "XDG_CACHE_HOME",
            "XDG_RUNTIME_DIR",
        ):
            Path(self.env[key]).mkdir(mode=0o700)

    def start(self):
        self.master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 48, 160, 0, 0))
        try:
            # No threads exist yet. Give nvim a controlling terminal, not just tty FDs.
            self.process = subprocess.Popen(
                [
                    self.executable,
                    "--listen",
                    str(self.socket),
                    "-i",
                    "NONE",
                    "--cmd",
                    "let g:loaded_wakatime = 1",
                ],
                stdin=slave,
                stdout=slave,
                stderr=slave,
                cwd=self.root,
                env=self.env,
                start_new_session=True,
                preexec_fn=lambda: fcntl.ioctl(0, termios.TIOCSCTTY, 0),
            )
        finally:
            os.close(slave)
        os.set_blocking(self.master, False)
        self.reader = threading.Thread(target=self.drain, daemon=True)
        self.reader.start()
        until = time.monotonic() + 25
        while not self.socket.exists():
            check(
                self.process.poll() is None,
                "Neovim exited before creating its RPC socket.",
            )
            check(
                time.monotonic() < until,
                "Neovim did not create its RPC socket within 25s.",
            )
            time.sleep(0.05)

    def drain(self):
        pending = b""
        replies = {
            b"\x1b]10;?\x07": b"\x1b]10;rgb:ffff/ffff/ffff\x1b\\",
            b"\x1b]11;?\x07": b"\x1b]11;rgb:0000/0000/0000\x1b\\",
            b"\x1b[5n": b"\x1b[0n",
            b"\x1b[c": b"\x1b[?1;2c",
        }
        while not self.stopping.is_set():
            try:
                if select.select([self.master], [], [], 0.1)[0]:
                    chunk = os.read(self.master, 65536)
                    if not chunk:
                        break
                    self.output.extend(chunk)
                    del self.output[:-65536]
                    # Answer xterm color/status queries; preserve split escape sequences.
                    pending += chunk
                    for query, reply in replies.items():
                        while query in pending:
                            pending = pending.replace(query, b"", 1)
                            os.write(self.master, reply)
                    pending = pending[-32:]
            except OSError as error:
                if error.errno != errno.EIO:
                    self.output.extend(f"\nPTY read error: {error}".encode())
                break

    def lua(self, code):
        remaining = self.deadline - time.monotonic()
        check(remaining > 0, "Overall 150s test deadline exceeded.")
        script = (
            "(function() local ok, value = pcall(function() "
            + code
            + " end); return vim.json.encode({ok = ok, value = value}) end)()"
        )
        expression = "luaeval('" + script.replace("'", "''") + "')"
        try:
            result = subprocess.run(
                [
                    self.executable,
                    "--server",
                    str(self.socket),
                    "--remote-expr",
                    expression,
                ],
                cwd=self.root,
                env=self.env,
                capture_output=True,
                text=True,
                timeout=min(5, remaining),
            )
        except subprocess.TimeoutExpired as error:
            raise Failure(
                "RPC timed out (5s); Neovim may be stuck at a prompt."
            ) from error
        check(
            result.returncode == 0,
            f"RPC exited {result.returncode}: {result.stdout}\n{result.stderr}",
        )
        try:
            response = json.loads(result.stdout)
        except ValueError as error:
            raise Failure(
                f"Invalid RPC response: {result.stdout!r}; stderr={result.stderr!r}"
            ) from error
        check(response["ok"], f"Lua inspection failed: {response.get('value')}")
        return response.get("value")

    def send(self, keys):
        until = time.monotonic() + 3
        while keys:
            check(time.monotonic() < until, "PTY input timed out.")
            if select.select([], [self.master], [], 0.1)[1]:
                keys = keys[os.write(self.master, keys) :]

    def edit(self, file, command="edit"):
        escaped = self.lua(f"return vim.fn.fnameescape({json.dumps(str(file))})")
        self.send(f":{command} {escaped}\r".encode())

    def resize(self, columns, lines):
        fcntl.ioctl(
            self.master, termios.TIOCSWINSZ, struct.pack("HHHH", lines, columns, 0, 0)
        )
        os.kill(self.process.pid, signal.SIGWINCH)

    def wait(self, label, predicate, timeout=8):
        self.stage = label
        until = min(time.monotonic() + timeout, self.deadline)
        stable = None
        state = None
        while time.monotonic() < until:
            check(self.process.poll() is None, f"Neovim exited during {label}.")
            state = self.lua(STATE)
            if predicate(state):
                stable = stable or time.monotonic()
                # Catch scheduled autocmds that briefly satisfy the assertion then undo it.
                if time.monotonic() - stable >= 0.35:
                    print(f"PASS {label}", flush=True)
                    return state
            else:
                stable = None
            time.sleep(0.05)
        raise Failure(
            f"Timed out waiting for {label}; last state:\n{json.dumps(state, indent=2)}"
        )

    def errors(self):
        return self.lua("""
return {
  errmsg = vim.v.errmsg,
  messages = vim.api.nvim_exec2('messages', {output = true}).output,
  notifications = _G.terminal_test_errors or {},
}
""")

    def check_errors(self, label):
        errors = self.errors()
        check(
            not errors["errmsg"]
            and not errors["notifications"]
            and not ERROR_PATTERN.search(errors["messages"]),
            f"{label}: Neovim reported errors:\n{json.dumps(errors, indent=2)}",
        )

    def diagnostics(self):
        try:
            print(
                "Neovim diagnostics: " + json.dumps(self.errors(), indent=2),
                file=sys.stderr,
            )
        except (Failure, OSError) as error:
            print(f"Diagnostics unavailable: {error}", file=sys.stderr)
        # repr prevents captured terminal escapes from corrupting the caller's terminal.
        print(
            "PTY tail: " + repr(bytes(self.output[-8000:]).decode(errors="replace")),
            file=sys.stderr,
        )

    def close(self):
        try:
            if self.process is not None and self.process.poll() is None:
                try:
                    self.send(b"\x1b:qa!\r")
                    self.process.wait(timeout=2)
                except (Failure, OSError, subprocess.TimeoutExpired):
                    pass
        finally:
            try:
                # Include jobs that changed process groups or were orphaned during :qa!.
                for sig in (signal.SIGTERM, signal.SIGKILL):
                    parents = {}
                    for stat in Path("/proc").glob("[0-9]*/stat"):
                        try:
                            fields = stat.read_text().rsplit(")", 1)[1].split()
                            parents[int(stat.parent.name)] = int(fields[1])
                        except (OSError, ValueError, IndexError):
                            continue
                    descendants = {os.getpid()}
                    while True:
                        found = {
                            pid
                            for pid, parent in parents.items()
                            if parent in descendants
                        }
                        if found <= descendants:
                            break
                        descendants.update(found)
                    for pid in descendants - {os.getpid()}:
                        try:
                            os.kill(pid, sig)
                        except ProcessLookupError:
                            pass
                    time.sleep(0.1)
                if self.process is not None:
                    self.process.wait(timeout=3)
                until = time.monotonic() + 2
                while time.monotonic() < until:
                    try:
                        pid, _ = os.waitpid(-1, os.WNOHANG)
                        if pid == 0:
                            time.sleep(0.05)
                    except ChildProcessError:
                        break
                else:
                    raise Failure(
                        "Child processes remain after teardown's 2s reap deadline."
                    )
            finally:
                self.stopping.set()
                if self.reader is not None:
                    self.reader.join(timeout=1)
                if self.master is not None:
                    os.close(self.master)


def regress(terminal):
    first, second = terminal.root / "alpha.txt", terminal.root / "beta.txt"
    first.write_text("First local regression fixture.\n")
    second.write_text("Second local regression fixture.\n")
    terminal.start()
    terminal.wait(
        "startup dashboard has a real 160x48 UI and no tree",
        lambda s: (
            s["started"]
            and s["ft"] == "ministarter"
            and layout(s, False)
            and (s["columns"], s["lines"]) == (160, 48)
            and any(
                ui["width"] == 160
                and ui["height"] == 48
                and ui["stdin_tty"]
                and ui["stdout_tty"]
                for ui in s["uis"]
            )
        ),
        timeout=25,
    )
    terminal.check_errors("Startup :messages / v:errmsg")
    terminal.lua("""
_G.terminal_test_errors = {}
local original = vim.notify
vim.notify = function(message, level, options)
  if level and level >= vim.log.levels.ERROR then
    table.insert(_G.terminal_test_errors, tostring(message))
  end
  return original(message, level, options)
end
return true
""")

    terminal.edit(first)
    terminal.wait(
        "local file opens a left 30-column tree without stealing focus",
        lambda s: layout(s, True, first),
    )
    terminal.edit(second)
    terminal.wait(
        "second local buffer retains file focus", lambda s: layout(s, True, second)
    )
    terminal.stage = "bufferline file entries and cycle mappings"
    tabline = terminal.lua("""
return vim.api.nvim_eval_statusline(vim.o.tabline, {
  use_tabline = true, maxwidth = vim.o.columns,
}).str
""")
    check(
        first.name in tabline and second.name in tabline,
        f"Rendered bufferline is missing file entries: {tabline!r}",
    )
    mappings = terminal.lua("""
return {next = vim.fn.maparg(' <S-Tab>', 'n'), previous = vim.fn.maparg(' <Tab>', 'n')}
""")
    # With two files, next and previous reach the same buffer; check direction too.
    check(
        "BufferLineCycleNext" in mappings["next"]
        and "BufferLineCyclePrev" in mappings["previous"],
        f"Unexpected buffer-cycle mappings: {mappings}",
    )
    terminal.send(b" \x1b[Z")
    terminal.wait(
        "literal Space Shift-Tab cycles next", lambda s: layout(s, True, first)
    )
    terminal.send(b" \t")
    terminal.wait(
        "literal Space Tab cycles previous (roundtrip)",
        lambda s: layout(s, True, second),
    )

    terminal.stage = "bufferline close callbacks preserve unsaved changes"
    terminal.lua("""
local options = require('bufferline.config').options
assert(type(options.close_command) == 'function', 'close_command must be a safe function')
assert(options.close_command == options.right_mouse_command, 'close callbacks must be identical')
local buf = vim.api.nvim_get_current_buf()
local original = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
local was_modified = vim.bo[buf].modified
local changed = vim.list_extend(vim.deepcopy(original), {'Unsaved regression change.'})
local confirm, calls = vim.fn.confirm, 0
local ok, err = pcall(function()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, changed)
  vim.fn.confirm = function()
    calls = calls + 1
    return 1
  end
  for index, close in ipairs({options.close_command, options.right_mouse_command}) do
    close(buf)
    assert(calls == index, 'safe close must ask before discarding changes')
    assert(vim.api.nvim_buf_is_valid(buf), 'refused close deleted the buffer')
    assert(vim.bo[buf].modified, 'refused close cleared the modified flag')
    assert(vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), changed),
      'refused close changed unsaved contents')
  end
end)
-- Restore the function and fixture even when a close assertion fails.
vim.fn.confirm = confirm
if vim.api.nvim_buf_is_valid(buf) then
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, original)
  vim.bo[buf].modified = was_modified
end
assert(ok, err)
return true
""")
    terminal.wait(
        "refusing bufferline close preserves unsaved changes and file focus",
        lambda s: layout(s, True, second),
    )

    for columns, lines, visible in (
        (80, 48, False),
        (160, 48, True),
        (160, 24, False),
        (160, 48, True),
    ):
        terminal.resize(columns, lines)
        terminal.wait(
            f"resize {columns}x{lines}: tree {'restored' if visible else 'hidden'}",
            lambda s: (s["columns"], s["lines"]) == (columns, lines)
            and layout(s, visible, second),
        )

    directory = terminal.root / "directory"
    directory.mkdir()
    for columns in (160, 80):
        terminal.resize(columns, 48)
        terminal.edit(directory)
        terminal.wait(
            f":edit directory at {columns} columns opens full-width Oil without a tree",
            lambda s: s["ft"] == "oil"
            and s["columns"] == columns
            and layout(s, False)
            and any(
                win["id"] == s["win"]
                and not win["floating"]
                and win["col"] == 0
                and win["width"] == columns
                for win in s["wins"]
            ),
        )
        terminal.edit(second)
        terminal.wait(
            f"restore file after Oil at {columns} columns",
            lambda s: layout(s, columns == 160, second),
        )
    terminal.resize(160, 48)
    terminal.wait(
        "restore wide file layout after directory browsing",
        lambda s: s["columns"] == 160 and layout(s, True, second),
    )

    terminal.send(b"\x05")
    terminal.wait("Ctrl-E manually hides the tree", lambda s: layout(s, False, second))
    for file in (first, second):
        terminal.edit(file)
        terminal.wait(
            f"manual hide survives switching to {file.name}",
            lambda s: layout(s, False, file),
        )
    terminal.send(b"\x05")
    state = terminal.wait("Ctrl-E reenables the tree", lambda s: layout(s, True))
    if state["ft"] == "NvimTree":
        terminal.send(b"\x17p")
    terminal.wait("return from explorer to file", lambda s: layout(s, True, second))

    terminal.lua("MiniStarter.open(); return true")
    home = terminal.wait(
        "MiniStarter.open closes the tree",
        lambda s: s["ft"] == "ministarter" and layout(s, False),
    )["tab"]
    terminal.edit(first, "tabedit")
    terminal.wait(
        "file tab has its own automatic tree",
        lambda s: s["tab"] != home and layout(s, True, first),
    )
    # MiniStarter's letter-query mappings intercept normal-mode gt.
    for keys, homepage in (
        (b":tabprevious\r", True),
        (b":tabnext\r", False),
        (b":tabprevious\r", True),
        (b":tabnext\r", False),
    ):
        terminal.send(keys)
        terminal.wait(
            "tab switch: "
            + ("homepage stays tree-free" if homepage else "file tree restored"),
            lambda s: (
                (s["tab"] == home and s["ft"] == "ministarter" and layout(s, False))
                if homepage
                else (s["tab"] != home and layout(s, True, first))
            ),
        )

    terminal.send(b" ssh")
    terminal.wait(
        "literal Space ssh opens a real Telescope prompt",
        lambda s: s["ft"] == "TelescopePrompt",
    )
    picker = terminal.lua("""
local picker = require('telescope.actions.state').get_current_picker(vim.api.nvim_get_current_buf())
return {title = picker.prompt_title, count = picker.manager:num_results()}
""")
    check(
        "Remote - SSH" in picker["title"] and picker["count"] > 0,
        f"Wrong Telescope menu: {picker}",
    )
    commands = terminal.lua("""
local commands = {}
for _, name in ipairs({'RemoteSessionPicker', 'RemoteOpen', 'RemoteTreeBrowser', 'RemoteTerminalNew'}) do
  commands[name] = vim.fn.exists(':' .. name)
end
return commands
""")
    check(
        all(value == 2 for value in commands.values()),
        f"Remote commands missing: {commands}",
    )
    # Cancel, never select an SSH action or supply a hostname.
    terminal.send(b"\x03")
    terminal.wait(
        "cancel SSH menu without connecting",
        lambda s: layout(s, True, first)
        and all(win["ft"] != "TelescopePrompt" for win in s["wins"]),
    )
    check(
        terminal.lua("return require('async-remote-write.config').config.autosave")
        is False,
        "Remote autosave must be false after the real remote-ssh setup.",
    )

    terminal.stage = "pomo and blink-ripgrep module loading"
    check(
        terminal.lua("""
require('lz.n').trigger_load('pomo-nvim')
return type(require('pomo').setup) == 'function' and vim.fn.exists(':TimerStart') == 2
"""),
        "pomo did not load / register TimerStart.",
    )
    check(
        terminal.lua("return type(require('blink-ripgrep')) == 'table'"),
        "blink-ripgrep module did not load.",
    )
    state = terminal.wait(
        "plugin load smoke checks leave the file UI intact",
        lambda s: layout(s, True, first),
    )

    (terminal.root / ".luarc.json").write_text("{}\n")
    lua_file = terminal.root / "smoke.lua"
    lua_file.write_text("local value = 42\nreturn value\n")
    terminal.edit(lua_file)
    terminal.wait(
        "local lua_ls initializes, attaches, and supports hover",
        lambda s: s["ft"] == "lua" and layout(s, True, lua_file) and terminal.lua("""
for _, client in ipairs(vim.lsp.get_clients({bufnr = 0, name = 'lua_ls'})) do
  if client.initialized and client:supports_method('textDocument/hover', 0) then
    return true
  end
end
return false
"""),
        timeout=20,
    )
    terminal.stage = "Lua LSP hover smoke"
    terminal.lua("""
assert(type(vim.lsp.handlers['textDocument/hover']) == 'function',
  'LSP hover handler must be callable')
vim.api.nvim_win_set_cursor(0, {2, 7})
vim.lsp.buf.hover({silent = true})
return true
""")
    terminal.edit(first)
    state = terminal.wait(
        "return to first fixture after Lua LSP hover",
        lambda s: layout(s, True, first),
    )

    check(
        state["tabs"] == [home, state["tab"]]
        and sum(not win["floating"] for win in state["wins"]) == 2,
        f"Quit regression requires a home tab and a file tab with only editor/tree windows: {state}",
    )
    terminal.send(b":q\r")
    terminal.wait(
        ":q closes the sole file window's tab and returns to the tree-free homepage",
        lambda s: s["tabs"] == [home]
        and s["tab"] == home
        and s["ft"] == "ministarter"
        and layout(s, False),
    )
    terminal.check_errors("Final :messages / v:errmsg / ERROR notifications")
    check(bool(terminal.output), "No real terminal output was captured.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "nvim", help="built, configured Neovim executable (no build is performed)"
    )
    args = parser.parse_args()
    # Keep the wrapper path: resolving a Nix wrapper symlink can bypass its configuration.
    executable = os.path.abspath(args.nvim)
    terminal = None
    try:
        check(
            os.path.isfile(executable) and os.access(executable, os.X_OK),
            f"Not an executable: {executable}",
        )
        isolate_processes()
        with tempfile.TemporaryDirectory(
            prefix="vix1-tui-", dir="/tmp/opencode"
        ) as directory:
            terminal = Terminal(executable, Path(directory))
            try:
                regress(terminal)
            except (Failure, OSError, subprocess.SubprocessError):
                terminal.diagnostics()
                raise
            finally:
                terminal.close()
    except (Failure, OSError, subprocess.SubprocessError) as error:
        stage = terminal.stage if terminal else "setup"
        print(f"FAIL [{stage}] {error}", file=sys.stderr)
        return 1
    print("PASS all real-TUI regressions (no SSH connection or timer started)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
