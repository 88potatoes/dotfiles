/**
 * Sandbox Directory Extension
 *
 * Restricts file modifications (write, edit) to only the directory where the session was started.
 * This prevents accidental or malicious modifications to files outside the working directory.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { resolve, relative } from "node:path";
import { realpath } from "node:fs/promises";

export default function (pi: ExtensionAPI) {
	let allowedDirectory: string | null = null;

	// Capture the starting directory when session starts
	pi.on("session_start", async (event, ctx) => {
		allowedDirectory = ctx.cwd;
		
		if (ctx.hasUI) {
			ctx.ui.notify(`Sandbox active: modifications restricted to ${allowedDirectory}`, "info");
			ctx.ui.setStatus("sandbox", `📁 Sandbox: ${allowedDirectory}`);
		}
	});

	// Intercept write and edit operations
	pi.on("tool_call", async (event, ctx) => {
		// Only check write and edit operations
		if (event.toolName !== "write" && event.toolName !== "edit") {
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

			// Check if the path is within the allowed directory
			const relativePath = relative(allowedDirectory, realPath);
			const isOutside = relativePath.startsWith("..") || relativePath === "" && realPath !== allowedDirectory;

			if (isOutside) {
				const message = `Blocked ${event.toolName} to ${targetPath}: outside sandbox directory`;
				
				if (ctx.hasUI) {
					ctx.ui.notify(message, "error");
				}

				return {
					block: true,
					reason: `File "${targetPath}" is outside the allowed directory "${allowedDirectory}"`
				};
			}
		} catch (error) {
			// Error resolving path - allow it (fail open) but log
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
