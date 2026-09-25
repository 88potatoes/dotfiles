#!/usr/bin/env node
/**
 * Re-applies the pi-tui-zig fast path to the globally installed pi-coding-agent.
 * Idempotent: skips if already patched. Run after `npm -g update @earendil-works/pi-coding-agent`
 * or after a Nix/homebrew rebuild refreshes the npm tree.
 *
 *   node ~/lib/pi-tui-zig/patch.mjs
 */
import fs from "node:fs";
import path from "node:path";

const MARKER = "[pi-tui-zig]";
const candidates = [
	"/opt/homebrew/lib/node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui/dist/utils.js",
	path.join(process.env.HOME, ".npm-global/lib/node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui/dist/utils.js"),
];
const ADDON = path.join(process.env.HOME, "lib/pi-tui-zig/pi_tui_zig.node");
const utilsPath = candidates.find((p) => fs.existsSync(p));
if (!utilsPath) {
	console.error("utils.js not found; update candidates in patch.mjs");
	process.exit(1);
}
if (!fs.existsSync(ADDON)) {
	console.error(`addon missing: ${ADDON} — build it in ~/Code/pi-tui-bench first`);
	process.exit(1);
}

let src = fs.readFileSync(utilsPath, "utf8");
if (src.includes(MARKER)) {
	console.log(`already patched: ${utilsPath}`);
	process.exit(0);
}

const anchorImport = 'import { eastAsianWidth } from "get-east-asian-width";';
const anchorVisible = "export function visibleWidth(str) {";
const anchorSplit = "function splitIntoTokensWithAnsi(text) {";
if (!src.includes(anchorImport) || !src.includes(anchorVisible) || !src.includes(anchorSplit)) {
	console.error("unexpected utils.js layout — patch manually");
	process.exit(1);
}

src = src.replace(
	anchorImport,
	`${anchorImport}
// ${MARKER} native fast path
import { createRequire as _zigCreateRequire } from "node:module";
let _zigNative = null;
try {
	_zigNative = _zigCreateRequire(import.meta.url)(${JSON.stringify(ADDON)});
} catch {
	// native addon unavailable: TS fallbacks handle everything
}`,
);
src = src.replace(
	anchorVisible,
	`export function visibleWidth(str) {
	if (_zigNative) {
		const w = _zigNative.visibleWidth(str);
		if (w >= 0)
			return w;
	}
	return _zigVisibleWidthTS(str);
}
function _zigVisibleWidthTS(str) {`,
);
src = src.replace(
	anchorSplit,
	`function splitIntoTokensWithAnsi(text) {
	if (_zigNative) {
		const t = _zigNative.splitIntoTokensWithAnsi(text);
		if (t !== null)
			return t;
	}
	return _zigSplitIntoTokensWithAnsiTS(text);
}
function _zigSplitIntoTokensWithAnsiTS(text) {`,
);

fs.copyFileSync(utilsPath, utilsPath + ".pre-zig");
fs.writeFileSync(utilsPath, src);
console.log(`patched: ${utilsPath} (backup: ${utilsPath}.pre-zig)`);