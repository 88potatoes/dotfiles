/**
 * Sandbox Directory Extension (Advanced)
 *
 * Restricts file modifications to the starting directory with additional features:
 * - Toggle sandbox on/off with /sandbox command
 * - Whitelist specific paths outside the sandbox
 * - Confirmation prompts for borderline cases
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { resolve, relative, join } from "node:path";
import { realpath } from "node:fs/promises";
import { homedir } from "node:os";

export default function (pi: ExtensionAPI) {
	let allowedDirectory: string | null = null;
	let sandboxEnabled = true;
	
	// Whitelist: paths that are always allowed even outside sandbox
	const whitelist = [
		join(homedir(), "dotfiles/pi/.pi"),
	];

	// Capture the starting directory when session starts
	pi.on("session_start", async (event, ctx) => {
		allowedDirectory = ctx.cwd;
		
		if (ctx.hasUI && sandboxEnabled) {
			ctx.ui.notify(`Sandbox active: ${allowedDirectory} (+ dotfiles/pi/.pi whitelist)`, "info");
			updateStatus(ctx);
		}
	});

	// Helper to update status indicator
	function updateStatus(ctx: any) {
		if (!ctx.hasUI) return;
		
		if (sandboxEnabled && allowedDirectory) {
			ctx.ui.setStatus("sandbox", `🔒 Sandbox: ${allowedDirectory} + dotfiles`);
		} else if (!sandboxEnabled) {
			ctx.ui.setStatus("sandbox", `🔓 Sandbox: disabled`);
		} else {
			ctx.ui.setStatus("sandbox", undefined);
		}
	}

	// Register /sandbox command to toggle
	pi.registerCommand("sandbox", {
		description: "Toggle sandbox protection on/off",
		handler: async (args, ctx) => {
			if (args === "on") {
				sandboxEnabled = true;
				ctx.ui.notify("Sandbox protection enabled", "success");
			} else if (args === "off") {
				sandboxEnabled = false;
				ctx.ui.notify("⚠️ Sandbox protection disabled", "warning");
			} else {
				// Toggle
				sandboxEnabled = !sandboxEnabled;
				ctx.ui.notify(
					sandboxEnabled ? "Sandbox protection enabled" : "⚠️ Sandbox protection disabled",
					sandboxEnabled ? "success" : "warning"
				);
			}
			updateStatus(ctx);
		},
	});

	// Register keyboard shortcut to toggle
	pi.registerShortcut("ctrl+shift+s", {
		description: "Toggle sandbox protection",
		handler: async (ctx) => {
			sandboxEnabled = !sandboxEnabled;
			ctx.ui.notify(
				sandboxEnabled ? "🔒 Sandbox enabled" : "🔓 Sandbox disabled",
				sandboxEnabled ? "success" : "warning"
			);
			updateStatus(ctx);
		},
	});

	// Intercept write and edit operations
	pi.on("tool_call", async (event, ctx) => {
		// Only check write and edit operations
		if (event.toolName !== "write" && event.toolName !== "edit") {
			return undefined;
		}

		// Skip if sandbox is disabled
		if (!sandboxEnabled) {
			return undefined;
		}

		// Skip if no allowed directory set
		if (!allowedDirectory) {
			return undefined;
		}

		const targetPath = event.input.path as string;
		
		// Resolve to absolute path
		const absolutePath = resolve(ctx.cwd, targetPath);
		
		try {
			// Try to get the real path (follows symlinks)
			let realPath: string;
			try {
				realPath = await realpath(absolutePath);
			} catch {
				// File doesn't exist yet, use the resolved path
				realPath = absolutePath;
			}

			// Check whitelist
			const isWhitelisted = whitelist.some((allowed) => realPath.startsWith(allowed));
			if (isWhitelisted) {
				return undefined; // Allow whitelisted paths
			}

			// Check if the path is within the allowed directory
			const relativePath = relative(allowedDirectory, realPath);
			const isOutside = relativePath.startsWith("..") || (relativePath === "" && realPath !== allowedDirectory);

			if (isOutside) {
				if (!ctx.hasUI) {
					return {
						block: true,
						reason: `File "${targetPath}" is outside sandbox directory "${allowedDirectory}"`
					};
				}

				// Prompt user for confirmation
				const message = [
					`⚠️ Sandbox violation detected:`,
					``,
					`  Tool: ${event.toolName}`,
					`  Target: ${targetPath}`,
					`  Resolved: ${realPath}`,
					`  Sandbox: ${allowedDirectory}`,
					``,
					`Allow this operation?`,
				].join("\n");

				const choice = await ctx.ui.select(message, ["No (block)", "Yes (allow once)", "Yes and disable sandbox"]);

				if (choice === "No (block)") {
					return {
						block: true,
						reason: `Blocked by user: file outside sandbox directory`
					};
				} else if (choice === "Yes and disable sandbox") {
					sandboxEnabled = false;
					updateStatus(ctx);
					ctx.ui.notify("Sandbox protection disabled", "warning");
					return undefined; // Allow this operation
				}
				// "Yes (allow once)" - return undefined to allow
			}
		} catch (error) {
			// Error resolving path - allow it but log
			if (ctx.hasUI) {
				ctx.ui.notify(`Warning: Could not verify path ${targetPath}: ${error}`, "warning");
			}
		}

		return undefined;
	});

	// Clean up status on shutdown
	pi.on("session_shutdown", async (_event, ctx) => {
		if (ctx.hasUI) {
			ctx.ui.setStatus("sandbox", undefined);
		}
	});
}
