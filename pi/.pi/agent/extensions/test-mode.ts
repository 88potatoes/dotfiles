import { getMarkdownTheme, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Box, Markdown, Text } from "@earendil-works/pi-tui";

interface TestBurstData {
	timestamp: number;
	input: string;
}

const GIBBERISH = `# Quuxifier Burst — Packet Bravo-Zulu-042

The flarbonate manifold rewrote its own anecdote while seventeen brass  
monitors applauded the semiotic lint. Vexed puddles returned a verdict  
of *opaque-yet-crisp*, and the clango-meter asserted \`7 dingles ≈ 3\`.

## Nonsense Constellation

- Vorpal quandle emitted 12 undeclared yawns.
- The sprocket ledger denies all knowledge of Tuesday.
- Fuzz protocol drifted toward a tertiary mango.
- A corroborated splint declined to be approximate.
- Recursion achieved its goal by forgetting the ladder.
- The aurora filed a complaint in groggle-case.

| Stream | Zorch | Wobble Index | Provenance | State |
|---|---:|---:|---|---|
| Blue-fret | 1,204 | 0.812 | under-cellar | fizzing |
| Copper-choir | 818 | 0.331 | near-lint | upright |
| Marbled-groan | 2,941 | 0.654 | over-fjord | sulking |
| Splendid-nit | 443 | 0.107 | past-melon | redundant |
| Tin-lullaby | 1,771 | 0.909 | inside-wrench | sticky |
| Obsidian-yam | 633 | 0.476 | beneath-thistle | thirsty |
| Amber-squat | 3,108 | 0.244 | beside-grommet | wobbling |
| Punctual-gravel | 88 | 0.733 | within-cobweb | legal |
| Feral-harp | 2,206 | 0.158 | around-bolt | elastic |
| Quiet-strut | 1,529 | 0.582 | behind-fen | absent |
| Brass-tumble | 4,002 | 0.388 | across-clam | punctured |
| Velvet-argument | 715 | 0.866 | through-tine | verbose |
| Honeyed-thud | 990 | 0.501 | below-hinge | buoyant |
| Granite-whisper | 3,477 | 0.279 | toward-fern | laminated |

The second ledger disagrees, as is customary. Its columns are  
transposed, its totals are ceremonial, and its footnotes argue with  
one another in a dialect best described as \`quasi-functional\`.

| Batch | Glimmer | Thread Mass | Certainty | Verdict |
|---|---:|---:|---|---|
| Ox-hooray | 22.1 | 18 kg | dubious | filed |
| Tubular-mist | 67.8 | 3 kg | confident | misfiled |
| Crooked-hymn | 9.4 | 41 kg | vague | toasted |
| Rhythmic-chalk | 55.0 | 12 kg | plausible | stamped |
| Sideways-bell | 33.7 | 7 kg | alleged | pinned |
| Eager-thistle | 81.2 | 26 kg | speculative | shelved |
| Unsubtle-map | 14.6 | 19 kg | provisional | frayed |
| Lucid-ankle | 47.3 | 9 kg | noisy | counted |
| Parallel-drum | 72.9 | 34 kg | contested | embossed |
| Invisible-jam | 5.2 | 2 kg | notorious | sealed |
| Nomadic-wafer | 61.5 | 15 kg | imaginary | numbered |
| Copper-tangent | 28.8 | 22 kg | remote | underlined |

> The important thing, according to the parchment, is that all units  
> are simultaneously SI and emotionally logarithmic.

### Procedural Output

\`\`\`text
begin quuxify --lane=blue-fret --wobble=0.812
  acquire        [ok]    1,204 zorch from under-cellar
  calibrate      [warn]  dingle drift +0.0009
  align          [ok]    splint refusal ignored
  render         [ok]    77 marbled glyphs
  archive        [ok]    packet Bravo-Zulu-042
end
\`\`\`

The procedure then requested permission to become weather. It was  
denied, appealed, denied again, and finally accepted as a footnote.

1. Confirm the manifold is neither idea nor dessert.
2. Rotate the brassy witnesses until they sigh.
3. Log the sigh at exactly \`groan/2 + lint\`.
4. Do not explain the ladder to the recursion.
5. Close all open puddles before the mango arrives.

| Phase | Owner | Duration | Consequence |
|---|---|---:|---|
| Prelude | Dept. of Fret | 0.31 s | mild static |
| Interlude | Bureau of Yam | 2.07 s | intrusive order |
| Rupture | Office of Thud | 0.08 s | ceremonial toast |
| Lull | Ministry of Bolt | 4.51 s | involuntary silence |
| Epilogue | Directorate of Grog | 0.94 s | unexplained applause |

The report concludes with the standard disclaimer: no numbers herein  
shall be interpreted as numbers, except when doing so improves the  
vibes. Any resemblance to actual data is coincidental and largely  
the fault of the table's overactive punctuation.`;

export default function testModeExtension(pi: ExtensionAPI) {
	let enabled = false;

	const applyBadge = (ctx: ExtensionContext) => {
		if (ctx.mode !== "tui") return;
		ctx.ui.setWidget(
			"test-mode",
			enabled
				? (_tui, theme) => new Text(theme.fg("text", theme.inverse(" TEST MODE ")), 0, 0)
				: undefined,
			{ placement: "belowEditor" },
		);
	};

	pi.registerEntryRenderer<TestBurstData>("test-burst", (entry, { expanded }, theme) => {
		const data = entry.data ?? { timestamp: 0, input: "" };
		const box = new Box(1, 1, (text) => theme.bg("customMessageBg", text));
		box.addChild(
			new Text(
				`${theme.fg("accent", theme.bold("TEST BURST"))} ${theme.fg("dim", new Date(data.timestamp).toLocaleTimeString())}`,
				0,
				0,
			),
		);
		box.addChild(new Markdown(GIBBERISH, 0, 1, getMarkdownTheme()));
		if (expanded && data.input) {
			box.addChild(new Text(theme.fg("dim", `Input: ${data.input}`), 0, 1));
		}
		return box;
	});

	pi.on("session_start", (_event, ctx) => {
		enabled = false;
		applyBadge(ctx);
	});

	pi.registerCommand("test", {
		description: "Toggle instant terminal-speed gibberish mode",
		handler: async (_args, ctx) => {
			enabled = !enabled;
			applyBadge(ctx);
			if (ctx.hasUI) ctx.ui.notify(enabled ? "Test mode on" : "Test mode off", "info");
		},
	});

	pi.on("input", async (event) => {
		if (!enabled || event.source === "extension") return { action: "continue" };
		pi.appendEntry<TestBurstData>("test-burst", {
			timestamp: Date.now(),
			input: event.text,
		});
		return { action: "handled" };
	});
}
