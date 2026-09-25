# pi-tui tier2 render bench — results

Harness: `bench.ts` — real `TuiMainScreen` + scheduler + diff-render loop, fake in-memory
`Terminal`, simulated streaming markdown (no LLM, no real terminal).
Run: `npm run bench [-- --chunks N --chunk-size N --interval MS --width N --height N --resize]`

Scenario setup: 20-turn history (~60 Text lines) + one streaming `Markdown` component,
120×40 viewport, machine = M-series MacBook Pro, Node v24.16.0, pi-tui 0.84.2.

| Scenario | Frames | doRender mean | p99 | max | Bytes written |
|---|---|---|---|---|---|
| realistic (400 chunks @ 30ms) | 400 | 0.65ms | 1.13ms | 5.05ms | 114 KiB |
| max throughput (1000 chunks, yield-only) | 82 | 1.64ms | 5.71ms | 5.71ms | 101 KiB |
| + resize stress (4 full redraws) | 36 | 1.37ms | 5.46ms | 5.46ms | 196 KiB |
| width 60 (heavier wrapping) | 1* | 13.45ms | 13.45ms | 13.45ms | 28.7 KiB |

*yield bug in first run — fixed; burst mode now renders per-chunk (82 frames / 1000 chunks).

## CPU profile (node --cpu-prof, 2000-chunk burst, % of all samples)

```
(idle)                  51.7%   (throttle-bound: 16ms MIN_RENDER_INTERVAL)
visibleWidth             9.8%
(program)                4.8%
splitIntoTokensWithAnsi  4.8%
graphemeWidth            4.4%
RegExp (latex detect)    1.6%
wrapSingleLine           1.5%
extractAnsiCode          1.4%
(garbage collector)      1.2%
```

## Conclusions

1. **~44% of non-idle render compute** is in four functions: `visibleWidth`,
   `splitIntoTokensWithAnsi`, `graphemeWidth`, `extractAnsiCode` (all in pi-tui `utils.js`).
2. The diff-render loop and scheduler are cheap: `doRender` p99 ≈ 5ms vs the 16ms throttle.
   Frames cap at ~55–60/s regardless — real-world wins come from full-redraw paths
   (resize, large paste) where `doRender` spikes to 12ms+.
3. Zig-rewrite targets (priority order): `visibleWidth`, `splitIntoTokensWithAnsi`,
   `graphemeWidth`, `extractAnsiCode`. See `native/zig/` for the implementation and
   `npm run benchfns` for TS-vs-Zig comparison.

## Zig rewrite results (`native/zig/`, `npm run benchfns`)

Scope: byte-exact Zig ports for printable-ASCII + ANSI input (what pi renders 99% of
the time); non-ASCII (CJK/emoji/combining) returns a fallback sentinel and the JS
loader defers to the original TS implementations, so correctness is preserved.

| Function | TS | Zig (incl. N-API boundary + fallback) | Speedup |
|---|---|---|---|
| `visibleWidth` | 7754ns/op | 201ns/op | **38.5x** |
| `splitIntoTokensWithAnsi` | 11342ns/op | 1854ns/op | **6.1x** |
| `extractAnsiCode` (per-call) | 56ns/op | 1243ns/op | **0.05x (slower)** |
| `graphemeWidth` (per-call) | 2063ns/op | 1741ns/op | 1.2x |

Correctness: all four match the TS reference byte-for-byte across a 1000-line
ANSI-styled corpus + non-ASCII fallback lines (`native/index.js` loader falls back
to pi-tui TS for anything Zig defers on).

**N-API boundary lesson:** per-call marshalling (`napi_get_value_string_utf8` copies
the whole string) costs ~1µs — it swamps cheap functions (`extractAnsiCode`,
`graphemeWidth`), so per-call Zig wrappers only pay off when the function does real
work (`visibleWidth`). A production integration would use **batch APIs** — e.g. one
Zig call that scans a whole line (ANSI strip + token split + wrap) instead of
per-character/per-position calls. `visibleWidth` already amortizes the copy and
shows the real potential: ~38x.