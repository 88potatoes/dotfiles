import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { access, readFile } from "node:fs/promises";
import { join } from "node:path";
import { homedir } from "node:os";

const workContextDir = join(homedir(), ".work-contexts");
const workContextReadme = join(workContextDir, "README.md");
const workContextSkillsDir = join(workContextDir, "skills");

async function pathExists(path: string): Promise<boolean> {
	try {
		await access(path);
		return true;
	} catch {
		return false;
	}
}

async function readWorkContext(): Promise<string | null> {
	try {
		const content = await readFile(workContextReadme, "utf8");
		const trimmed = content.trim();
		return trimmed.length > 0 ? trimmed : null;
	} catch {
		return null;
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		const hasReadme = await pathExists(workContextReadme);
		if (!ctx.hasUI) return;

		if (!hasReadme) {
			ctx.ui.notify(`Work context missing: ${workContextReadme}`, "warning");
			ctx.ui.setStatus("work-context", "work context: missing");
			return;
		}

		const content = await readWorkContext();
		if (!content) {
			ctx.ui.notify(`Work context empty: ${workContextReadme}`, "warning");
			ctx.ui.setStatus("work-context", "work context: empty");
			return;
		}

		ctx.ui.setStatus("work-context", "work context: loaded");
	});

	pi.on("resources_discover", async () => {
		if (!(await pathExists(workContextSkillsDir))) {
			return undefined;
		}

		return {
			skillPaths: [workContextSkillsDir],
		};
	});

	pi.on("before_agent_start", async (event) => {
		const content = await readWorkContext();
		if (!content) {
			return undefined;
		}

		return {
			systemPrompt: `${event.systemPrompt}\n\n<work_context path="~/.work-contexts/README.md">\n${content}\n</work_context>`,
		};
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		if (ctx.hasUI) {
			ctx.ui.setStatus("work-context", undefined);
		}
	});
}
