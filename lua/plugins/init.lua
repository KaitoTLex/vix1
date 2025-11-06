-- Experimental Neovim byte-compiled module loader
vim.loader.enable()
pcall(function()
  local nc = require("nixCats")
  if nc.vimPackDir then
    vim.opt.packpath:prepend(nc.vimPackDir)
    vim.opt.runtimepath:prepend(nc.vimPackDir)
  end
end)

local pluginSpec = require("plugins.lz-spec")
require("lz.n").load(pluginSpec)
