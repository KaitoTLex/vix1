return {
  "mini.files",
  keys = {
    {
      "<C-e>",
      function()
        if vim.bo.filetype == "ministarter" then
          MiniFiles.open(nil, false)
        else
          MiniFiles.open(vim.api.nvim_buf_get_name(0))
        end
      end,
      desc = "Open file explorer at current file",
      mode = "n",
    },
    {
      "<leader>fe",
      function()
        MiniFiles.open(nil, false)
      end,
      desc = "Open file explorer at cwd",
      mode = "n",
    },
  },
  after = function()
    require("mini.files").setup({
      windows = { preview = true, width_preview = 40 },
    })
  end,
}
