local M = {}

-- Colorschemes to use for each mode. Change these to your preference.
M.dark = "kanagawa-wave"
M.light = "kanagawa-lotus"

local function detect()
  -- XDG portal: 1 = dark, 2 = light, 0 = no preference
  local out = vim.fn.system(
    "dbus-send --session --print-reply=literal --dest=org.freedesktop.portal.Desktop"
      .. " /org/freedesktop/portal/desktop"
      .. " org.freedesktop.portal.Settings.Read"
      .. " string:org.freedesktop.appearance string:color-scheme 2>/dev/null"
  )
  if out:match("uint32 2") then
    return "light"
  end
  if out:match("uint32 1") then
    return "dark"
  end
  -- fallback: gsettings (GNOME)
  local gs = vim.fn.system("gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null")
  if gs:match("prefer-light") then
    return "light"
  end
  return "dark"
end

local function apply(mode)
  if mode == "light" then
    vim.o.background = "light"
    vim.cmd.colorscheme(M.light)
  else
    vim.o.background = "dark"
    vim.cmd.colorscheme(M.dark)
  end
end

-- Watch dconf for live GNOME theme changes
local function watch_dconf()
  local path = vim.fn.expand("~/.config/dconf/user")
  if vim.fn.filereadable(path) == 0 then
    return
  end
  local watcher = vim.uv.new_fs_event()
  if not watcher then
    return
  end
  watcher:start(path, {}, function(err)
    if err then
      return
    end
    vim.schedule(function()
      apply(detect())
    end)
  end)
end

M.setup = function()
  apply(detect())
  watch_dconf()
end

return M
