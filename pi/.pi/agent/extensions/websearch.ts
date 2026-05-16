import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";

const USER_AGENT =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/124.0 Safari/537.36";

type SearchResult = {
  title: string;
  url: string;
  snippet: string;
};

function decodeHtml(value: string): string {
  return value
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&#x2F;/g, "/")
    .replace(/&#x27;/g, "'")
    .replace(/&#(\d+);/g, (_match, code) => String.fromCharCode(Number(code)))
    .replace(/&#x([0-9a-fA-F]+);/g, (_match, code) => String.fromCharCode(parseInt(code, 16)));
}

function stripTags(value: string): string {
  return decodeHtml(value.replace(/<[^>]*>/g, " "))
    .replace(/\s+/g, " ")
    .trim();
}

function unwrapDuckDuckGoUrl(url: string): string {
  const decoded = decodeHtml(url);

  try {
    const parsed = new URL(decoded, "https://duckduckgo.com");
    const uddg = parsed.searchParams.get("uddg");
    if (uddg) return decodeURIComponent(uddg);
    return parsed.href;
  } catch {
    return decoded;
  }
}

function withTimeout(signal: AbortSignal, timeoutMs: number): AbortSignal {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  signal.addEventListener(
    "abort",
    () => {
      clearTimeout(timer);
      controller.abort();
    },
    { once: true },
  );

  controller.signal.addEventListener("abort", () => clearTimeout(timer), { once: true });
  return controller.signal;
}

async function searchDuckDuckGo(query: string, maxResults: number, signal: AbortSignal): Promise<SearchResult[]> {
  const url = `https://html.duckduckgo.com/html/?q=${encodeURIComponent(query)}`;
  const response = await fetch(url, {
    headers: { "user-agent": USER_AGENT, accept: "text/html" },
    signal: withTimeout(signal, 15000),
  });

  if (!response.ok) {
    throw new Error(`DuckDuckGo returned HTTP ${response.status}`);
  }

  const html = await response.text();
  const results: SearchResult[] = [];
  const resultRegex = /<div class="result[\s\S]*?<a[^>]+class="result__a"[^>]+href="([^"]+)"[^>]*>([\s\S]*?)<\/a>[\s\S]*?(?:<a[^>]+class="result__snippet"[^>]*>([\s\S]*?)<\/a>|<div[^>]+class="result__snippet"[^>]*>([\s\S]*?)<\/div>)/g;

  for (const match of html.matchAll(resultRegex)) {
    const title = stripTags(match[2] ?? "");
    const resultUrl = unwrapDuckDuckGoUrl(match[1] ?? "");
    const snippet = stripTags(match[3] ?? match[4] ?? "");

    if (!title || !resultUrl) continue;
    if (results.some((result) => result.url === resultUrl)) continue;

    results.push({ title, url: resultUrl, snippet });
    if (results.length >= maxResults) break;
  }

  return results;
}

function formatResults(query: string, results: SearchResult[]): string {
  if (results.length === 0) {
    return `No web results found for: ${query}`;
  }

  return results
    .map((result, index) => {
      const snippet = result.snippet ? `\n${result.snippet}` : "";
      return `${index + 1}. ${result.title}\n${result.url}${snippet}`;
    })
    .join("\n\n");
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description: "Search the web using DuckDuckGo HTML results. Use for current facts, docs, and URLs.",
    parameters: Type.Object({
      query: Type.String({ description: "Search query" }),
      maxResults: Type.Optional(
        Type.Number({ minimum: 1, maximum: 10, description: "Maximum results to return. Default: 5" }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const query = params.query.trim();
      const maxResults = Math.min(Math.max(Math.floor(params.maxResults ?? 5), 1), 10);

      if (!query) {
        return {
          content: [{ type: "text", text: "query is required" }],
          details: { results: [] },
        };
      }

      const results = await searchDuckDuckGo(query, maxResults, signal);
      return {
        content: [{ type: "text", text: formatResults(query, results) }],
        details: { query, results },
      };
    },
  });
}
