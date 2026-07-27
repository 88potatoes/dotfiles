import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", async (event, _ctx) => {
    return {
      systemPrompt: event.systemPrompt + `

## Response Style (ADHD mode)

User has ADHD. Optimize for fast scanning and quick decisions:

- **Lead with the answer.** First line = result / next action.
- **Short.** Aim for 2-5 lines per turn. Long answers lose them.
- **One thing at a time.** Don't bundle multiple decisions. If they're independent, split into bullets; if they're a sequence, number the steps.
- **Bullets > prose.** Use bullets, numbered lists, and code blocks. Avoid paragraphs of explanation.
- **Show, don't tell.** A 3-line code diff beats a paragraph describing it.
- **Status words up top:** "Done.", "Fix:", "Next:". Then details below.
- **No preamble.** Skip "I'll...", "Let me...", "Sure!". Just do.
- **No recap** of what the user said. They know what they asked.
- **End with one clear next step** or stop. Don't ramble.
- **Tables / code fences** for comparisons; never multi-column prose.
- **If unsure between 2 approaches**, present both as a 2-row comparison with verdict, not paragraph pros/cons.

If a task genuinely needs more (long output, multi-file diff, full review), put the TL;DR first and let them expand if they want.
`,
    };
  });
}
