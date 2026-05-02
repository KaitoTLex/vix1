local function get_workspaces()
  local all_workspaces = {
    {
      name = "vault",
      path = vim.fs.normalize("~/Documents/vaults/vault"),
    },
    {
      name = "alexandria",
      path = vim.fs.normalize("~/Documents/alexandria/content"),
    },
  }

  local existing_workspaces = {}

  for i, x in ipairs(all_workspaces) do
    if vim.fn.isdirectory(x.path) == 1 then
      table.insert(existing_workspaces, all_workspaces[i])
      vim.notify(
        [[Detected Obsidian workspace ]]
          .. x.path
          .. [[, adding ]]
          .. vim.inspect(all_workspaces[i])
          .. [[ to obsidian workspaces]],
        vim.log.levels.DEBUG
      )
    end
  end

  return existing_workspaces
end

return {
  "obsidian.nvim",
  ft = { "markdown" },
  after = function()
    local workspaces = get_workspaces()

    if #workspaces > 0 then
      local opts = {
        ui = { enable = false },
        workspaces = workspaces,
        completion = { nvim_cmp = false },
      }
      require("obsidian").setup(opts)
    end
  end,
}
