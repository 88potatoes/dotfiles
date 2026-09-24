import { readFile, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	pi.registerCommand("figma-auth", {
		description: "Set or update your Figma Personal Access Token in ~/.pi/agent/auth.json",
		handler: async (args, ctx) => {
			let token = args.trim();
			if (!token) {
				if (!ctx.hasUI) {
					ctx.ui?.notify("Usage: /figma-auth <figma-personal-access-token>", "error");
					return;
				}
				const input = await ctx.ui.input("Enter your Figma Personal Access Token:");
				if (!input || !input.trim()) {
					ctx.ui.notify("Figma authentication cancelled.", "info");
					return;
				}
				token = input.trim();
			}

			const authPath = join(homedir(), ".pi", "agent", "auth.json");
			let auth: Record<string, unknown> = {};
			try {
				const contents = await readFile(authPath, "utf8");
				auth = JSON.parse(contents);
			} catch (error) {
				if ((error as NodeJS.ErrnoException).code !== "ENOENT") {
					ctx.ui.notify(`Failed to read ${authPath}: ${String(error)}`, "error");
					return;
				}
			}

			auth.figma = { type: "api_key", key: token };
			try {
				await writeFile(authPath, JSON.stringify(auth, null, 2) + "\n", { mode: 0o600 });
				ctx.ui.notify("Figma token saved to ~/.pi/agent/auth.json", "success");
			} catch (error) {
				ctx.ui.notify(`Failed to save to ${authPath}: ${String(error)}`, "error");
			}
		},
	});
}
