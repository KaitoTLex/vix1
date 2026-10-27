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
              vim.ui.input({ prompt = "SSH project (host//path): " }, function(target)
                if not target or vim.trim(target) == "" then
                  return
                end
                target = vim.trim(target):gsub("^rsync://", ""):gsub("^scp://", "")
                local host, path = target:match("^([%w_.@-]+)//(.+)$")
                if not host then
                  vim.notify("Use an SSH alias or user@host followed by //path", vim.log.levels.WARN)
                  return
                end
                -- The plugin's ssh/scp jobs cannot prompt, so check the login non-interactively first.
                -- The remote shell also expands ~ and relative paths (from the remote home) to an absolute path.
                local home, rest = path:match("^(~)/?(.*)$")
                local cd = home and ("cd ~" .. (rest ~= "" and "/" .. vim.fn.shellescape(rest) or ""))
                  or ("cd " .. vim.fn.shellescape(path))
                vim.notify("Connecting to " .. host .. "...")
                vim.system(
                  { "ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10", host, cd .. " && pwd" },
                  { text = true },
                  vim.schedule_wrap(function(result)
                    local resolved = vim.trim(result.stdout or "")
                    if result.code == 0 and resolved:sub(1, 1) == "/" then
                      require("remote-session").open("rsync://" .. host .. "/" .. resolved, { open_terminal = false })
                      return
                    end
                    local reason = vim.trim(result.stderr or "")
                    if result.code ~= 255 then
                      vim.notify("Remote directory not found: " .. path .. "\n" .. reason, vim.log.levels.ERROR)
                      return
                    end
                    vim.notify(
                      "SSH login to "
                        .. host
                        .. " needs interaction:\n"
                        .. reason
                        .. "\nComplete it in the terminal (accept the host key; use ssh-add for key passphrases), then connect again.",
                      vim.log.levels.ERROR
                    )
                    vim.cmd("botright split | terminal ssh " .. vim.fn.shellescape(host) .. " true")
                    vim.cmd.startinsert()
                  end)
                )
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
