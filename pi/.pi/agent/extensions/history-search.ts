/**
 * Reverse history search extension (ctrl+r)
 * 
 * Fuzzy search through previous user messages.
 * Uses fzf --filter for ranking (non-interactive).
 * History persists across sessions in ~/.pi/agent/history.jsonl
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Input, Key, matchesKey, truncateToWidth } from "@mariozechner/pi-tui";
import { readFileSync, appendFileSync, mkdirSync } from "node:fs";
import { execSync } from "node:child_process";
import { dirname, join } from "node:path";
import { homedir } from "node:os";

const HISTORY_FILE = join(homedir(), ".pi", "agent", "history.jsonl");
const MAX_HISTORY = 1000;

function loadHistory(): string[] {
	try {
		const content = readFileSync(HISTORY_FILE, "utf-8");
		const lines = content.trim().split("\n").filter(Boolean);
		const results: string[] = [];
		for (const line of lines) {
			try {
				const parsed = JSON.parse(line);
				if (parsed.text) {
					results.push(parsed.text);
				}
			} catch {
				// Skip malformed lines
			}
		}
		return results;
	} catch {
		return [];
	}
}

function appendHistory(text: string): void {
	try {
		mkdirSync(dirname(HISTORY_FILE), { recursive: true });
		appendFileSync(HISTORY_FILE, JSON.stringify({ text, ts: Date.now() }) + "\n");
	} catch {
		// Ignore write errors
	}
}

/**
 * Use fzf --filter for fuzzy matching and ranking.
 * Returns items sorted by relevance (best match first).
 */
function fzfFilter(items: string[], query: string): string[] {
	if (!query.trim()) {
		return items;
	}

	try {
		// Create input with index prefix so we can map back to original (preserving newlines)
		const indexedItems = items.map((item, i) => `${i}\t${item.replace(/\n/g, " ")}`);
		const input = indexedItems.join("\n");

		const result = execSync(`fzf --filter=${JSON.stringify(query)}`, {
			input,
			encoding: "utf-8",
			maxBuffer: 10 * 1024 * 1024,
		});

		// Parse results and map back to original items
		const matchedIndices = result
			.trim()
			.split("\n")
			.filter(Boolean)
			.map((line) => parseInt(line.split("\t")[0], 10))
			.filter((i) => !isNaN(i) && i >= 0 && i < items.length);

		return matchedIndices.map((i) => items[i]);
	} catch {
		// fzf returns exit code 1 when no matches, or if fzf not installed
		// Fall back to simple includes filter
		const lowerQuery = query.toLowerCase();
		return items.filter((item) => item.toLowerCase().includes(lowerQuery));
	}
}

export default function (pi: ExtensionAPI) {
	// Record user messages
	pi.on("message_end", async (event) => {
		if (event.message.role !== "user") return;

		const text = event.message.content
			.filter((c): c is { type: "text"; text: string } => c.type === "text")
			.map((c) => c.text)
			.join("\n")
			.trim();

		if (!text) return;

		// Load current history to check for dupes
		const existing = new Set(loadHistory());
		if (!existing.has(text)) {
			appendHistory(text);
		}
	});

	pi.registerShortcut("ctrl+r", {
		description: "Reverse history search",
		handler: async (ctx) => {
			if (!ctx.hasUI) return;

			const history = loadHistory();
			if (history.length === 0) {
				ctx.ui.notify("No history", "info");
				return;
			}

			// Dedupe and reverse for most recent first (when no query)
			const unique = [...new Set(history)].reverse().slice(0, MAX_HISTORY);

			const result = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
				const searchInput = new Input();
				searchInput.focused = true;

				let selectedIndex = 0;
				let filtered = unique;
				let lastQuery = "";
				let cachedLines: string[] | null = null;

				const updateFilter = () => {
					const query = searchInput.getValue();
					if (query !== lastQuery) {
						lastQuery = query;
						filtered = fzfFilter(unique, query);
						selectedIndex = 0;
						cachedLines = null;
					}
				};

				const formatItem = (text: string, width: number, isSelected: boolean): string => {
					const oneLine = text.replace(/\n/g, " ").trim();
					const prefix = isSelected ? theme.fg("accent", "> ") : "  ";
					const content = isSelected ? theme.fg("accent", oneLine) : oneLine;
					return truncateToWidth(prefix + content, width);
				};

				return {
					render: (width: number) => {
						if (cachedLines) return cachedLines;

						const lines: string[] = [];

						// Top border
						lines.push(theme.fg("accent", "-".repeat(width)));

						// Search input
						const inputLines = searchInput.render(width - 10);
						lines.push(theme.fg("accent", "search: ") + (inputLines[0] || ""));

						// Separator
						lines.push(theme.fg("dim", "-".repeat(width)));

						// Results (max 15) - best match at top
						const maxVisible = 15;
						if (filtered.length === 0) {
							lines.push(theme.fg("warning", "  No matches"));
						} else {
							// Keep selection in view
							let start = 0;
							if (selectedIndex >= maxVisible) {
								start = selectedIndex - maxVisible + 1;
							}
							const end = Math.min(filtered.length, start + maxVisible);

							for (let i = start; i < end; i++) {
								lines.push(formatItem(filtered[i], width, i === selectedIndex));
							}

							// Scroll indicator
							if (filtered.length > maxVisible) {
								const info = `  ${selectedIndex + 1}/${filtered.length}`;
								lines.push(theme.fg("dim", info));
							}
						}

						// Help text
						lines.push(theme.fg("dim", "-".repeat(width)));
						lines.push(theme.fg("dim", "up/down navigate, enter select, esc cancel"));

						// Bottom border
						lines.push(theme.fg("accent", "-".repeat(width)));

						cachedLines = lines;
						return lines;
					},

					invalidate: () => {
						cachedLines = null;
						searchInput.invalidate();
					},

					handleInput: (data: string) => {
						if (matchesKey(data, Key.escape)) {
							done(null);
						} else if (matchesKey(data, Key.enter)) {
							if (filtered.length > 0) {
								done(filtered[selectedIndex]);
							}
						} else if (matchesKey(data, Key.up)) {
							if (selectedIndex > 0) {
								selectedIndex--;
								cachedLines = null;
							}
						} else if (matchesKey(data, Key.down)) {
							if (selectedIndex < filtered.length - 1) {
								selectedIndex++;
								cachedLines = null;
							}
						} else {
							// Pass to search input
							searchInput.handleInput(data);
							updateFilter();
						}
						tui.requestRender();
					},
				};
			});

			if (result) {
				ctx.ui.setEditorText(result);
			}
		},
	});
}
