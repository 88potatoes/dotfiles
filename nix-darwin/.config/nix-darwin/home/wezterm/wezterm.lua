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

  send_composed_key_when_left_alt_is_pressed = false,
  send_composed_key_when_right_alt_is_pressed = false,
  window_decorations = 'TITLE|RESIZE',

  keys = {
    { key = 'a', mods = 'SUPER', action = wezterm.action.Nop },
    { key = 'z', mods = 'SUPER', action = wezterm.action.SendString '\x1b[122;9u' },
    { key = 'LeftArrow', mods = 'SUPER|OPT', action = wezterm.action.ActivateTabRelative(-1) },
    { key = 'RightArrow', mods = 'SUPER|OPT', action = wezterm.action.ActivateTabRelative(1) },

    { key = 'd', mods = 'SUPER', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'd', mods = 'SUPER|SHIFT', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = '[', mods = 'SUPER', action = wezterm.action.ActivatePaneDirection 'Prev' },
    { key = ']', mods = 'SUPER', action = wezterm.action.ActivatePaneDirection 'Next' },
    { key = 'UpArrow', mods = 'SUPER|OPT', action = wezterm.action.ActivatePaneDirection 'Up' },
    { key = 'DownArrow', mods = 'SUPER|OPT', action = wezterm.action.ActivatePaneDirection 'Down' },
    { key = 'Enter', mods = 'SUPER|SHIFT', action = wezterm.action.TogglePaneZoomState },
    { key = 'w', mods = 'SUPER', action = wezterm.action.CloseCurrentPane { confirm = true } },
    { key = 'w', mods = 'SUPER|SHIFT', action = wezterm.action.CloseCurrentTab { confirm = true } },
  },
}

local local_path = wezterm.home_dir .. '/.config/wezterm/config.local.lua'
local f = io.open(local_path, 'r')
if f then
  f:close()
  dofile(local_path)(config)
end

return config
