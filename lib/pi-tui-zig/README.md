# pi-tui-zig

Zig N-API fast path for pi-tui's hot text functions (`visibleWidth`,
`splitIntoTokensWithAnsi`). Falls back to TS for non-ASCII input.
Benchmarks and source: `~/Code/pi-tui-bench` (see RESULTS.md there).

## Install / re-apply (after every pi update)

    node ~/lib/pi-tui-zig/patch.mjs

Patches the globally installed `pi-tui/dist/utils.js` (idempotent, backs up to
`utils.js.pre-zig`). `~/lib/pi-tui-zig` is a symlink into this dotfiles dir.

## Kill switch

    mv ~/lib/pi-tui-zig/pi_tui_zig.node{,.off}   # back: remove .off

## Rebuild addon (source lives in ~/Code/pi-tui-bench/native/zig)

    cd ~/Code/pi-tui-bench && npm run build:native
    cp native/zig/pi_tui_zig.node ~/dotfiles/lib/pi-tui-zig/
    node ~/lib/pi-tui-zig/patch.mjs   # only needed if utils.js changed
