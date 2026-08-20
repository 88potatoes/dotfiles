import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { resolve, relative, normalize } from "node:path";
import { realpathSync } from "node:fs";
import { homedir } from "node:os";

export default function (pi: ExtensionAPI) {
	const userHome = homedir();
	const protectedFiles = [
		resolve(userHome, ".pi/agent/auth.json"),
	];

	function isProtectedLocation(absPath: string): boolean {
		const norm = normalize(absPath);
		if (norm === userHome || norm === "/" || norm === "") {
			return true;
		}
		const sensitivePrefixes = [
			resolve(userHome, "dotfiles"),
			resolve(userHome, ".pi"),
			resolve(userHome, ".work-contexts"),
			resolve(userHome, ".ssh"),
			resolve(userHome, ".aws"),
			resolve(userHome, ".gnupg"),
			resolve(userHome, ".config"),
			"/etc",
			"/usr",
			"/bin",
			"/sbin",
			"/var",
			"/System",
			"/Library",
		];
		return sensitivePrefixes.some((p) => norm === p || norm.startsWith(p + "/"));
	}

	function resolvePath(p: string, cwd: string): string {
		if (p === "~") return userHome;
		if (p.startsWith("~/") || p.startsWith("~\\")) {
			return resolve(userHome, p.slice(2));
		}
		return resolve(cwd, p);
	}

	function isRmSafe(command: string, cwd: string): boolean {
		// If cwd itself is in a protected location (dotfiles, work-contexts, home, etc.),
		// always require confirmation.
		if (isProtectedLocation(cwd)) {
			return false;
		}

		const segments = command.split(/[\n;&|]+/);
		let foundRm = false;

		for (const rawSegment of segments) {
			const segment = rawSegment.trim();
			if (!segment) continue;

			const rmMatch = segment.match(/(?:^|\s)(?:(?:\/[\w.-]+)*\/)?rm(?:\.exe)?(?:\s+|$)/i);
			if (!rmMatch) {
				continue;
			}

			foundRm = true;
			const rmIndex = segment.indexOf(rmMatch[0]) + rmMatch[0].length;
			const argsStr = segment.slice(rmIndex).trim();

			if (!argsStr) {
				return false;
			}

			const tokens: string[] = [];
			const tokenRegex = /[^\s"']+|"([^"]*)"|'([^']*)'/g;
			let match: RegExpExecArray | null;
			while ((match = tokenRegex.exec(argsStr)) !== null) {
				const val = match[1] ?? match[2] ?? match[0];
				tokens.push(val);
			}

			if (tokens.length === 0) {
				return false;
			}

			const targetPaths: string[] = [];
			for (const token of tokens) {
				if (token.startsWith("-")) {
					continue;
				}
				// Subshells, variables, or wildcards need user review
				if (/[\$`\(\)\*\?]/.test(token)) {
					return false;
				}
				targetPaths.push(token);
			}

			if (targetPaths.length === 0) {
				return false;
			}

			for (const target of targetPaths) {
				if (!target || target === "." || target === "./" || target === ".." || target === "../") {
					return false;
				}

				const resolved = resolvePath(target, cwd);
				if (resolved === cwd) {
					return false;
				}

				const rel = relative(cwd, resolved);
				if (rel.startsWith("..") || rel === "" || resolve(cwd, rel) !== resolved) {
					return false;
				}

				if (rel === ".git" || rel.startsWith(".git/") || rel.startsWith(".git\\")) {
					return false;
				}

				if (isProtectedLocation(resolved)) {
					return false;
				}
			}
		}

		return foundRm;
	}

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
		const alwaysDangerous = [/\bsudo\b/i, /\b(chmod|chown)\b.*777/i];
		let isDangerous = alwaysDangerous.some((p) => p.test(command));

		// If rm is used with recursive/force options, check if target files are within cwd sandbox
		if (!isDangerous && /\brm\s+(-rf?|--recursive|-r|-R)\b/i.test(command)) {
			if (!isRmSafe(command, ctx.cwd)) {
				isDangerous = true;
			}
		}

		if (isDangerous) {
			if (!ctx.hasUI) {
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
