local M = {}

-- Colorschemes to use for each mode. Change these to your preference.
M.dark = "kanagawa-wave"
M.light = "kanagawa-lotus"

local function detect()
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

-- Watch XDG portal SettingChanged signal — works on Wayland (Hyprland, GNOME, etc.)
local function watch_portal()
  vim.fn.jobstart({
    "dbus-monitor",
    "--session",
    "type='signal',interface='org.freedesktop.portal.Settings',member='SettingChanged'",
  }, {
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line:match("color%-scheme") then
          vim.schedule(function()
            apply(detect())
          end)
        end
      end
    end,
    stdout_buffered = false,
  })
end

M.setup = function()
  apply(detect())
  watch_portal()
end

return M
