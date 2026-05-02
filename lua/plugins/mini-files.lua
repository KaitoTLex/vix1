return {
  "mini.files",
  keys = {
    {
      "<C-e>",
      function()
        if not MiniFiles.close() then
          if vim.bo.filetype == "ministarter" then
            MiniFiles.open(nil, false)
          else
            MiniFiles.open(vim.api.nvim_buf_get_name(0))
          end
        end
      end,
      desc = "Toggle file explorer at current file",
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
      mappings = {
        go_in = "l",
        go_in_plus = "L",
        synchronize = "<CR>",
      },
    })

    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniFilesBufferCreate",
      callback = function(args)
        vim.keymap.set("n", "<Esc>", MiniFiles.close, { buffer = args.data.buf_id })
      end,
    })
  end,
}
