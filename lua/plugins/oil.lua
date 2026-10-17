-- we still use oil.nvim for more complex filesystem manipulations
return {
  "oil.nvim",
  lazy = false,
  cmd = "Oil",
  keys = {
    {
      "<leader>bf",
      function()
        vim.cmd("Oil " .. vim.fn.getcwd())
      end,
      mode = "n",
      desc = "Open oil in current working directory",
    },
    {
      "<leader>be",
      vim.cmd.Oil,
      mode = "n",
      desc = "Open oil in current file directory",
    },
  },
  after = function()
    require("oil").setup({
      columns = {
        "size",
        "icon",
      },
      default_file_explorer = true,
      buf_options = { undofile = false },
      use_default_keymaps = false,
      keymaps = {
        ["J"] = "actions.parent",
        ["Q"] = "actions.close",
        ["<C-h>"] = "actions.select_split",
        ["<C-l>"] = "actions.refresh",
        ["<C-p>"] = "actions.preview",
        ["<C-s>"] = "actions.select_vsplit",
        ["<C-t>"] = "actions.select_tab",
        ["<CR>"] = "actions.select",
        ["K"] = "actions.select",
        ["_"] = "actions.open_cwd",
        ["`"] = "actions.cd",
        ["g."] = "actions.toggle_hidden",
        ["g?"] = "actions.show_help",
        ["g\\"] = "actions.toggle_trash",
        ["gs"] = "actions.change_sort",
        ["gx"] = "actions.open_external",
        ["~"] = "actions.tcd",
      },
    })
  end,
}
