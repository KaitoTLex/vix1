# Terminal Regressions

Run against an already-built, configured executable:

```sh
python3 tests/terminal.py /nix/store/<package>/bin/nvim
```

The executable is required. The runner never builds anything, uses `result`, or
loads the checkout's configuration into a different Neovim. A plain or older
Neovim is expected to fail the feature assertions.

Only the Python standard library is needed. Run on Linux x86_64 or aarch64 with
PTYs, `/proc`, and seccomp available. The runner fails rather than silently
disabling network isolation on unsupported systems. `/tmp/opencode` must exist
and be writable.

The test starts a real, non-headless Neovim with a controlling 160x48 PTY and a
private Unix RPC socket. HOME, XDG directories, working directory, fixtures, and
temporary state live in a private temporary directory under `/tmp/opencode` and
are removed afterward. It does not inherit the user's Neovim, SSH-agent, or
desktop-session environment. WakaTime's unrelated startup telemetry is disabled.
An inherited seccomp filter denies non-Unix network sockets for the runner,
Neovim, RPC clients, and plugin jobs. The actual SSH menu is opened and canceled;
no remote action, hostname, or network service is used.

Coverage includes dashboard startup, automatic and manually toggled explorer
layout, both responsive size thresholds, file focus, rendered bufferline entries,
literal buffer-cycle keystrokes, safe cancellation of unsaved bufferline closes,
wide/narrow directory editing in full-width Oil, homepage/file tab switching, the
real Telescope SSH picker and remote commands, remote autosave configuration,
pomo and blink-ripgrep loading, and `:q` returning from the file tab to the
tree-free homepage. The tests do not start a timer, test ripgrep completions, or
make SSH connections.

PTY output is drained continuously and retained as a bounded diagnostic tail.
The drain loop answers basic xterm color/status queries to avoid artificial
terminal-response errors at startup.
Assertions poll for stable UI state instead of assuming fixed startup sleeps.
RPC calls, assertions, startup, and the entire scenario have time limits. The
runner checks startup and final `:messages`, `v:errmsg`, and ERROR notifications
captured by a forwarding `vim.notify` spy installed only after startup. Failures
print their stage and Neovim/PTY diagnostics. Teardown quits Neovim, terminates
remaining descendants (including adopted orphan jobs), reaps children, and closes
the PTY. No third-party Python package, external terminal, or existing `result`
link is needed.
