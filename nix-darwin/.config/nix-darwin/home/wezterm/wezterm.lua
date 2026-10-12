local wezterm = require 'wezterm'

local config = {
  colors = {
    foreground = '#c8c8c8',
    background = '#000000',
    split = '#585858',
  },

  font = wezterm.font 'Iosevka',
  font_size = 9.0,
  harfbuzz_features = { 'calt' },

  macos_option_as_alt = true,
  window_decorations = 'TITLE|RESIZE',

  keys = {
    { key = 'a', mods = 'SUPER', action = wezterm.action.Nop },
    { key = 'z', mods = 'SUPER', action = wezterm.action.SendString '\x1b[122;9u' },
    { key = 'LeftArrow', mods = 'SUPER|OPT', action = wezterm.action.ActivateTabRelative(-1) },
    { key = 'RightArrow', mods = 'SUPER|OPT', action = wezterm.action.ActivateTabRelative(1) },
  },
}

local local_path = wezterm.home_dir .. '/.config/wezterm/config.local.lua'
local f = io.open(local_path, 'r')
if f then
  f:close()
  dofile(local_path)(config)
end

return config
