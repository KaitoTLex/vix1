return {
  "nvim-tree.lua",
  after = function()
    local api = require("nvim-tree.api")
    local function toggle()
      vim.t.explorer_disabled = api.tree.is_visible()
      if vim.t.explorer_disabled then
        api.tree.close()
      elseif vim.bo.filetype ~= "ministarter" and vim.api.nvim_buf_get_name(0) ~= "" then
        api.tree.open()
      end
    end

    require("nvim-tree").setup({
      disable_netrw = true,
      hijack_netrw = false,
      hijack_directories = { enable = false },
      view = { side = "left", width = 30, preserve_window_proportions = true },
      renderer = { group_empty = true },
      sync_root_with_cwd = true,
      update_focused_file = { enable = true },
      actions = { open_file = { resize_window = false } },
      on_attach = function(buf)
        api.map.on_attach.default(buf)
        vim.keymap.set("n", "<C-e>", toggle, { buffer = buf, desc = "Toggle explorer" })
        vim.keymap.set("n", "q", toggle, { buffer = buf, desc = "Close explorer" })
      end,
    })

    local pending = false
    local closing = false
    local group = vim.api.nvim_create_augroup("ResponsiveExplorer", { clear = true })
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = group,
      callback = function()
        closing = true
      end,
    })
    vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter", "BufWinEnter", "TabEnter", "VimResized", "WinClosed" }, {
      group = group,
      callback = function()
        if pending or closing then
          return
        end
        pending = true
        vim.schedule(function()
          pending = false
          if closing then
            return
          end
          local wins = vim.api.nvim_tabpage_list_wins(0)
          if #wins == 1 and vim.bo[vim.api.nvim_win_get_buf(wins[1])].filetype == "NvimTree" then
            vim.cmd.quit()
            return
          end
          local has_file = false
          for _, win in ipairs(wins) do
            local buf = vim.api.nvim_win_get_buf(win)
            local name = vim.api.nvim_buf_get_name(buf)
            if
              vim.api.nvim_win_get_config(win).relative == ""
              and vim.bo[buf].buftype == ""
              and name ~= ""
              and not name:match("^%w[%w+.-]*://")
              and vim.fn.isdirectory(name) == 0
            then
              has_file = true
              break
            end
          end
          -- Terminal emulators expose their grid size, not their fullscreen state.
          local roomy = vim.o.columns >= (vim.g.explorer_min_columns or 120)
            and vim.o.lines >= (vim.g.explorer_min_lines or 30)
          if not roomy or not has_file or vim.bo.filetype == "ministarter" or vim.t.explorer_disabled then
            if api.tree.is_visible() then
              api.tree.close()
            end
          elseif not api.tree.is_visible() then
            api.tree.toggle({ focus = false })
          end
        end)
      end,
    })
    vim.keymap.set("n", "<C-e>", toggle, { desc = "Toggle explorer" })
    vim.keymap.set("n", "<leader>fe", toggle, { desc = "Toggle explorer" })
  end,
}
