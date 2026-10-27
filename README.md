# viminal2

This is my second attempt at creating a Neovim configuration intended for
NixOS. The [first](https://github.com/youwen5/viminal) was configured using
[Nixvim](https://github.com/nix-community/nixvim). This mostly worked, except
you often had to escape into raw Lua strings to get precise customization.

Enter [nixCats](https://github.com/BirdeeHub/nixCats-nvim). It provides the
tools needed to mix Nix and Lua in your configurations. For advanced users,
configuring Neovim with Nix expressions doesn't really make sense, since the
whole point of Neovim is to be extremely hackable ("hyperextensible") and it
provides ergonomic Lua bindings for that purpose.

This setup provides not just a usable but a "great" Neovim configuration for
NixOS. That is, it has features that make it _better_ on _all distros_, not
just on NixOS. Why? Instead of using ad-hoc package managers written for Neovim
like `lazy.nvim`, `Mason`, etc, all external dependencies are fetched and built
by Nix. Mason and lazy are good for what they are meant for, but Nix can make
strong guarantees that practically no other package management tool can,
period. Namely, it can ensure the presence of runtime dependencies (like `rg`,
`fd`, LSPs, formatters, etc), and guarantee builds are successful. If your
editor works today, it'll work tomorrow. It won't break from system upgrades or
files randomly getting broken. Nix is purpose built to handle pretty much
everything that a text editor's plugins shouldn't, and it's a perfect match.

## Try it

You can test drive the configuration (even if you aren't on NixOS) if you have
the Nix package manager available (with flakes).

```bash
nix run 'github:youwen5/viminal2'
```

To build and run this checkout (including new, untracked Lua files):

```bash
nix build path:.#nvim
./result/bin/nvim
```

To open a new **fullscreen Kitty window**, use `nix run path:.#fullscreen`.
File arguments are supported: `nix run path:.#fullscreen -- ./flake.nix`.
This launcher requests fullscreen only for its own window; starting `nvim` inside
an existing terminal does not change that terminal's window-manager state.

Run the real-terminal regression suite after building:

```bash
python3 tests/terminal.py ./result/bin/nvim
```

See [tests/README.md](tests/README.md) for the isolated test environment and coverage.

## Hacking

This flake exposes a package at `packages.${system}.nvim-no-rc` that doesn't
bundle the Lua configuration with the files. (It still includes all of the
plugins managed by Nix and the nixCats Lua helper). This means you can quickly
hack on the configuration just like a regular Neovim config without constantly
re-running `nix build`. Here's how:

Clone this repository to `~/.config/nvim`. Enter the repository and run `nix
build .#nvim-no-rc`. Then, you can run Neovim from within the symlink,
`result/bin/nvim-no-rc`, which will use the Neovim configuration in
`~/.config/nvim`. You can then quickly hack on any Lua files without constant
rebuilds.

## Philosophy

As this is my second configuration from scratch (if you count Nixvim as "from
scratch"), I wanted to do it right (so I could stop wasting my time configuring
my editor). I've been using this configuration daily for various purposes for
over a year, with no desire to declare Neovim bankruptcy yet, so presumably it
was a success.

For completion, I use [blink.cmp](https://github.com/Saghen/blink.cmp). This
plugin is much, much faster than `nvim-cmp` thanks to optimized `SIMD`
instructions (and Rust), has a better fuzzy search, and comes with more out of
the box.

`lz.n` is used to load plugins after they have been downloaded by Nix. `lz.n`
is a lazy loading plugin by the authors of `Rocks.nvim`, a plugin manager based
on Luarocks. As they are designed to be decoupled, `Rocks.nvim` can simply be
replaced by Nix. Most plugins are lazy loaded, but generally performance is
good enough that it is not even strictly necessary.

The keybinds have gotten a lot more idiosyncratic. Instead of focusing on
mnemonic keys that can be easily committed to memory, highly efficient ones
were chosen instead.

## Keybindings

> `<leader>` is `<Space>`. Chord keys (e.g. `<C-h><C-a>`) are pressed sequentially.

### File Explorer (nvim-tree)

The explorer is docked on the left while editing local files. It stays hidden on
the home screen, hides automatically below **120 columns or 30 rows**, and returns
when the terminal grows again. This covers narrow/half-sized terminal panes
without forcing them back to fullscreen. Terminals expose their character-grid
size, not a portable fullscreen flag; the thresholds can be changed with
`vim.g.explorer_min_columns` and `vim.g.explorer_min_lines` before setup.
Manually hiding the explorer persists for the current Neovim tab page.

| Key | Action |
|-----|--------|
| `<C-e>` / `<leader>fe` | Toggle the left explorer |
| `<CR>` / `o` | Expand directory / open file |
| `<BS>` | Close directory |
| `a` / `r` / `d` | Create / rename / delete |
| `H` | Toggle hidden files |
| `g?` | Show explorer keybindings |
| `q` | Hide the explorer |

### File Tabs

Open files appear as clickable tabs across the top, like VS Code. These are
**buffer tabs**, not Neovim tab pages (which hold separate window layouts).

| Key | Action |
|-----|--------|
| `<leader><S-Tab>` | Next file tab, wrapping around |
| `<leader><Tab>` | Previous file tab, wrapping around |
| `<leader>bd` | Close current file buffer |

Press Space, then Shift+Tab for the requested shortcut.

### Remote - SSH

`<leader>ssh` (Space, then `s`, `s`, `h`) opens the Remote - SSH menu, with
connection, recent projects, file history, terminal, disconnect, and SSH config
actions. The plugin is
[inhesrom/remote-ssh.nvim](https://github.com/inhesrom/remote-ssh.nvim): files are
edited locally, with remote filesystem operations and remote language servers.
Remote buffers use normal explicit saves; automatic remote saving is disabled.

Choose **Connect to Remote Project...** and enter `my-server//home/user/project`,
`user@host//~/project`, or `user@host//project` (relative to the remote home).
Use an SSH alias from `~/.ssh/config` for nonstandard ports, identity files, or
jump hosts. The plugin's background ssh/scp jobs cannot prompt, so the menu first
checks the login non-interactively; if a host key must be accepted or a password
or passphrase is needed, it shows ssh's error and opens an interactive `ssh`
terminal to finish once. Key passphrases should be loaded with `ssh-add`. The local wrapper includes OpenSSH, rsync, Python, and coreutils;
the remote host needs SSH, rsync, Python 3, standard Unix tools, and any language
servers you want to use. No remote Neovim installation is required.

### File Explorer (oil.nvim)

Opening a directory with `nvim .` or `:edit /path/to/directory` uses Oil as a
full-width browser, including in narrow terminals.

| Key | Action |
|-----|--------|
| `<leader>bf` | Open oil at cwd |
| `<leader>be` | Open oil at current file's directory |
| `<C-h>` | Open in horizontal split |
| `<C-s>` | Open in vertical split |
| `<C-t>` | Open in new tab |
| `<C-p>` | Toggle preview |

### Search / Find (Telescope)

| Key | Action |
|-----|--------|
| `<leader><Space>` | Find files (git-tracked or cwd fallback) |
| `<leader>ff` | Find all files in cwd |
| `<leader>/` | Live grep |
| `<leader>k` | List open buffers |
| `<leader>j` | Search document symbols |
| `<leader>fs` | Search workspace symbols |
| `<leader>fd` | Search LSP diagnostics |
| `gd` | Go to LSP definition |
| `gi` | Go to implementations |
| `<leader>ca` | LSP code action |

### Marks / Quick Navigation (Harpoon)

| Key | Action |
|-----|--------|
| `<leader>a` | Add current file to harpoon |
| `<C-h><C-h>` | Open harpoon menu (telescope) |
| `<C-h><C-a>` | Jump to harpoon slot 1 |
| `<C-h><C-s>` | Jump to harpoon slot 2 |
| `<C-h><C-d>` | Jump to harpoon slot 3 |
| `<C-h><C-f>` | Jump to harpoon slot 4 |

### Terminal (toggleterm.nvim)

| Key | Action |
|-----|--------|
| `<C-l>` | Toggle floating terminal |
| `<leader>tv` | Open vertical terminal |
| `<leader>tt` | Open horizontal terminal |
| `<leader>ts` | Terminal select |
| `<C-j>` | Toggle `just` runner |

### Git (Gitsigns + Neogit)

| Key | Action |
|-----|--------|
| `<leader>gg` | Open Neogit |
| `<leader>gc` | Open Neogit commit menu |
| `<leader>gs` | Stage hunk |
| `<leader>gr` | Reset hunk |
| `<leader>gS` | Stage buffer |
| `<leader>gu` | Undo stage hunk |
| `<leader>gR` | Reset buffer |
| `<leader>gp` | Preview hunk |
| `<leader>gb` | Toggle line blame |
| `<leader>gd` | Diff this |
| `<leader>gD` | Diff vs HEAD~ |
| `<leader>gtd` | Toggle show deleted |

### Diagnostics (Trouble)

| Key | Action |
|-----|--------|
| `<leader>xx` | Workspace diagnostics |
| `<leader>xX` | Buffer diagnostics |
| `<leader>cs` | Symbols panel |
| `<leader>cl` | LSP definitions / references |
| `<leader>ql` | Quickfix list |

### Formatting (conform.nvim)

| Key | Action |
|-----|--------|
| `<leader>cf` | Format current buffer |
| `<leader>ctf` | Toggle autoformat on save (global) |
| `<leader>cbf` | Toggle autoformat on save (buffer) |

### Splits / Panes (Neovim built-in)

| Key | Action |
|-----|--------|
| `<C-w>v` | Vertical split |
| `<C-w>s` | Horizontal split |
| `<C-w>h` | Focus left split |
| `<C-w>j` | Focus lower split |
| `<C-w>k` | Focus upper split |
| `<C-w>l` | Focus right split |
| `<C-w>c` | Close split |
| `<C-w>=` | Equalize split sizes |

## Todo

- Try rewriting config in Fennel.

## License

Feel free to copy any code from here or use it as an example. It's [public
domain](./LICENSE).
