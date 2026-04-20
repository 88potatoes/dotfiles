# Lightning AI Provider Extension

This extension adds [Lightning AI](https://lightning.ai) as a model provider for pi.

## Setup

### 1. Get Your API Key

Visit [Lightning AI](https://lightning.ai) and create an API key.

### 2. Set Environment Variable

Add to your shell profile (`~/.zshrc`, `~/.bashrc`, etc.):

```bash
export LIGHTNING_API_KEY="your_api_key_here"
```

Or set it temporarily:

```bash
export LIGHTNING_API_KEY="your_api_key_here"
```

### 3. Reload Pi (if already running)

If pi is already running, reload extensions:

```
/reload
```

## Usage

### Select a Lightning AI Model

```bash
# Open model selector
/model

# Or use keyboard shortcut
Ctrl+L
```

Then search for "Lightning" or specific model names like "Llama", "Qwen", etc.

### CLI Usage

```bash
pi --provider lightning --model "meta-llama/Llama-3.1-70B-Instruct"
```

### List Available Models

```bash
pi --list-models lightning
```

## Available Models

- **Llama 3.1**: 8B, 70B, 405B (128K context)
- **Llama 3.3**: 70B (128K context)
- **Mistral**: 7B, Mixtral 8x7B (32K context)
- **Qwen**: 2.5 Coder 32B, 2.5 72B (32-128K context)
- **DeepSeek**: V3 (64K context)

## Examples

```bash
# Use Qwen Coder for coding tasks
pi --provider lightning --model "Qwen/Qwen2.5-Coder-32B-Instruct" \
   "Create a REST API in Python"

# Use Llama for general tasks
pi --provider lightning --model "meta-llama/Llama-3.1-70B-Instruct" \
   @src/main.py "Review this code"
```

## Troubleshooting

### Models Not Appearing

1. Make sure `LIGHTNING_API_KEY` is set:
   ```bash
   echo $LIGHTNING_API_KEY
   ```

2. Reload extensions in pi:
   ```
   /reload
   ```

### Dynamic Model Discovery (Alternative)

If you want to fetch models dynamically from the API, replace `lightning-ai-provider.ts` with this version:

```typescript
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

interface LightningModelsResponse {
  data: Array<{ id: string }>;
}

export default async function (pi: ExtensionAPI) {
  const apiKey = process.env.LIGHTNING_API_KEY;
  if (!apiKey) return;

  try {
    const response = await fetch("https://api.lightning.ai/v1/models", {
      headers: { "Authorization": `Bearer ${apiKey}` },
    });
    
    const data = await response.json() as LightningModelsResponse;
    
    // Map API models to pi configs...
    const models = data.data.map(m => ({
      id: m.id,
      name: m.id,
      reasoning: false,
      input: ["text" as const],
      cost: { input: 0.1, output: 0.1, cacheRead: 0, cacheWrite: 0 },
      contextWindow: 32768,
      maxTokens: 4096,
    }));

    pi.registerProvider("lightning", {
      baseUrl: "https://api.lightning.ai/v1",
      apiKey: "LIGHTNING_API_KEY",
      api: "openai-completions",
      models,
    });
  } catch (error) {
    console.error("Failed to load Lightning AI:", error);
  }
}
```

## Resources

- [Lightning AI Docs](https://lightning.ai/docs)
- [Lightning AI Pricing](https://lightning.ai/pricing)
