import type { Api, Model } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { decodeKittyPrintable, fuzzyFilter, getKeybindings } from "@earendil-works/pi-tui";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

// Global pi settings. Write via the symlink target path so we never clobber
// the stow symlink itself; this file is the same one /model persists to.
const SETTINGS_PATH = join(homedir(), ".pi", "agent", "settings.json");

type Settings = Record<string, unknown> & {
	defaultProvider?: string;
	defaultModel?: string;
};

function loadSettings(): Settings {
	if (!existsSync(SETTINGS_PATH)) return {};
	try {
		return JSON.parse(readFileSync(SETTINGS_PATH, "utf-8")) as Settings;
	} catch {
		return {};
	}
}

function saveSettings(settings: Settings): void {
	writeFileSync(SETTINGS_PATH, JSON.stringify(settings, null, 2) + "\n", "utf-8");
}

type PinnedDefault = { provider: string; model: string } | undefined;

function readPinnedDefault(): PinnedDefault {
	const settings = loadSettings();
	if (!settings.defaultProvider || !settings.defaultModel) return undefined;
	return { provider: settings.defaultProvider, model: settings.defaultModel };
}

function modelKey(model: Model<Api>): string {
	return `${model.provider}/${model.id}`;
}

function modelLabel(model: Model<Api>): string {
	const name = model.name && model.name !== model.id ? ` — ${model.name}` : "";
	return `${model.provider}/${model.id}${name}`;
}

type ModelChoice = {
	value: string;
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

async function chooseModel(ctx: ExtensionCommandContext): Promise<Model<Api> | undefined> {
	const available = ctx.modelRegistry.getAvailable().sort((a, b) => modelLabel(a).localeCompare(modelLabel(b)));
	if (available.length === 0) {
		ctx.ui.notify("No authenticated models available. Run /login or configure API keys first.", "error");
		return undefined;
	}

	const choices: ModelChoice[] = available.map((model) => ({
		value: modelKey(model),
		label: modelLabel(model),
		search: `${model.provider} ${model.id} ${model.name ?? ""}`,
		details: `${model.contextWindow.toLocaleString()} ctx • ${model.maxTokens.toLocaleString()} max`,
	}));

	if (ctx.mode !== "tui") {
		const choice = await ctx.ui.select("Pick new default model:", choices.map((item) => item.label));
		if (!choice) return undefined;
		return available.find((model) => modelLabel(model) === choice);
	}

	const current = loadSettings();
	const currentKey = current.defaultProvider && current.defaultModel ? `${current.defaultProvider}/${current.defaultModel}` : undefined;
	let selectedIndex = Math.max(0, choices.findIndex((choice) => choice.value === currentKey));

	const choice = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
		let filter = "";
		const maxVisible = Math.min(choices.length, 12);

		const filtered = () => fuzzyFilter(choices, filter, (choice) => choice.search);

		const clampSelection = (items: ModelChoice[]) => {
			selectedIndex = Math.max(0, Math.min(selectedIndex, Math.max(0, items.length - 1)));
		};

		const render = (width: number) => {
			const items = filtered();
			clampSelection(items);
			const lines: string[] = [];
			lines.push(theme.fg("accent", theme.bold("Pick new default model")));
			if (currentKey) lines.push(theme.fg("muted", `Current default: ${currentKey}`));
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
				const nameLine = `    ${item.details}`;
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
			} else if (data === "" || data === "\b" || data === "\x1b[3~") {
				filter = filter.slice(0, -1);
				selectedIndex = 0;
			} else if (data === "") {
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
	return available.find((model) => modelKey(model) === choice);
}

function parseTarget(value: string): { provider: string; modelId: string } | undefined {
	const trimmed = value.trim();
	const slash = trimmed.indexOf("/");
	if (slash <= 0 || slash === trimmed.length - 1) return undefined;
	return { provider: trimmed.slice(0, slash), modelId: trimmed.slice(slash + 1) };
}

export default function defaultModel(pi: ExtensionAPI) {
	// pi's built-in setModel/cycleModel always persists the selected model as
	// the default (settings.json). The user wants /model to be session-only,
	// so pin the default at session start and restore it after every switch.
	// setDefaultModelAndProvider runs (and clears its modified-fields) before
	// model_select fires, so a short delay lets the queued write land first.
	let pinned = readPinnedDefault();

	pi.on("session_start", async () => {
		pinned = readPinnedDefault();
	});

	pi.on("model_select", async () => {
		if (!pinned) return;
		await new Promise((resolve) => setTimeout(resolve, 250));
		const settings = loadSettings();
		if (settings.defaultProvider === pinned.provider && settings.defaultModel === pinned.model) return;
		settings.defaultProvider = pinned.provider;
		settings.defaultModel = pinned.model;
		saveSettings(settings);
	});

	pi.registerCommand("default-model", {
		description: "Set the default model for new sessions (writes ~/.pi/agent/settings.json; does not change the current session)",
		handler: async (args, ctx) => {
			let model: Model<Api> | undefined;

			const explicit = args.trim() ? parseTarget(args) : undefined;
			if (args.trim() && !explicit) {
				ctx.ui.notify("Usage: /default-model [provider/model-id]", "error");
				return;
			}
			if (explicit) {
				model = ctx.modelRegistry.find(explicit.provider, explicit.modelId);
				if (!model) {
					ctx.ui.notify(`Model not found: ${explicit.provider}/${explicit.modelId}`, "error");
					return;
				}
			} else {
				model = await chooseModel(ctx);
				if (!model) return;
			}

			const settings = loadSettings();
			settings.defaultProvider = model.provider;
			settings.defaultModel = model.id;
			saveSettings(settings);
			pinned = { provider: model.provider, model: model.id };
			ctx.ui.notify(`Default model set to ${modelKey(model)} (applies to new sessions; current session unchanged)`, "success");
		},
	});
}
