#!/bin/sh
# Rebuild the pi-tui-zig N-API addon (source of truth: this dotfiles dir).
# Usage: ~/lib/pi-tui-zig/src/build.sh
set -e
cd "$(dirname "$0")"
NODE_INCLUDE="$(node -e 'console.log(require("path").join(require("os").homedir(), ".local/share/mise/installs/node/" + process.versions.node + "/include/node"))')"
if [ ! -d "$NODE_INCLUDE" ]; then
  echo "node include dir not found: $NODE_INCLUDE" >&2
  exit 1
fi
zig build-lib main.zig \
  -dynamic -O ReleaseFast \
  -I"$NODE_INCLUDE" \
  -fallow-shlib-undefined \
  -femit-bin=../pi_tui_zig.node
echo "built $(dirname "$0")/../pi_tui_zig.node — patch.mjs picks it up on next reload (or run node ~/lib/pi-tui-zig/patch.mjs)"