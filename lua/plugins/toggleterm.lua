return {
  "toggleterm.nvim",
  keys = {
    {
      "<C-l>",
      function()
        vim.cmd("ToggleTerm direction=float")
      end,
      mode = { "n", "t", "v" },
      desc = "Toggle terminal",
    },
    {
      "<leader>tv",
      function()
        vim.cmd("ToggleTerm direction=vertical")
      end,
      desc = "Vertical terminal",
      mode = "n",
    },
    {
      "<leader>tt",
      function()
        vim.cmd("ToggleTerm direction=horizontal")
      end,
      desc = "Horizontal terminal",
      mode = "n",
    },
    {
      "<leader>ts",
      function()
        vim.cmd("TermSelect")
      end,
      desc = "Terminal select",
      mode = "n",
    },
    {
      "<C-j>",
      function()
        require("toggleterm.terminal").Terminal
          :new({
            direction = "horizontal",
            count = 100,
            cmd = "just",
            display_name = "just runner",
            auto_scroll = true,
            close_on_exit = true,
          })
          :toggle()
      end,
      mode = "n",
      desc = "Toggle just runner",
    },
  },
  after = function()
    require("toggleterm").setup({
      shade_terminals = false,
      size = function(term)
        if term.direction == "horizontal" then
          return 20
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
    })
  end,
}
