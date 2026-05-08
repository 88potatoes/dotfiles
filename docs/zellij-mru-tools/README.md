# zellij-mru-tools MVP

Send text from Neovim to the previously-focused pane in the same Zellij tab.

## Files

- `zellij-pane-mru-poller` - background poller. Tracks focused panes per session+tab.
- `zellij-mru-send` - reads stdin/text and pastes it into previous pane in same tab.
- `nvim/.config/nvim/lua/zellij_mru.lua` - Neovim helper.

State lives at:

```sh
${ZELLIJ_MRU_DIR:-$TMPDIR/zellij-pane-mru-$UID}/<session>/tab_<tab_id>.json
```

## Use

From inside zellij, start poller:

```sh
/Users/eric/.local/bin/zellij-pane-mru-poller >/tmp/zellij-mru.log 2>&1 &
```

Focus target pane, then focus nvim pane. Send text:

```sh
printf 'hello from nvim\n' | /Users/eric/.local/bin/zellij-mru-send
```

Submit after paste, useful for pi:

```sh
printf 'hello pi\n' | /Users/eric/.local/bin/zellij-mru-send --enter
```

Debug target:

```sh
printf test | /Users/eric/.local/bin/zellij-mru-send --print-target
```

## Neovim keymap

Neovim module lives at `lua/zellij_mru.lua`.

Configured keymap:

```lua
local mru = require('zellij_mru')
vim.keymap.set('v', '<leader>ap', function()
  mru.send_visual({
    script = '/Users/eric/.local/bin/zellij-mru-send',
    enter = false, -- paste only, no submit
  })
end, { desc = 'Paste selection to previous zellij pane' })
```

Workflow:

1. Focus pi/shell/repl pane.
2. Focus nvim pane in same zellij tab.
3. Visual select code.
4. Hit `<leader>ap`.

Payload format:

````md
Context from nvim:
File: path/from/nvim/cwd
Lines: 10-20

```filetype
selection
```
````

## Notes

- Only targets panes in the same zellij tab.
- Target is MRU previous pane, not hard-coded pi.
- Stale/exited/plugin panes are filtered out.
- `zellij-mru-send` refreshes current focus before choosing target, so it works even if poller has not noticed nvim yet.
