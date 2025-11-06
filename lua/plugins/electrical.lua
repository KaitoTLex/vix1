-- Scala + Chisel + Metals integration layer

return {
  "scalameta/nvim-metals",
  ft = { "scala", "sbt", "java" },

  after = function()
    local metals = require("metals")

    -- Pull completion capabilities from *blink.cmp* LSP extension
    local blink = require("blink.cmp")
    local capabilities = vim.tbl_deep_extend(
      "force",
      vim.lsp.protocol.make_client_capabilities(),
      blink.get_lsp_capabilities and blink.get_lsp_capabilities() or {}
    )

    local metals_config = metals.bare_config()
    metals_config.capabilities = capabilities

    metals_config.on_attach = function(_, bufnr)
      local map = function(mode, lhs, rhs)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true })
      end

      map("n", "gd", vim.lsp.buf.definition)
      map("n", "K", vim.lsp.buf.hover)
      map("n", "gr", vim.lsp.buf.references)
      map("n", "<leader>rn", vim.lsp.buf.rename)
      map("n", "<leader>ca", vim.lsp.buf.code_action)

      -- Metals helpers
      map("n", "<leader>mi", "<cmd>MetalsImportBuild<cr>")
      map("n", "<leader>mc", "<cmd>MetalsConnect<cr>")
    end

    metals_config.settings = {
      showImplicitArguments = true,
      showInferredType = true,
    }

    -- trigger attach on correct filetypes
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "scala", "sbt", "java" },
      callback = function()
        metals.initialize_or_attach(metals_config)
      end,
    })

    -- Chisel workflow
    vim.api.nvim_create_user_command("SbtTest", function()
      vim.cmd("botright split | terminal sbt test")
    end, {})

    vim.keymap.set("n", "<leader>rt", ":SbtTest<cr>", { desc = "Run Chisel tests" })
  end,
}
