local M = {}

M.setup = function()
  vim.lsp.config("lua_ls", {
    settings = {
      Lua = {
        runtime = {
          -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
          version = "LuaJIT",
        },
        diagnostics = {
          globals = { "nixCats" },
        },
        -- unfortunately we won't get nixCats autocomplete with this option
        -- off, but lazydev will be much faster
        --
        -- workspace = {
        --   -- Make the server aware of Neovim runtime files
        --   library = vim.api.nvim_get_runtime_file("", true),
        --   -- library =
        -- },
        -- Do not send telemetry data containing a randomized but unique identifier
        telemetry = {
          enable = false,
        },
      },
    },
  })
  vim.lsp.enable("nixd")
  vim.lsp.enable("marksman")
  vim.lsp.enable("svelte")
  vim.lsp.enable("texlab")
  vim.lsp.enable("clangd")
  vim.lsp.enable("mesonlsp")
  vim.lsp.enable("nushell")
  vim.lsp.enable("harper_ls")
  vim.lsp.enable("tinymist")
  vim.lsp.enable("lua_ls")
  vim.lsp.enable("vhdl-ls")
  vim.lsp.config("vhdl-ls", { settings = {
    on_attach = on_attach,
    capabilities = capabilities,
  } })
  vim.lsp.config("harper_ls", { settings = { ["harper-ls"] = { linters = { SentenceCapitalization = false } } } })
  vim.lsp.config("tinymist", {
    offset_encoding = "utf-8",
  })
end

return M
