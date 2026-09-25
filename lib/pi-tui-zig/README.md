# pi-tui-zig

Zig N-API fast path for pi-tui's hot text functions (`visibleWidth`,
`splitIntoTokensWithAnsi`). Falls back to TS for non-ASCII input.
Source lives in this dir (`src/`); benchmarks: `~/Code/pi-tui-bench` (RESULTS.md).

## Install / re-apply (after every pi update)

    node ~/lib/pi-tui-zig/patch.mjs

Patches the globally installed `pi-tui/dist/utils.js` (idempotent, backs up to
`utils.js.pre-zig`). `~/lib/pi-tui-zig` is a symlink into this dotfiles dir.

## Kill switch

    mv ~/lib/pi-tui-zig/pi_tui_zig.node{,.off}   # back: remove .off

## Rebuild addon (source in src/)

    ~/lib/pi-tui-zig/src/build.sh

## Benchmark harness (bench/)

    cd ~/lib/pi-tui-zig/bench && npm install
    npm run bench      # tier2: real TuiMainScreen + fake terminal, streaming simulation
    npm run profile    # tier2 with --cpu-prof (flame chart)
    npm run benchfns   # TS-vs-Zig correctness + speed for the 4 ported functions

First run needs `npm install` (uses @earendil-works/pi-tui + get-east-asian-width);
the addon is loaded from ../pi_tui_zig.node. See RESULTS.md for numbers.
