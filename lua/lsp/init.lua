local M = {}

M.setup = function()
  -- local symbols = { Error = "󰅙", Info = "󰋼", Hint = "󰌵", Warn = "" }

  -- for name, icon in pairs(symbols) do
  -- local hl = "DiagnosticSign" .. name
  -- vim.fn.sign_define(hl, { text = icon, numhl = hl, texthl = hl })
  -- end
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
  vim.lsp.config("harper_ls", { settings = { ["harper-ls"] = { linters = { SentenceCapitalization = false } } } })
  vim.lsp.config("tinymist", {
    offset_encoding = "utf-8",
  })
  vim.lsp.config("vhdl_ls", { on_attach = on_attach, capabilities = capabilities })
  -- vim.lsp.config({
  --   -- command = "elm-language-server",
  --   -- filetype = "*.elm",
  -- })
  vim.lsp.config("nvim-java", { -- Startup checks
    checks = {
      nvim_version = true, -- Check Neovim version
      nvim_jdtls_conflict = true, -- Check for nvim-jdtls conflict
    },

    -- JDTLS configuration
    jdtls = {
      version = "1.43.0",
    },

    -- Extensions
    lombok = {
      enable = true,
      version = "1.18.40",
    },

    java_test = {
      enable = true,
      version = "0.40.1",
    },

    java_debug_adapter = {
      enable = true,
      version = "0.58.2",
    },

    spring_boot_tools = {
      enable = true,
      version = "1.55.1",
    },

    -- JDK installation
    jdk = {
      auto_install = true,
      version = "17",
    },

    -- Logging
    log = {
      use_console = true,
      use_file = true,
      level = "info",
      log_file = vim.fn.stdpath("state") .. "/nvim-java.log",
      max_lines = 1000,
      show_location = false,
    },
  })
  vim.lsp.enable("nixd")
  vim.lsp.enable("jdtls")
  vim.lsp.enable("marksman")
  vim.lsp.enable("tinymist")
  vim.lsp.enable("harper_ls")
  vim.lsp.enable("tailwindcss")
  vim.lsp.enable("svelte")
  vim.lsp.enable("texlab")
  vim.lsp.enable("nushell")
  vim.lsp.enable("arduino_language_server")
  vim.lsp.enable("gradle_ls")
  vim.lsp.enable("lua_ls")
  vim.lsp.enable("pylsp")
  vim.lsp.enable("systemverilog")
  vim.lsp.enable("vhdl_ls")
end

return M
