-- Rex config — mirrors the Ghostty config in ../ghostty/config
-- Reload with: rex config reload

-- Local overrides, like Ghostty's config-file = ?~/.config/ghostty/config.local
local local_config = os.getenv("HOME") .. "/.config/rex/config.local.lua"
local f = io.open(local_config, "r")
if f ~= nil then
  f:close()
  require("config.local")
end

-- keybind = cmd+shift+r = rename session
rex.bind("cmd+shift+r", "session.rename")

-- cmd+n = new session (not a new window)
rex.unbind("cmd+n")
rex.bind("cmd+n", "session.new")

-- keybind = cmd+p = command palette
rex.bind("cmd+p", "client.palette.toggle")

-- Ghostty's super+a=unbind: Rex has no default cmd+a binding, so no unbind needed.

-- keybind = super+d=new_split:right
rex.bind("cmd+d", "pane.split", { direction = "right" })

-- keybind = super+opt+left=previous_tab
-- keybind = super+opt+right=next_tab
rex.bind("cmd+opt+left", "client.tab.previous")
rex.bind("cmd+opt+right", "client.tab.next")

-- keybind = opt+left=unbind, opt+right=unbind
-- Rex sends unbound keys (like opt+arrows) to the shell by default, so no unbind needed.

-- Not ported from Ghostty:
--   ctrl+l=clear_screen and ctrl+c=text:\x15\x03 — Rex sends keys straight
--   through to the shell by default, so ^L clears and ^C interrupts as usual.
--   super+z=text:\x1b[122;9u — Rex can't send raw text from a keybinding.
--   Font (Iosevka 9), option-as-alt, background, and window styling are set
--   in the Rex app's settings, not the config file.

local LAZYGIT_PREFIX = "lazygit "

local function find_lazygit_layer(view, bid, label)
  local by_label
  for _, window in ipairs(view.windows or {}) do
    for _, layer in ipairs(window.layers or {}) do
      if layer.kind ~= "tiled" then
        for _, block in ipairs(layer.blocks or {}) do
          if block.block_id == bid and (block.label or ""):sub(1, #LAZYGIT_PREFIX) == LAZYGIT_PREFIX then
            return layer
          end
          if block.label == label then
            by_label = layer
          end
        end
      end
    end
  end
  return by_label
end

local function ensure_lazygit_layer(sid, view, bid, cwd)
  local label = LAZYGIT_PREFIX .. cwd
  local layer = find_lazygit_layer(view, bid, label)
  if layer then
    return layer.layer_id, layer.state, false
  end
  local created = rex.call("session.new_layer", {
    session_id = sid,
    window_id = view.active_window_id,
    bounds = { 0.1, 0.1, 0.8, 0.8 },
    focus = true,
    layout = {
      block = {
        flavor = "com.superlogical.terminal.shell",
        label = label,
        options = { command = { "lazygit" }, cwd = cwd },
      },
    },
  })
  return created.layer_id, "normal", true
end

rex.action({
  name = "lazygit_float",
  title = "Toggle floating lazygit",
  run = function(ctx)
    local f = io.open("/tmp/rex-lazygit.log", "a")
    if f then f:write(os.date() .. " fired origin=" .. tostring(ctx.origin) .. " block=" .. tostring(ctx.block_id) .. "\n") f:close() end
    local sid = ctx.session_id
    local bid = ctx.block_id

    local process = rex.call("block.method", {
      session_id = sid,
      block_id = bid,
      method = "process",
      args = {},
    })
    local cwd = process.foreground and process.foreground.cwd or os.getenv("HOME")

    local view = rex.call("session.view", { session_id = sid })
    local layer_id, state, created = ensure_lazygit_layer(sid, view, bid, cwd)
    if created then
      return
    end

    if state == "minimized" then
      rex.call("session.set_layer_state", {
        session_id = sid,
        layer_id = layer_id,
        state = "normal",
        focus = true,
      })
    else
      rex.call("session.set_layer_state", {
        session_id = sid,
        layer_id = layer_id,
        state = "minimized",
      })
    end
  end,
})

rex.bind("cmd+shift+l", "lazygit_float")
rex.bind("cmd+shift+k", "client.palette.toggle")
rex.bind("cmd+shift+j", "lazygit_float")
