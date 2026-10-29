-- Rex config — mirrors the Ghostty config in ../ghostty/config
-- Reload with: rex config reload

-- Local overrides, like Ghostty's config-file = ?~/.config/ghostty/config.local
local local_config = os.getenv("HOME") .. "/.config/rex/config.local.lua"
local f = io.open(local_config, "r")
if f ~= nil then
  f:close()
  require("config.local")
end

-- keybind = super+a=unbind
rex.unbind("cmd+a")

-- keybind = super+d=new_split:right
rex.bind("cmd+d", "pane.split", { direction = "right" })

-- keybind = super+opt+left=previous_tab
-- keybind = super+opt+right=next_tab
rex.bind("cmd+opt+left", "client.tab.previous")
rex.bind("cmd+opt+right", "client.tab.next")

-- keybind = opt+left=unbind
-- keybind = opt+right=unbind
rex.unbind("opt+left")
rex.unbind("opt+right")

-- Not ported from Ghostty:
--   ctrl+l=clear_screen and ctrl+c=text:\x15\x03 — Rex sends keys straight
--   through to the shell by default, so ^L clears and ^C interrupts as usual.
--   super+z=text:\x1b[122;9u — Rex can't send raw text from a keybinding.
--   Font (Iosevka 9), option-as-alt, background, and window styling are set
--   in the Rex app's settings, not the config file.
