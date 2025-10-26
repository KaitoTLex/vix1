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

vim.treesitter.indent = true
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldmethod = "expr"
vim.opt.foldenable = false

vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250

vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

vim.opt.scrolloff = 10

vim.cmd.colorscheme("rose-pine-moon")

require("nvim-treesitter.configs").setup({
  ensure_installed = {},
  sync_install = false,
  auto_install = false,
  modules = { "highlight", "incremental_selection", "indent" },
  ignore_install = { "org" },
  highlight = { enable = true },
  disable = function(_, buf)
    local max_filesize = 100 * 1024 -- 100 KB
    ---@diagnostic disable-next-line: undefined-field
    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
    if ok and stats and stats.size > max_filesize then
      return true
    end
  end,
  additional_vim_regex_highlighting = false,
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<CR>",
      node_incremental = "<C-k>",
      scope_incremental = "<BS>",
      node_decremental = "<C-j>",
    },
  },
})

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
    vim.highlight.on_yank({ higroup = "Visual", timeout = 300 })
  end,
})

-- silence the hover 'no information available' notification
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  silent = true,
})
