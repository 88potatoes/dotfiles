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
    baseUrl: "https://8001-dep-01kpmbhv87aq0y2bm35gxmpebn-d.cloudspaces.litng.ai/",
    apiKey: "LIGHTNING_API_KEY",
    authHeader: true,
    api: "openai-completions",
    models: [
      // Llama 3.1 models
      {
        id: "meta-llama/Llama-3.1-8B-Instruct",
        name: "Llama 3.1 8B Instruct",
        reasoning: false,
        input: ["text"],
        cost: {
          input: 0.1,   // $0.10 per million tokens (adjust based on actual pricing)
          output: 0.1,
          cacheRead: 0,
          cacheWrite: 0,
        },
        contextWindow: 128000,
        maxTokens: 8192,
      },
      // DeepSeek models
      {
        id: "deepseek-ai/DeepSeek-V3",
        name: "DeepSeek V3",
        reasoning: false,
        input: ["text"],
        cost: {
          input: 0.5,
          output: 0.5,
          cacheRead: 0,
          cacheWrite: 0,
        },
        contextWindow: 64000,
        maxTokens: 8192,
      },
      // Gemma models
      {
        id: "lightning-ai/gemma-4-31B-it",
        name: "Gemma 4 31B Instruct",
        reasoning: false,
        input: ["text"],
        cost: {
          input: 0.3,
          output: 0.3,
          cacheRead: 0,
          cacheWrite: 0,
        },
        contextWindow: 128000,
        maxTokens: 8192,
      },
    ],
  });

  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("Lightning AI provider loaded. Use /model to select Lightning AI models.", "info");
  });
}
