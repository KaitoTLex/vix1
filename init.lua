if os.getenv("TERM") == "xterm-kitty" then
  require("scripts.chameleon").setup()
  require("scripts.kitty-padding").setup()
end

require("keymaps")
require("plugins")
require("scripts.obsidian-sync")

require("scripts.autoroot").setup()

vim.opt.relativenumber = true
vim.opt.number = true

-- Global statusline
vim.opt.laststatus = 3
-- Persistent undos across session
vim.opt.undofile = true

vim.opt.tabstop = 4
vim.opt.shiftwidth = 2

vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldmethod = "expr"
vim.opt.foldenable = false

vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250

vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

vim.opt.scrolloff = 10

vim.cmd.colorscheme("kanagawa")

-- nvim-treesitter 0.10+ — highlighting is automatic; disable for large files
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local max_filesize = 100 * 1024 -- 100 KB
    ---@diagnostic disable-next-line: undefined-field
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
    if ok and stats and stats.size > max_filesize then
      vim.treesitter.stop(args.buf)
    end
  end,
})

-- no line numbers for terminals
vim.api.nvim_create_autocmd({
  "TermOpen",
}, {
  group = vim.api.nvim_create_augroup("terminal", {}),
  callback = function()
    vim.cmd("setlocal nonumber norelativenumber")
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank({ higroup = "Visual", timeout = 300 })
  end,
})

-- silence the hover 'no information available' notification
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  silent = true,
})

vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = vim.api.nvim_create_augroup("EqualizeSplits", {}),
  callback = function()
    local current_tab = vim.api.nvim_get_current_tabpage()
    vim.cmd("tabdo wincmd =")
    vim.api.nvim_set_current_tabpage(current_tab)
  end,
  desc = "Resize splits with terminal window",
})

vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅙",
      [vim.diagnostic.severity.INFO] = "󰋼",
      [vim.diagnostic.severity.HINT] = "󰌵",
      [vim.diagnostic.severity.WARN] = "",
    },
  },
  virtual_lines = { current_line = true },
})
