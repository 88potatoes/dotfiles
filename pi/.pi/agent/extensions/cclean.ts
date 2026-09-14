import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

/**
 * /cclean [file or path]
 *
 * Remove redundant, noisy comments that merely restate what the code clearly says
 * (e.g. `// Item 1: ...` right above `{ description: 'Item 1: ...' }`, `// fetch user`
 * directly above `await fetchUser()`, `// check if valid` above `if (isValid)`).
 *
 * Retains meaningful "why" comments, non-obvious domain caveats, or regulatory notices.
 */
export default function (pi: ExtensionAPI) {
	pi.registerCommand("cclean", {
		description: "Clean up redundant comments that merely restate code (usage: /cclean [path])",
		handler: async (args, ctx) => {
			const target = args.trim();
			const instruction = [
				target
					? `Clean up redundant comments in: \`${target}\``
					: "Clean up redundant comments in the currently modified files (git diff).",
				"",
				"Task: Remove all comments that merely restate what the adjacent code clearly expresses.",
				"",
				"Examples to REMOVE:",
				"- `// fetch user` directly above `const user = await fetchUser();`",
				"- `// SWR-3 Item 1: Intended purpose` directly above `medDeviceStep('...', { description: 'Item 1: Intended purpose' })`",
				"- `// check if user exists` directly above `if (user) {`",
				"- `// return result` directly above `return result;`",
				"",
				"Examples to KEEP:",
				"- Explanations of non-obvious workarounds, edge-case bugs, or timing issues (the 'why').",
				"- Essential regulatory or issue citations (e.g. `@pod:evidence`, `EVI-2281`).",
				"- JSDoc on public exported interfaces/types that provide IDE documentation.",
				"",
				"After removing redundant comments, run type checks / validation on the touched files.",
			].join("\n");

			pi.sendUserMessage(instruction, { deliverAs: "followUp" });
		},
	});
}
