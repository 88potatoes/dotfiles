import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { resolve } from "node:path";
import { realpathSync } from "node:fs";

export default function (pi: ExtensionAPI) {
	const dangerousPatterns = [/\brm\s+(-rf?|--recursive)/i, /\bsudo\b/i, /\b(chmod|chown)\b.*777/i];
	const protectedFiles = [
		resolve(process.env.HOME || "", ".pi/agent/auth.json"),
	];

	pi.on("tool_call", async (event, ctx) => {
		// Block reading protected files
		if (event.toolName === "read") {
			const path = event.input.path as string;
			const resolvedPath = resolve(ctx.cwd, path);
			try {
				const realPath = realpathSync(resolvedPath);
				if (protectedFiles.includes(realPath)) {
					return { block: true, reason: "Access to auth.json is blocked" };
				}
			} catch {
				// File doesn't exist, check resolved path directly
				if (protectedFiles.includes(resolvedPath)) {
					return { block: true, reason: "Access to auth.json is blocked" };
				}
			}
			return undefined;
		}

		if (event.toolName !== "bash") return undefined;

		const command = event.input.command as string;
		const isDangerous = dangerousPatterns.some((p) => p.test(command));

		if (isDangerous) {
			if (!ctx.hasUI) {
				// In non-interactive mode, block by default
				return { block: true, reason: "Dangerous command blocked (no UI for confirmation)" };
			}

			const choice = await ctx.ui.select(`⚠️ Dangerous command:\n\n  ${command}\n\nAllow?`, ["Yes", "No"]);

			if (choice !== "Yes") {
				return { block: true, reason: "Blocked by user" };
			}
		}

		return undefined;
	});
}
