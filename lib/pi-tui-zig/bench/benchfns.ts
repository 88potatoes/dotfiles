/**
 * TS-vs-Zig correctness + speed comparison for the 4 hot functions.
 * Run: npm run benchfns
 *
 * TS reference impls are copied verbatim from pi-tui dist/utils.js
 * (splitIntoTokensWithAnsi and graphemeWidth are module-private there).
 * The Zig addon handles printable-ASCII + ANSI byte-exactly and signals
 * fallback (-1 / null) for anything needing Intl.Segmenter / Unicode tables.
 */
import { extractAnsiCode } from "@earendil-works/pi-tui/dist/utils.js";
import { visibleWidth as tsVisibleWidth } from "@earendil-works/pi-tui";
import { eastAsianWidth } from "get-east-asian-width";
import {
	hasNative,
	visibleWidth as anyVisibleWidth,
	splitIntoTokensWithAnsi as anySplit,
	graphemeWidth as anyGraphemeWidth,
	ansiCodeAt as anyAnsiCodeAt,
} from "./loader.js";

// ---------------------------------------------------------------------------
// Reference TS impls (copied verbatim from pi-tui dist/utils.js)
// ---------------------------------------------------------------------------
const graphemeSegmenter = new Intl.Segmenter(undefined, { granularity: "grapheme" });
const cjkBreakRegex = /[\p{Script_Extensions=Han}\p{Script_Extensions=Hiragana}\p{Script_Extensions=Katakana}\p{Script_Extensions=Hangul}\p{Script_Extensions=Bopomofo}]/u;
const zeroWidthRegex = /^(?:\p{Default_Ignorable_Code_Point}|\p{Control}|\p{Mark}|\p{Surrogate})+$/v;
const leadingNonPrintingRegex = /^[\p{Default_Ignorable_Code_Point}\p{Control}\p{Format}\p{Mark}\p{Surrogate}]+/v;
const nonPrintingCharRegex = /^(?:\p{Default_Ignorable_Code_Point}|\p{Control}|\p{Format}|\p{Mark}|\p{Surrogate})$/v;
const markCharRegex = /^\p{Mark}$/v;
const terminalSpacingMarkRegex = /^(?:[\p{Spacing_Mark}--[\u1734\u302E\u302F]]|[\u065F\u0F7F\u102B\u102C\u1031\u1033-\u1035\u1038\u103A-\u103E])+$/v;
const rgiEmojiRegex = /^\p{RGI_Emoji}$/v;

function couldBeEmoji(segment) {
	const cp = segment.codePointAt(0);
	return (
		(cp >= 0x1f000 && cp <= 0x1fbff) ||
		(cp >= 0x2300 && cp <= 0x23ff) ||
		(cp >= 0x2600 && cp <= 0x27bf) ||
		(cp >= 0x2b50 && cp <= 0x2b55) ||
		segment.includes("\uFE0F") ||
		segment.length > 2
	);
}

function tsGraphemeWidth(segment) {
	if (segment === "\t") return 3;
	if (terminalSpacingMarkRegex.test(segment)) return [...segment].length;
	if (zeroWidthRegex.test(segment)) return 0;
	if (couldBeEmoji(segment) && rgiEmojiRegex.test(segment)) return 2;
	const base = segment.replace(leadingNonPrintingRegex, "");
	const cp = base.codePointAt(0);
	if (cp === undefined) return 0;
	if (cp >= 0x1f1e6 && cp <= 0x1f1ff) return 2;
	let width = eastAsianWidth(cp);
	let followsMark = false;
	const chars = [...base];
	for (const char of chars.slice(1)) {
		if (terminalSpacingMarkRegex.test(char)) {
			width += 1;
			followsMark = false;
		} else if (markCharRegex.test(char)) {
			followsMark = true;
		} else if (!nonPrintingCharRegex.test(char)) {
			const c = char.codePointAt(0);
			if (followsMark || (c >= 0xff00 && c <= 0xffef)) {
				width += eastAsianWidth(c);
			} else if (c === 0x0e33 || c === 0x0eb3) {
				width += 1;
			}
			followsMark = false;
		}
	}
	return width;
}

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
			const segmentKind = segmentIsSpace ? "space" : "word";
			if (current && currentKind !== segmentKind) {
				tokens.push(current);
				current = "";
				currentKind = null;
			}
			if (pendingAnsi) {
				current += pendingAnsi;
				pendingAnsi = "";
			}
			currentKind = segmentKind;
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

// ---------------------------------------------------------------------------
// Corpus: deterministic pseudo-random styled markdown-ish lines (ASCII + ANSI)
// plus a few non-ASCII lines that exercise the fallback path.
// ---------------------------------------------------------------------------
const WORDS = "the quick brown fox jumps over lazy dog renderer tracks previous lines only rewrites changed rows streaming updates stay cheap width returns array strings terminal columns escape sequences".split(" ");
const STYLES = ["\x1b[1m", "\x1b[3m", "\x1b[33m", "\x1b[36m", "\x1b[90m", "\x1b[38;5;240m"];
const RESET = "\x1b[0m";

function makeLine(i) {
	let s = 0x2f6e2b1 ^ i;
	const rnd = () => ((s = (s * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff);
	const parts = [];
	const nWords = 6 + (i % 12);
	for (let w = 0; w < nWords; w++) {
		const word = WORDS[Math.floor(rnd() * WORDS.length)];
		if (rnd() < 0.25) {
			parts.push(STYLES[Math.floor(rnd() * STYLES.length)] + word + RESET);
		} else if (rnd() < 0.08) {
			parts.push(`\x1b]8;;https://example.com/${word}\x1b\\${word}\x1b]8;;\x1b\\`);
		} else {
			parts.push(word);
		}
	}
	return parts.join(" ") + (i % 7 === 0 ? "\tindent" : "");
}

const CORPUS = Array.from({ length: 1000 }, (_, i) => makeLine(i));
const NON_ASCII_LINES = ["日本語のテキストは幅2", "emoji 🎉 and café", "combining: é\u0301"];
const FULL_CORPUS = [...CORPUS, ...NON_ASCII_LINES];

// ---------------------------------------------------------------------------
// Correctness
// ---------------------------------------------------------------------------
let failures = 0;
function check(name, a, b, ctx) {
	const same = JSON.stringify(a) === JSON.stringify(b);
	if (!same) {
		failures++;
		if (failures <= 5)
			console.error(`FAIL ${name} (${ctx}): ${JSON.stringify(a)} vs ${JSON.stringify(b)}`);
	}
}

for (const line of FULL_CORPUS) {
	check("visibleWidth", anyVisibleWidth(line), tsVisibleWidth(line), line.slice(0, 40));
	check("splitTokens", anySplit(line), tsSplitIntoTokensWithAnsi(line), line.slice(0, 40));
	for (let p = 0; p < Math.min(line.length, 10); p++) {
		check("ansiCodeAt", anyAnsiCodeAt(line, p), extractAnsiCode(line, p), `${line.slice(0, 20)}@${p}`);
	}
}
for (const line of CORPUS.slice(0, 200)) {
	for (const { segment } of graphemeSegmenter.segment(line)) {
		check("graphemeWidth", anyGraphemeWidth(segment), tsGraphemeWidth(segment), segment);
	}
}
// fallback path must still agree for non-ASCII
for (const line of NON_ASCII_LINES) {
	check("splitTokens(nonascii)", anySplit(line), tsSplitIntoTokensWithAnsi(line), line);
	check("visibleWidth", anyVisibleWidth(line), tsVisibleWidth(line), line);
}

console.log(`correctness: ${failures === 0 ? "OK (all match)" : failures + " FAILURES"}`);

// ---------------------------------------------------------------------------
// Speed
// ---------------------------------------------------------------------------
const ITER = 200;
function bench(name, fn) {
	for (let i = 0; i < ITER / 10; i++) fn();
	const t0 = process.hrtime.bigint();
	for (let i = 0; i < ITER; i++) fn();
	const ms = Number(process.hrtime.bigint() - t0) / 1e6;
	const nsPerOp = (ms * 1e6) / (FULL_CORPUS.length * ITER);
	console.log(`${name}: ${ms.toFixed(0)}ms total, ${nsPerOp.toFixed(0)}ns/op`);
	return ms;
}

console.log(`\nnative: ${hasNative ? "zig addon loaded" : "NOT LOADED (TS only)"}\n`);

const tsVw = bench("TS  visibleWidth             ", () => {
	for (const l of FULL_CORPUS) tsVisibleWidth(l);
});
let zigVwMs = 0;
if (hasNative) {
	zigVwMs = bench("Zig visibleWidth (w/ fallback)", () => {
		for (const l of FULL_CORPUS) anyVisibleWidth(l);
	});
}

const tsSplit = bench("TS  splitIntoTokensWithAnsi  ", () => {
	for (const l of FULL_CORPUS) tsSplitIntoTokensWithAnsi(l);
});
let zigSplitMs = 0;
if (hasNative) {
	zigSplitMs = bench("Zig splitIntoTokensWithAnsi  ", () => {
		for (const l of FULL_CORPUS) anySplit(l);
	});
}

const tsAnsi = bench("TS  extractAnsiCode          ", () => {
	for (const l of FULL_CORPUS) {
		for (let p = 0; p < Math.min(l.length, 10); p++) extractAnsiCode(l, p);
	}
});
let zigAnsiMs = 0;
if (hasNative) {
	zigAnsiMs = bench("Zig ansiCodeAt               ", () => {
		for (const l of FULL_CORPUS) {
			for (let p = 0; p < Math.min(l.length, 10); p++) anyAnsiCodeAt(l, p);
		}
	});
}

const tsGw = bench("TS  graphemeWidth (segments) ", () => {
	for (const l of CORPUS.slice(0, 200)) {
		for (const { segment } of graphemeSegmenter.segment(l)) tsGraphemeWidth(segment);
	}
});
let zigGwMs = 0;
if (hasNative) {
	zigGwMs = bench("Zig graphemeWidth (segments) ", () => {
		for (const l of CORPUS.slice(0, 200)) {
			for (const { segment } of graphemeSegmenter.segment(l)) anyGraphemeWidth(segment);
		}
	});
}

if (hasNative) {
	console.log("\nspeedups (zig incl. fallback vs ts):");
	if (zigVwMs > 0) console.log(`  visibleWidth:            ${(tsVw / zigVwMs).toFixed(1)}x`);
	if (zigSplitMs > 0) console.log(`  splitIntoTokensWithAnsi: ${(tsSplit / zigSplitMs).toFixed(1)}x`);
	if (zigAnsiMs > 0) console.log(`  extractAnsiCode:         ${(tsAnsi / zigAnsiMs).toFixed(1)}x`);
	if (zigGwMs > 0) console.log(`  graphemeWidth:           ${(tsGw / zigGwMs).toFixed(1)}x`);
}