return {
  "nvim-orgmode/orgmode",
  config = function()
    local ok, orgmode = pcall(require, "orgmode")
    if not ok then
      vim.notify("orgmode failed to load", vim.log.levels.ERROR)
      return
    end

    orgmode.setup({
      org_agenda_files = { "~/org/**/*" },
      org_default_notes_file = "~/org/refile.org",
    })

    -- Keymaps (match your existing leader usage)
    vim.keymap.set("n", "<leader>oa", ":Org agenda<CR>")
    vim.keymap.set("n", "<leader>oc", ":Org capture<CR>")
  end,
}
