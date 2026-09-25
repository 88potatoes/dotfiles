/**
 * Tier 2 pi-tui render bench: real TuiMainScreen + scheduler + diff-render loop,
 * fake in-memory terminal, simulated streaming text (no LLM, no real terminal).
 *
 * Usage:
 *   npm run bench                      # defaults
 *   npm run bench -- --chunks 500      # number of streaming chunks
 *   npm run bench -- --chunk-size 40   # chars per chunk
 *   npm run bench -- --interval 0      # ms between chunks (0 = max throughput)
 *   npm run bench -- --width 100       # terminal width
 *   npm run profile                    # writes .cpuprof for flame chart
 */
import {
	Container,
	type Component,
	Markdown,
	Text,
	TuiMainScreen,
	type Terminal,
} from "@earendil-works/pi-tui";

// ---------------------------------------------------------------------------
// Args
// ---------------------------------------------------------------------------
const args = process.argv.slice(2);
function argValue(name: string): string | undefined {
	const i = args.indexOf(`--${name}`);
	return i >= 0 ? args[i + 1] : undefined;
}
const CHUNKS = Number(argValue("chunks") ?? 400);
const CHUNK_SIZE = Number(argValue("chunk-size") ?? 25);
const INTERVAL_MS = Number(argValue("interval") ?? 30);
const TERM_WIDTH = Number(argValue("width") ?? 120);
const TERM_HEIGHT = Number(argValue("height") ?? 40);
const DO_RESIZE = args.includes("--resize");

// ---------------------------------------------------------------------------
// Fake terminal: satisfies the Terminal interface, counts writes
// ---------------------------------------------------------------------------
class FakeTerminal implements Terminal {
	writtenBytes = 0;
	writes = 0;
	onInput?: (data: string) => void;
	onResize?: () => void;

	columns = TERM_WIDTH;
	rows = TERM_HEIGHT;

	write(data: string) {
		this.writtenBytes += data.length;
		this.writes++;
	}
	start(onInput: (data: string) => void, onResize: () => void) {
		this.onInput = onInput;
		this.onResize = onResize;
	}
	stop() {}
	async drainInput() {}
	moveBy() {}
	hideCursor() {}
	showCursor() {}
	clearLine() {}
	clearFromCursor() {}
	clearScreen() {}
	setTitle() {}
	setProgress() {}
	get kittyProtocolActive() {
		return false;
	}
}

// ---------------------------------------------------------------------------
// Sample markdown resembling an assistant coding answer
// ---------------------------------------------------------------------------
const PARAGRAPHS = [
	"The diff renderer tracks `previousLines` and only rewrites changed rows, so streaming updates stay cheap once the transcript stabilizes.",
	"## Implementation notes\n\n1. Components return `string[]` from `render(width)`\n2. The scheduler throttles to 16ms between frames\n3. Width changes force a full redraw",
	"**Bold claims** need *evidence*, and `inline code` needs escaping. Links like [pi-tui](https://github.com/earendil-works/pi) are styled per line.",
	"```ts\nconst tui = new TuiMainScreen(terminal);\ntui.addChild(new Markdown(text));\n```\n\nThe above allocates a new string array every frame.",
];
function nextChunk(i: number): string {
	const p = PARAGRAPHS[i % PARAGRAPHS.length];
	const start = (i * CHUNK_SIZE) % (p.length - CHUNK_SIZE);
	return p.slice(Math.max(0, start), start + CHUNK_SIZE) + " ";
}

// ---------------------------------------------------------------------------
// Set up a pi-like transcript: growing history + one streaming markdown line
// ---------------------------------------------------------------------------
const terminal = new FakeTerminal();
const root = new Container();

// done history lines (like completed chat turns)
const history: Text[] = [];
for (let turn = 0; turn < 20; turn++) {
	history.push(new Text(`> user turn ${turn}: explain the change scope`, 0, 0));
	history.push(new Text(PARAGRAPHS[turn % PARAGRAPHS.length], 0, 0));
	history.push(new Text("", 0, 0));
}
for (const h of history) root.addChild(h);

const mdTheme = {
	heading: (t: string) => `\x1b[1m${t}\x1b[0m`,
	link: (t: string) => `\x1b[36m${t}\x1b[0m`,
	linkUrl: (t: string) => `\x1b[2m${t}\x1b[0m`,
	code: (t: string) => `\x1b[33m${t}\x1b[0m`,
	codeBlock: (t: string) => `\x1b[90m${t}\x1b[0m`,
	codeBlockBorder: (t: string) => `\x1b[90m${t}\x1b[0m`,
	quote: (t: string) => `\x1b[2m${t}\x1b[0m`,
	quoteBorder: (t: string) => `\x1b[2m${t}\x1b[0m`,
	hr: (t: string) => `\x1b[2m${t}\x1b[0m`,
	listBullet: (t: string) => `\x1b[36m${t}\x1b[0m`,
	bold: (t: string) => `\x1b[1m${t}\x1b[0m`,
	italic: (t: string) => `\x1b[3m${t}\x1b[0m`,
	strikethrough: (t: string) => `\x1b[9m${t}\x1b[0m`,
	underline: (t: string) => `\x1b[4m${t}\x1b[0m`,
};
const streaming = new Markdown("", 0, 0, mdTheme);
root.addChild(streaming);
const realTui = new TuiMainScreen(terminal, false);
realTui.addChild(root);

// ---------------------------------------------------------------------------
// Instrument doRender: time each frame, count lines
// ---------------------------------------------------------------------------
const frameMs: number[] = [];
const originalDoRender = Object.getPrototypeOf(realTui).doRender.bind(realTui);
(Object.getPrototypeOf(realTui) as { doRender: () => void }).doRender = () => {
	const t0 = performance.now();
	originalDoRender();
	frameMs.push(performance.now() - t0);
};

const fake = realTui.terminal as FakeTerminal;

// ---------------------------------------------------------------------------
// Run: pump chunks like text_delta events
// ---------------------------------------------------------------------------
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function main() {
	let streamed = "";
	const t0 = performance.now();

	for (let i = 0; i < CHUNKS; i++) {
		streamed += nextChunk(i);
		streaming.setText(streamed);
		realTui.requestRender();
		// interval 0 = yield only to the scheduler (max throughput stress)
		await sleep(INTERVAL_MS > 0 ? INTERVAL_MS : 0);
	}
	// let the scheduler drain
	await sleep(100);

	// optional resize stress: force full-redraw paths
	if (DO_RESIZE) {
		for (const w of [100, 90, 110, TERM_WIDTH]) {
			fake.columns = w;
			realTui.requestRender(true);
			await sleep(50);
		}
	}
	await sleep(100);

	const wall = performance.now() - t0;
	frameMs.sort((a, b) => a - b);
	const sum = frameMs.reduce((a, b) => a + b, 0);
	const pct = (p: number) => frameMs[Math.min(frameMs.length - 1, Math.floor(frameMs.length * p))];
	const fullRedraws = Number(
		(realTui as unknown as { fullRedrawCount?: number }).fullRedrawCount ?? -1,
	);

	console.log("== pi-tui tier2 bench ==");
	console.log(`chunks=${CHUNKS} chunkSize=${CHUNK_SIZE} interval=${INTERVAL_MS}ms cols=${TERM_WIDTH}`);
	console.log(`wall: ${wall.toFixed(0)}ms  chars streamed: ${streamed.length}`);
	console.log(`frames: ${frameMs.length}  full redraws: ${fullRedraws < 0 ? "n/a" : fullRedraws}`);
	if (frameMs.length > 0) {
		console.log(
			`doRender ms: mean=${(sum / frameMs.length).toFixed(2)} p50=${pct(0.5).toFixed(2)} p95=${pct(0.95).toFixed(2)} p99=${pct(0.99).toFixed(2)} max=${frameMs.at(-1)!.toFixed(2)}`,
		);
	}
	console.log(`terminal writes: ${fake.writes}  bytes: ${(fake.writtenBytes / 1024).toFixed(1)} KiB`);

	realTui.stop();
	process.exit(0);
}

main();