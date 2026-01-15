return {
  "conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true })
      end,
      desc = "Format code",
      mode = { "n", "v" },
    },
    {
      "<leader>ctf",
      function()
        if vim.g.disable_autoformat then
          vim.g.disable_autoformat = false
        else
          vim.g.disable_autoformat = true
        end
      end,
      desc = "Disable autoformat on save globally",
      mode = { "n", "v" },
    },
    {
      "<leader>cbf",
      function()
        if vim.b[0].disable_autoformat then
          vim.b[0].disable_autoformat = false
        else
          vim.b[0].disable_autoformat = true
        end
      end,
      desc = "Disable autoformat on save buffer",
      mode = { "n", "v" },
    },
  },
  after = function()
    require("conform").setup({
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end

        return { timeout_ms = 500, lsp_fallback = true }
      end,
      default_format_opts = {
        lsp_format = "fallback",
      },
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        rust = { "rustfmt", lsp_format = "fallback" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        jypescriptreact = { "prettierd", "prettier", stop_after_first = true },
        nix = { "nixfmt" },
        haskell = { "fourmolu", "ormolu", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        -- jsonc = { "prettierd", "prettier", stop_after_first = true },
        toml = { "taplo", stop_after_first = true },
        yaml = { "prettierd", "prettier", stop_after_first = true },
        typst = { "typstyle" },
        svelte = { "prettier", lsp_format = "fallback" },
        tex = { "latexindent" },
        cpp = { "clang-format", lsp_format = "fallback" },
        c = { "clang-format", lsp_format = "fallback" },
      },
    })

    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
