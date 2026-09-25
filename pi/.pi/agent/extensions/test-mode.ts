import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import {
	createAssistantMessageEventStream,
	type AssistantMessage,
	type Model,
	type SimpleStreamOptions,
	type TranscriptContext,
} from "@earendil-works/pi-ai/compat";

const PROVIDER = "test-mode";
const MODEL_ID = "gibberish";
const STREAM_DELAY_MS = 40;
const STREAM_CHUNK_CHARS = 10;

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

const STREAM_PARTS = Array.from(
	{ length: Math.ceil(GIBBERISH.length / STREAM_CHUNK_CHARS) },
	(_, index) => GIBBERISH.slice(index * STREAM_CHUNK_CHARS, (index + 1) * STREAM_CHUNK_CHARS),
);

function sleep(ms: number): Promise<void> {
	return new Promise((resolve) => setTimeout(resolve, ms));
}

function streamGibberish(
	model: Model<string>,
	_context: TranscriptContext,
	options?: SimpleStreamOptions,
) {
	const stream = createAssistantMessageEventStream();

	void (async () => {
		const output: AssistantMessage = {
			role: "assistant",
			content: [{ type: "text", text: "" }],
			api: model.api,
			provider: model.provider,
			model: model.id,
			usage: {
				input: 0,
				output: 0,
				cacheRead: 0,
				cacheWrite: 0,
				totalTokens: 0,
				cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
			},
			stopReason: "pending",
			timestamp: Date.now(),
		};

		const abort = () => {
			output.stopReason = "aborted";
			output.errorMessage = "Aborted";
			stream.push({ type: "error", reason: "aborted", error: output });
			stream.end(output);
		};

		try {
			const payload = { model: model.id, stream: true, text: GIBBERISH.length };
			const replacement = await options?.onPayload?.(payload, model);
			void (replacement ?? payload);
			options?.onResponse?.({ status: 200, headers: {} }, model);

			stream.push({ type: "start", partial: output });
			stream.push({ type: "text_start", contentIndex: 0, partial: output });

			for (const delta of STREAM_PARTS) {
				if (options?.signal?.aborted) {
					abort();
					return;
				}
				const text = output.content[0];
				if (text.type !== "text") throw new Error("Test stream text block disappeared");
				text.text += delta;
				output.usage.output += 1;
				output.usage.totalTokens += 1;
				stream.push({ type: "text_delta", contentIndex: 0, delta, partial: output });
				await sleep(STREAM_DELAY_MS);
			}

			const text = output.content[0];
			if (text.type !== "text") throw new Error("Test stream text block disappeared");
			output.stopReason = "stop";
			stream.push({ type: "text_end", contentIndex: 0, content: text.text, partial: output });
			stream.push({ type: "done", reason: "stop", message: output });
			stream.end(output);
		} catch (error) {
			output.stopReason = "error";
			output.errorMessage = error instanceof Error ? error.message : String(error);
			stream.push({ type: "error", reason: "error", error: output });
			stream.end(output);
		}
	})();

	return stream;
}

export default function testModeExtension(pi: ExtensionAPI) {
	let enabled = false;
	let savedModel: Model<string> | undefined;

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

	pi.registerProvider(PROVIDER, {
		name: "Test Mode",
		baseUrl: "test://local",
		apiKey: "test",
		api: "test-mode-gibberish",
		models: [
			{
				id: MODEL_ID,
				name: "Test Gibberish",
				reasoning: false,
				input: ["text"],
				cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
				contextWindow: 200_000,
				maxTokens: 8_192,
			},
		],
		streamSimple: streamGibberish,
	});

	pi.on("session_start", (_event, ctx) => {
		enabled = false;
		savedModel = undefined;
		applyBadge(ctx);
	});

	pi.registerCommand("test", {
		description: "Toggle fake streaming LLM mode",
		handler: async (_args, ctx) => {
			if (!enabled) {
				const fake = ctx.modelRegistry.find(PROVIDER, MODEL_ID);
				if (!fake) {
					if (ctx.hasUI) ctx.ui.notify("Test model is not registered", "error");
					return;
				}
				savedModel = ctx.model;
				const switched = await pi.setModel(fake);
				if (!switched) {
					savedModel = undefined;
					if (ctx.hasUI) ctx.ui.notify("Could not switch to test model", "error");
					return;
				}
				enabled = true;
			} else {
				enabled = false;
				const restore = savedModel;
				savedModel = undefined;
				if (restore) await pi.setModel(restore);
			}

			applyBadge(ctx);
			if (ctx.hasUI) ctx.ui.notify(enabled ? "Test mode on" : "Test mode off", "info");
		},
	});
}
