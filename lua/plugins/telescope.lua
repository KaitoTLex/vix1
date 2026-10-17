return {
  "telescope.nvim",
  after = function()
    require("telescope").setup({
      extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown({}),
        },
      },
    })

    require("telescope").load_extension("fzf")
    require("telescope").load_extension("ui-select")
  end,
  keys = {
    {
      "<leader> ",
      function()
        local builtin = require("telescope.builtin")
        local is_git = vim.fn.finddir(".git", vim.fn.getcwd() .. ";")
        if is_git ~= "" then
          builtin.git_files()
        else
          builtin.find_files()
        end
      end,
      desc = "Grep through all files tracked by git, or fall back to just cwd",
      mode = "n",
    },
    {
      "<leader>ff",
      function()
        require("telescope.builtin").find_files()
      end,
      desc = "Grep through all files in cwd",
      mode = "n",
    },
    { "<leader>ca", vim.lsp.buf.code_action, desc = "LSP Code Action", mode = "n" },
    {
      "<leader>/",
      function()
        require("telescope.builtin").live_grep()
      end,
      desc = "Live grep",
      mode = "n",
    },
    {
      "<leader>k",
      function()
        require("telescope.builtin").buffers()
      end,
      desc = "List buffers",
      mode = "n",
    },
    {
      "gd",
      function()
        require("telescope.builtin").lsp_definitions()
      end,
      desc = "Go to LSP definition",
      mode = "n",
    },
    {
      "gi",
      function()
        require("telescope.builtin").lsp_implementations()
      end,
      desc = "Go to implementations",
      mode = "n",
    },
    {
      "<leader>j",
      function()
        require("telescope.builtin").lsp_document_symbols()
      end,
      desc = "Search through document symbols",
      mode = "n",
    },
    {
      "<leader>fs",
      function()
        require("telescope.builtin").lsp_workspace_symbols()
      end,
      desc = "Search through entire workspace symbols",
      mode = "n",
    },
    {
      "<leader>fd",
      function()
        require("telescope.builtin").diagnostics()
      end,
      desc = "Search through LSP diagnostics",
      mode = "n",
    },
  },
}
