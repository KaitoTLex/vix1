return {
  "remote-ssh",
  lazy = true,
  after = function()
    require("lz.n").trigger_load({ "plenary.nvim", "nvim-lspconfig" })
    require("remote-ssh").setup({
      async_write_opts = { autosave = false },
    })
  end,
  keys = {
    {
      "<leader>ssh",
      function()
        require("lz.n").trigger_load("telescope.nvim")
        local actions = {
          {
            "Connect to Remote Project...",
            function()
              vim.ui.input({ prompt = "SSH project (host//absolute/path): " }, function(target)
                if not target or vim.trim(target) == "" then
                  return
                end
                target = vim.trim(target)
                if not target:match("^[%w_.@-]+//[^%s]+$") then
                  vim.notify("Use an SSH alias or user@host followed by //absolute/path", vim.log.levels.WARN)
                  return
                end
                require("remote-session").open("rsync://" .. target, { open_terminal = false })
              end)
            end,
          },
          { "Recent Remote Projects", vim.cmd.RemoteSessionPicker },
          { "Remote File History", vim.cmd.RemoteHistory },
          { "Open SSH Terminal", vim.cmd.RemoteTerminalNew },
          { "Close Remote Project", vim.cmd.RemoteSessionClose },
          {
            "Edit SSH Config",
            function()
              vim.cmd.edit(vim.fn.expand("~/.ssh/config"))
            end,
          },
        }
        vim.ui.select(actions, {
          prompt = "Remote - SSH",
          format_item = function(item)
            return item[1]
          end,
        }, function(item)
          if item then
            item[2]()
          end
        end)
      end,
      desc = "Remote - SSH menu",
    },
  },
}
