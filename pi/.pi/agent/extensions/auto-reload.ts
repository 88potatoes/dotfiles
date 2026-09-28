/**
 * Auto-reload: watches pi's global agent dirs (extensions, prompts, skills, AGENTS.md)
 * and runs the /reload flow when they change.
 *
 * - Debounced (500ms) so bursts of writes trigger a single reload.
 * - Reload is queued as a follow-up command, so it defers until pi is idle —
 *   changes made mid-turn (e.g. by the agent itself) apply after the turn ends.
 * - Watchers are closed on session_shutdown and recreated on session_start,
 *   so reloads don't stack duplicate watchers.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const DEBOUNCE_MS = 500;

function agentDir(): string {
	return fs.realpathSync(path.join(process.env.HOME ?? "", ".pi", "agent"));
}

export default function (pi: ExtensionAPI) {
	let watchers: fs.FSWatcher[] = [];
	let debounceTimer: ReturnType<typeof setTimeout> | null = null;

	function closeWatchers() {
		for (const watcher of watchers) {
			watcher.close();
		}
		watchers = [];
		if (debounceTimer) {
			clearTimeout(debounceTimer);
			debounceTimer = null;
		}
	}

	// Command entrypoint: only command contexts can call ctx.reload().
	// Treat reload as terminal for this handler.
	pi.registerCommand("auto-reload", {
		description: "Reload extensions, skills, prompts, themes, and context files",
		handler: async (_args, ctx) => {
			await ctx.reload();
			return;
		},
	});

	pi.on("session_start", async () => {
		closeWatchers();

		const base = agentDir();
		const targets = [
			path.join(base, "extensions"),
			path.join(base, "prompts"),
			path.join(base, "skills"),
			path.join(base, "AGENTS.md"),
		].filter((p) => fs.existsSync(p));

		for (const target of targets) {
			try {
				const watcher = fs.watch(target, { recursive: true }, () => {
					if (debounceTimer) clearTimeout(debounceTimer);
					debounceTimer = setTimeout(() => {
						debounceTimer = null;
						// Queue the reload command; "followUp" defers until pi is idle.
						pi.sendUserMessage("/auto-reload", { deliverAs: "followUp" });
					}, DEBOUNCE_MS);
				});
				watchers.push(watcher);
			} catch {
				// Watch setup is best-effort; manual /reload still works.
			}
		}
	});

	pi.on("session_shutdown", async () => {
		closeWatchers();
	});
}
