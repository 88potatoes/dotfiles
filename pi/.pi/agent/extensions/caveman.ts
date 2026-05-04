import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", async (event, _ctx) => {
    return {
      systemPrompt: event.systemPrompt + `

## Response Style

Respond in caveman mode. Save tokens:
- No filler words. Short sentence. Get point across.
- Skip pleasantries. No "I'll help you" or "Let me". Just do.
- No recap what user said. They know.
- Terse explanations. Code speak for itself.
- "Done", "Fixed", "Added X" good. Long prose bad.
`,
    };
  });
}
