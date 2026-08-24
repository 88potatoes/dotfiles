import type { Api, Model } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { decodeKittyPrintable, fuzzyFilter, getKeybindings } from "@earendil-works/pi-tui";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";

type AliasName = "strong" | "weak";

type AliasTarget = {
	provider: string;
	modelId: string;
};

type AliasConfig = Partial<Record<AliasName, AliasTarget>>;

const CONFIG_PATH = join(homedir(), ".local", "state", "pi", "model-aliases.json");
const ALIASES: AliasName[] = ["strong", "weak"];

function loadConfig(): AliasConfig {
	if (!existsSync(CONFIG_PATH)) return {};
	try {
		return JSON.parse(readFileSync(CONFIG_PATH, "utf-8")) as AliasConfig;
	} catch {
		return {};
	}
}

function saveConfig(config: AliasConfig): void {
	mkdirSync(dirname(CONFIG_PATH), { recursive: true });
	writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2) + "\n", "utf-8");
}

function modelKey(model: Model<Api>): string {
	return `${model.provider}/${model.id}`;
}

function modelLabel(model: Model<Api>): string {
	const provider = model.provider;
	const name = model.name && model.name !== model.id ? ` — ${model.name}` : "";
	return `${provider}/${model.id}${name}`;
}

function findModel(ctx: ExtensionCommandContext, target: AliasTarget): Model<Api> | undefined {
	return ctx.modelRegistry.find(target.provider, target.modelId);
}

function parseTarget(value: string): AliasTarget | undefined {
	const trimmed = value.trim();
	const slash = trimmed.indexOf("/");
	if (slash <= 0 || slash === trimmed.length - 1) return undefined;
	return {
		provider: trimmed.slice(0, slash),
		modelId: trimmed.slice(slash + 1),
	};
}

type ModelChoice = {
	value: string;
	model: Model<Api>;
	label: string;
	search: string;
	details: string;
};

function fit(text: string, width: number): string {
	if (width <= 0) return "";
	if (text.length <= width) return text;
	if (width <= 1) return "…";
	return `${text.slice(0, width - 1)}…`;
}

async function chooseModel(ctx: ExtensionCommandContext, alias: AliasName): Promise<AliasTarget | undefined> {
	const available = ctx.modelRegistry.getAvailable().sort((a, b) => modelLabel(a).localeCompare(modelLabel(b)));
	if (available.length === 0) {
		ctx.ui.notify("No authenticated models available. Run /login or configure API keys first.", "error");
		return undefined;
	}

	const choices: ModelChoice[] = available.map((model) => ({
		value: modelKey(model),
		model,
		label: modelLabel(model),
		search: `${model.provider} ${model.id} ${model.name ?? ""}`,
		details: `${model.contextWindow.toLocaleString()} ctx • ${model.maxTokens.toLocaleString()} max`,
	}));

	if (ctx.mode !== "tui") {
		const choice = await ctx.ui.select(`Pick model for /${alias}`, choices.map((item) => item.label));
		if (!choice) return undefined;
		const model = choices.find((item) => item.label === choice)?.model;
		return model ? { provider: model.provider, modelId: model.id } : undefined;
	}

	const choice = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
		let filter = "";
		let selectedIndex = 0;
		const maxVisible = Math.min(choices.length, 12);

		const filtered = () => fuzzyFilter(choices, filter, (choice) => choice.search);

		const clampSelection = (items: ModelChoice[]) => {
			selectedIndex = Math.max(0, Math.min(selectedIndex, Math.max(0, items.length - 1)));
		};

		const render = (width: number) => {
			const items = filtered();
			clampSelection(items);
			const lines: string[] = [];
			lines.push(theme.fg("accent", theme.bold(`Pick model for /${alias}`)));
			lines.push(theme.fg("muted", `Filter: ${filter || "(type to search)"}`));

			if (items.length === 0) {
				lines.push(theme.fg("warning", "  No matching models"));
				lines.push(theme.fg("dim", "type to fuzzy filter • backspace delete • esc cancel"));
				return lines;
			}

			const startIndex = Math.max(0, Math.min(selectedIndex - Math.floor(maxVisible / 2), items.length - maxVisible));
			const endIndex = Math.min(startIndex + maxVisible, items.length);
			for (let i = startIndex; i < endIndex; i++) {
				const item = items[i];
				if (!item) continue;
				const selected = i === selectedIndex;
				const prefix = selected ? "→ " : "  ";
				const modelLine = `${prefix}${item.value}`;
				const nameLine = `    ${item.model.name ?? item.model.id} — ${item.details}`;
				lines.push(selected ? theme.fg("accent", fit(modelLine, width)) : fit(modelLine, width));
				lines.push(theme.fg("muted", fit(nameLine, width)));
			}

			if (items.length > maxVisible) {
				lines.push(theme.fg("dim", `  (${selectedIndex + 1}/${items.length})`));
			}
			lines.push(theme.fg("dim", "type to fuzzy filter • ↑↓ navigate • enter select • backspace delete • esc cancel"));
			return lines;
		};

		const handleInput = (data: string) => {
			const kb = getKeybindings();
			const items = filtered();
			if (kb.matches(data, "tui.select.up")) {
				selectedIndex = selectedIndex === 0 ? Math.max(0, items.length - 1) : selectedIndex - 1;
			} else if (kb.matches(data, "tui.select.down")) {
				selectedIndex = selectedIndex === items.length - 1 ? 0 : selectedIndex + 1;
			} else if (kb.matches(data, "tui.select.confirm")) {
				const selected = items[selectedIndex];
				if (selected) done(selected.value);
			} else if (kb.matches(data, "tui.select.cancel")) {
				done(null);
			} else if (data === "\u007f" || data === "\b" || data === "\x1b[3~") {
				filter = filter.slice(0, -1);
				selectedIndex = 0;
			} else if (data === "\u0015") {
				filter = "";
				selectedIndex = 0;
			} else {
				const printable = decodeKittyPrintable(data) ?? (data.length === 1 && data >= " " ? data : undefined);
				if (printable) {
					filter += printable;
					selectedIndex = 0;
				}
			}
			tui.requestRender();
		};

		return { render, invalidate() {}, handleInput };
	});

	if (!choice) return undefined;
	return parseTarget(choice);
}

async function configureAlias(
	ctx: ExtensionCommandContext,
	alias: AliasName,
	explicitTarget?: AliasTarget,
): Promise<AliasTarget | undefined> {
	const target = explicitTarget ?? (await chooseModel(ctx, alias));
	if (!target) return undefined;

	const model = findModel(ctx, target);
	if (!model) {
		ctx.ui.notify(`Model not found: ${target.provider}/${target.modelId}`, "error");
		return undefined;
	}

	const config = loadConfig();
	config[alias] = target;
	saveConfig(config);
	ctx.ui.notify(`/${alias} → ${modelKey(model)} saved to ${CONFIG_PATH}`, "success");
	return target;
}

async function switchToAlias(pi: ExtensionAPI, ctx: ExtensionCommandContext, alias: AliasName): Promise<void> {
	const config = loadConfig();
	let target = config[alias];

	if (!target) {
		ctx.ui.notify(`No /${alias} model set yet. Pick one now.`, "info");
		target = await configureAlias(ctx, alias);
		if (!target) return;
	}

	let model = findModel(ctx, target);
	if (!model) {
		ctx.ui.notify(`/${alias} model no longer exists: ${target.provider}/${target.modelId}. Pick a new one.`, "warning");
		target = await configureAlias(ctx, alias);
		if (!target) return;
		model = findModel(ctx, target);
		if (!model) return;
	}

	const success = await pi.setModel(model);
	if (!success) {
		ctx.ui.notify(`No auth available for ${modelKey(model)}. Run /login or pick another model.`, "error");
		return;
	}
	ctx.ui.notify(`Switched to /${alias}: ${modelKey(model)}`, "success");
}

function parseAlias(value: string): AliasName | undefined {
	return ALIASES.find((alias) => alias === value.trim());
}

export default function modelAliases(pi: ExtensionAPI) {
	for (const alias of ALIASES) {
		pi.registerCommand(alias, {
			description: `Switch to configured ${alias} model`,
			handler: async (_args, ctx) => {
				await switchToAlias(pi, ctx, alias);
			},
		});
	}

	pi.registerCommand("model-configure", {
		description: "Configure /strong or /weak model alias",
		handler: async (args, ctx) => {
			const parts = args.trim().split(/\s+/).filter(Boolean);
			let alias = parts[0] ? parseAlias(parts[0]) : undefined;
			if (parts[0] && !alias) {
				ctx.ui.notify("Usage: /model-configure [strong|weak] [provider/model-id]", "error");
				return;
			}

			if (!alias) {
				const choice = await ctx.ui.select("Configure which model alias?", [...ALIASES]);
				alias = parseAlias(choice ?? "");
				if (!alias) return;
			}

			const explicitTarget = parts[1] ? parseTarget(parts.slice(1).join(" ")) : undefined;
			if (parts[1] && !explicitTarget) {
				ctx.ui.notify("Model must be provider/model-id, e.g. anthropic/claude-sonnet-4-5", "error");
				return;
			}

			await configureAlias(ctx, alias, explicitTarget);
		},
		getArgumentCompletions: (prefix) => {
			const items = ALIASES.map((alias) => ({ value: alias, label: alias }));
			const filtered = items.filter((item) => item.value.startsWith(prefix));
			return filtered.length > 0 ? filtered : null;
		},
	});
}
