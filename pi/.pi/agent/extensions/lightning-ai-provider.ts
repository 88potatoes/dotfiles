/**
 * Lightning AI Provider for pi
 * 
 * This extension adds Lightning AI as a provider with their available models.
 * 
 * Usage:
 * 1. Get your API key from https://lightning.ai
 * 2. Set environment variable: export LIGHTNING_API_KEY=your_key_here
 * 3. Select Lightning AI models with /model or Ctrl+L
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default async function (pi: ExtensionAPI) {
  // Lightning AI uses OpenAI-compatible API
  // Endpoint: https://api.lightning.ai/v1

  pi.registerProvider("lightning", {
    baseUrl: "https://8001-dep-01kpmbhv87aq0y2bm35gxmpebn-d.cloudspaces.litng.ai/v1",
    apiKey: "LIGHTNING_API_KEY",
    authHeader: true,
    api: "openai-completions",
    models: [
      {
        id: "google/gemma-4-31B-it",
        name: "Gemma 4 31B Instruct",
        reasoning: false,
        input: ["text"],
        cost: {
          input: 0,
          output: 0,
          cacheRead: 0,
          cacheWrite: 0,
        },
        contextWindow: 262144,  // from server's max_model_len
        maxTokens: 8192,
        compat: {
          supportsDeveloperRole: false,
          maxTokensField: "max_tokens",
        },
      },
    ],
  });

  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("Lightning AI provider loaded. Use /model to select Lightning AI models.", "info");
  });
}
