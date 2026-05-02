local M = {}

-- Colorschemes to use for each mode. Change these to your preference.
M.dark = "kanagawa-wave"
M.light = "kanagawa-lotus"

local function detect()
  -- 1. Stylix palette.json: base00 luminance is the most reliable signal here
  --    (portal returns uint32 0 / "default" when Stylix doesn't set an explicit preference)
  local home = os.getenv("HOME") or ""
  local f = io.open(home .. "/.config/stylix/palette.json", "r")
  if f then
    local content = f:read("*a")
    f:close()
    local hex = content:match('"base00"%s*:%s*"(%x%x%x%x%x%x)"')
    if hex then
      local r = tonumber(hex:sub(1, 2), 16)
      local g = tonumber(hex:sub(3, 4), 16)
      local b = tonumber(hex:sub(5, 6), 16)
      return (0.299 * r + 0.587 * g + 0.114 * b) > 127 and "light" or "dark"
    end
  end

  -- 2. XDG portal (works on GNOME, KDE, portals that actually report a preference)
  local out = vim.fn.system(
    "dbus-send --session --print-reply=literal --dest=org.freedesktop.portal.Desktop"
      .. " /org/freedesktop/portal/desktop"
      .. " org.freedesktop.portal.Settings.Read"
      .. " string:org.freedesktop.appearance string:color-scheme 2>/dev/null"
  )
  if out:match("uint32 2") then return "light" end
  if out:match("uint32 1") then return "dark" end

  -- 3. dconf gtk-theme: Stylix sets adw-gtk3-dark for dark polarity
  local theme = vim.fn.system("dconf read /org/gnome/desktop/interface/gtk-theme 2>/dev/null")
  if theme:match("[Dd]ark") then return "dark" end
  if theme:match("%S") then return "light" end

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

-- Watch XDG portal SettingChanged signal — works on GNOME, KDE, etc.
local function watch_portal()
  vim.fn.jobstart({
    "dbus-monitor",
    "--session",
    "type='signal',interface='org.freedesktop.portal.Settings',member='SettingChanged'",
  }, {
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line:match("color%-scheme") then
          vim.schedule(function() apply(detect()) end)
        end
      end
    end,
    stdout_buffered = false,
  })
end

-- Watch dconf for gtk-theme / color-scheme changes — catches Stylix home-manager switches
local function watch_dconf()
  vim.fn.jobstart({ "dconf", "watch", "/org/gnome/desktop/interface/" }, {
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line:match("gtk%-theme") or line:match("color%-scheme") or line:match("icon%-theme") then
          vim.schedule(function() apply(detect()) end)
        end
      end
    end,
    stdout_buffered = false,
  })
end

M.setup = function()
  apply(detect())
  watch_portal()
  watch_dconf()
end

return M
