return {
  "bufferline.nvim",
  after = function()
    local function close(buf)
      require("lz.n").trigger_load("mini.bufremove")
      MiniBufremove.delete(buf)
    end
    require("bufferline").setup({
      options = {
        mode = "buffers",
        close_command = close,
        right_mouse_command = close,
        separator_style = "thin",
        always_show_bufferline = true,
        diagnostics = "nvim_lsp",
        offsets = {
          { filetype = "NvimTree", text = "EXPLORER", text_align = "left", separator = true },
        },
        custom_filter = function(buf)
          return (vim.bo[buf].buftype == "" or vim.bo[buf].buftype == "acwrite")
            and vim.bo[buf].filetype ~= "ministarter"
        end,
      },
    })
    vim.keymap.set("n", "<leader><S-Tab>", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next file tab" })
    vim.keymap.set("n", "<leader><Tab>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Previous file tab" })
  end,
}
