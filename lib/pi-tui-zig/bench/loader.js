// Loader for the Zig N-API addon with transparent TS fallback.
// Zig handles printable-ASCII (+ANSI) input byte-exactly; anything returning
// -1/null (non-ASCII: CJK, emoji, combining marks) falls back to the original
// pi-tui TS implementations so correctness is never traded for speed.
// extractAnsiCode isn't re-exported by pi-tui's index; import from the module directly
import { extractAnsiCode } from "@earendil-works/pi-tui/dist/utils.js";
import { visibleWidth as tsVisibleWidth } from "@earendil-works/pi-tui";

const graphemeSegmenter = new Intl.Segmenter(undefined, { granularity: "grapheme" });
const cjkBreakRegex = /[\p{Script_Extensions=Han}\p{Script_Extensions=Hiragana}\p{Script_Extensions=Katakana}\p{Script_Extensions=Hangul}\p{Script_Extensions=Bopomofo}]/u;
const require = (await import("node:module")).createRequire(import.meta.url);
let native;
try {
	native = require("../pi_tui_zig.node");
} catch {
	native = null;
}

// JS fallback port of splitIntoTokensWithAnsi (pi-tui's is module-private).
function tsSplitIntoTokensWithAnsi(text) {
	const tokens = [];
	let current = "";
	let pendingAnsi = "";
	let currentKind = null;
	let i = 0;
	while (i < text.length) {
		const ansi = extractAnsiCode(text, i);
		if (ansi) {
			pendingAnsi += ansi.code;
			i += ansi.length;
			continue;
		}
		let end = i;
		while (end < text.length && !extractAnsiCode(text, end)) end++;
		for (const { segment } of graphemeSegmenter.segment(text.slice(i, end))) {
			const segmentIsSpace = segment === " ";
			if (!segmentIsSpace && cjkBreakRegex.test(segment)) {
				if (current) tokens.push(current);
				tokens.push(pendingAnsi + segment);
				pendingAnsi = "";
				current = "";
				currentKind = null;
				continue;
			}
			const kind = segment === " " ? "space" : "word";
			if (current && currentKind !== kind) {
				if (current) tokens.push(current);
				current = "";
			}
			if (pendingAnsi) {
				current += pendingAnsi;
				pendingAnsi = "";
			}
			currentKind = kind;
			current += segment;
		}
		i = end;
	}
	if (pendingAnsi) {
		if (current) current += pendingAnsi;
		else if (tokens.length > 0) tokens[tokens.length - 1] += pendingAnsi;
		else current = pendingAnsi;
	}
	if (current) tokens.push(current);
	return tokens;
}

export const hasNative = native !== null;

export function visibleWidth(str) {
	const w = native?.visibleWidth(str) ?? -1;
	return w >= 0 ? w : tsVisibleWidth(str);
}

export function graphemeWidth(segment) {
	const w = native?.graphemeWidth(segment) ?? -1;
	return w >= 0 ? w : tsVisibleWidth(segment); // fallback approximation; exotic segments go to TS
}

export function ansiCodeAt(str, pos) {
	return native?.ansiCodeAt(str, pos) ?? extractAnsiCode(str, pos);
}

export function splitIntoTokensWithAnsi(text) {
	return native?.splitIntoTokensWithAnsi(text) ?? tsSplitIntoTokensWithAnsi(text);
}