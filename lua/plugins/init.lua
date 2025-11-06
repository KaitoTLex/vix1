-- Experimental Neovim byte-compiled module loader
vim.loader.enable()

local pluginSpec = require("plugins.lz-spec")
require("lz.n").load(pluginSpec)
require("plugins.orgmode")
