return {
  "texpresso.vim",
  ft = { "tex", "latex" },
  keys = {
    {
      "<leader>tx",
      function()
        vim.cmd("TexpressoStart")
      end,
      desc = "Start texpresso preview",
      mode = "n",
    },
    {
      "<leader>tX",
      function()
        vim.cmd("TexpressoStop")
      end,
      desc = "Stop texpresso preview",
      mode = "n",
    },
  },
  after = function()
    require("texpresso").texpresso_path = nixCats("bin.texpresso")
  end,
}
