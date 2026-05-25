import type { ExtensionAPI, ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { matchesKey, truncateToWidth } from "@earendil-works/pi-tui";

type Config = {
  enabled: boolean;
  runAfterChanges: boolean;
  commands: string[];
};

type Store = Record<string, Config>;

type UiAction =
  | { type: "add" }
  | { type: "remove"; index: number }
  | { type: "toggleEnabled" }
  | { type: "toggleRunAfterChanges" }
  | { type: "clear" }
  | { type: "close" };

const STORE_PATH = join(homedir(), ".pi", "agent", "test-after-changes.json");
const DEFAULT_CONFIG: Config = {
  enabled: true,
  runAfterChanges: true,
  commands: [],
};

const cloneConfig = (config: Config): Config => ({
  enabled: config.enabled,
  runAfterChanges: config.runAfterChanges,
  commands: [...config.commands],
});

const readStore = (): Store => {
  if (!existsSync(STORE_PATH)) return {};

  try {
    return JSON.parse(readFileSync(STORE_PATH, "utf8")) as Store;
  } catch {
    return {};
  }
};

const writeStore = (store: Store) => {
  mkdirSync(dirname(STORE_PATH), { recursive: true });
  writeFileSync(STORE_PATH, `${JSON.stringify(store, null, 2)}\n`);
};

const getConfig = (cwd: string): Config => {
  const store = readStore();
  return cloneConfig(store[cwd] ?? DEFAULT_CONFIG);
};

const setConfig = (cwd: string, config: Config) => {
  const store = readStore();
  store[cwd] = cloneConfig(config);
  writeStore(store);
};

const formatCommands = (commands: string[]) => {
  if (!commands.length) return "No test commands configured.";
  return commands.map((command, index) => `${index + 1}. ${command}`).join("\n");
};

const updateWidget = (ctx: ExtensionContext) => {
  if (!ctx.hasUI) return;

  const config = getConfig(ctx.cwd);
  if (!config.enabled || !config.commands.length) {
    ctx.ui.setWidget("test-after-changes", undefined);
    ctx.ui.setStatus("test-after-changes", undefined);
    return;
  }

  ctx.ui.setStatus("test-after-changes", `tests:${config.commands.length}`);
  ctx.ui.setWidget(
    "test-after-changes",
    [
      ctx.ui.theme.fg("accent", "Test after changes") +
        ctx.ui.theme.fg("dim", ` (${config.commands.length}) /test-after-changes`),
      ...config.commands.slice(0, 3).map((command, index) =>
        ctx.ui.theme.fg("dim", `  ${index + 1}. ${command}`),
      ),
      ...(config.commands.length > 3 ? [ctx.ui.theme.fg("dim", `  ... ${config.commands.length - 3} more`)] : []),
    ],
    { placement: "belowEditor" },
  );
};

class TestAfterChangesPanel {
  private selectedIndex = 0;
  private cachedWidth?: number;
  private cachedLines?: string[];

  constructor(
    private config: Config,
    private theme: Theme,
    private done: (action: UiAction) => void,
  ) {}

  handleInput(data: string): void {
    if (matchesKey(data, "escape") || matchesKey(data, "ctrl+c")) {
      this.done({ type: "close" });
      return;
    }

    if (matchesKey(data, "up")) {
      this.selectedIndex = Math.max(0, this.selectedIndex - 1);
      this.invalidate();
      return;
    }

    if (matchesKey(data, "down")) {
      this.selectedIndex = Math.min(Math.max(0, this.config.commands.length - 1), this.selectedIndex + 1);
      this.invalidate();
      return;
    }

    if (data === "a") {
      this.done({ type: "add" });
      return;
    }

    if (data === "d") {
      this.done({ type: "remove", index: this.selectedIndex });
      return;
    }

    if (data === "e") {
      this.done({ type: "toggleEnabled" });
      return;
    }

    if (data === "r") {
      this.done({ type: "toggleRunAfterChanges" });
      return;
    }

    if (data === "c") {
      this.done({ type: "clear" });
    }
  }

  render(width: number): string[] {
    if (this.cachedLines && this.cachedWidth === width) return this.cachedLines;

    const th = this.theme;
    const lines: string[] = [];
    lines.push(th.fg("accent", "─".repeat(width)));
    lines.push(truncateToWidth(th.fg("accent", " Test after changes ") + th.fg("dim", "project test watchlist"), width));
    lines.push(th.fg("borderMuted", "─".repeat(width)));
    lines.push(truncateToWidth(`  enabled: ${this.config.enabled ? th.fg("success", "yes") : th.fg("warning", "no")}`, width));
    lines.push(
      truncateToWidth(
        `  run after changes: ${this.config.runAfterChanges ? th.fg("success", "yes") : th.fg("warning", "no")}`,
        width,
      ),
    );
    lines.push("");

    if (!this.config.commands.length) {
      lines.push(truncateToWidth(`  ${th.fg("dim", "No commands. Press a to add one.")}`, width));
    } else {
      this.config.commands.forEach((command, index) => {
        const selected = index === this.selectedIndex;
        const prefix = selected ? th.fg("accent", ">") : " ";
        const text = selected ? th.fg("accent", command) : th.fg("text", command);
        lines.push(truncateToWidth(`${prefix} ${index + 1}. ${text}`, width));
      });
    }

    lines.push("");
    lines.push(th.fg("borderMuted", "─".repeat(width)));
    lines.push(
      truncateToWidth(
        th.fg("dim", "a add • d delete selected • e enable/disable • r auto-run toggle • c clear • esc close"),
        width,
      ),
    );
    lines.push(th.fg("accent", "─".repeat(width)));

    this.cachedWidth = width;
    this.cachedLines = lines;
    return lines;
  }

  invalidate(): void {
    this.cachedWidth = undefined;
    this.cachedLines = undefined;
  }
}

const openPanel = async (ctx: ExtensionContext) => {
  if (!ctx.hasUI) {
    ctx.ui.notify("/test-after-changes requires interactive mode", "error");
    return;
  }

  let keepOpen = true;
  while (keepOpen) {
    const config = getConfig(ctx.cwd);
    const action = await ctx.ui.custom<UiAction>((_tui, theme, _kb, done) => {
      return new TestAfterChangesPanel(config, theme, done);
    });

    if (!action || action.type === "close") break;

    const nextConfig = getConfig(ctx.cwd);
    switch (action.type) {
      case "add": {
        const command = await ctx.ui.input("Test command to run after changes", "pnpm test --testPathPattern=...");
        if (command?.trim()) {
          nextConfig.commands.push(command.trim());
          setConfig(ctx.cwd, nextConfig);
          ctx.ui.notify("Added test command", "info");
        }
        break;
      }
      case "remove": {
        if (nextConfig.commands[action.index]) {
          nextConfig.commands.splice(action.index, 1);
          setConfig(ctx.cwd, nextConfig);
          ctx.ui.notify("Removed test command", "info");
        }
        break;
      }
      case "toggleEnabled": {
        nextConfig.enabled = !nextConfig.enabled;
        setConfig(ctx.cwd, nextConfig);
        break;
      }
      case "toggleRunAfterChanges": {
        nextConfig.runAfterChanges = !nextConfig.runAfterChanges;
        setConfig(ctx.cwd, nextConfig);
        break;
      }
      case "clear": {
        const ok = await ctx.ui.confirm("Clear test commands?", "Remove all configured test-after-changes commands for this project?");
        if (ok) {
          nextConfig.commands = [];
          setConfig(ctx.cwd, nextConfig);
          ctx.ui.notify("Cleared test commands", "info");
        }
        break;
      }
      case "close": {
        keepOpen = false;
        break;
      }
    }

    updateWidget(ctx);
  }
};

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => updateWidget(ctx));
  pi.on("session_tree", async (_event, ctx) => updateWidget(ctx));

  pi.on("before_agent_start", async (event, ctx) => {
    const config = getConfig(ctx.cwd);
    const baseInstruction = `

## Test After Changes Extension

If the user asks to add, remove, list, enable, disable, or remember tests to run after changes, use the test_after_changes_config tool. If active test commands are configured and you make code/file changes, run the configured command(s) before your final response.`;

    if (!config.enabled || !config.runAfterChanges || !config.commands.length) {
      return { systemPrompt: event.systemPrompt + baseInstruction };
    }

    return {
      systemPrompt:
        event.systemPrompt +
        baseInstruction +
        `

Active test-after-changes commands for this project:
${formatCommands(config.commands)}

After making code/file changes in this turn, run every command above exactly with the bash tool before the final response. If a command fails and the failure is caused by your changes, fix it and rerun the same command. If you make no code/file changes, say the commands were not run unless the user explicitly asked to run them anyway.`,
    };
  });

  pi.registerTool({
    name: "test_after_changes_config",
    label: "Test After Changes Config",
    description:
      "Manage project-scoped test commands that should be run after code/file changes. Use when the user asks to add, remove, list, enable, disable, or remember tests to run after changes.",
    parameters: Type.Object({
      action: Type.Union([
        Type.Literal("list"),
        Type.Literal("add"),
        Type.Literal("remove"),
        Type.Literal("clear"),
        Type.Literal("enable"),
        Type.Literal("disable"),
        Type.Literal("set_run_after_changes"),
      ]),
      command: Type.Optional(Type.String({ description: "Command to add" })),
      index: Type.Optional(Type.Number({ description: "1-based command index to remove" })),
      runAfterChanges: Type.Optional(Type.Boolean({ description: "Whether commands should run after changes" })),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const config = getConfig(ctx.cwd);

      switch (params.action) {
        case "add": {
          const command = params.command?.trim();
          if (!command) {
            return { content: [{ type: "text", text: "command is required" }], details: { config } };
          }
          if (!config.commands.includes(command)) config.commands.push(command);
          setConfig(ctx.cwd, config);
          updateWidget(ctx);
          return { content: [{ type: "text", text: `Added: ${command}` }], details: { config } };
        }
        case "remove": {
          const index = params.index ?? 0;
          if (index < 1 || index > config.commands.length) {
            return { content: [{ type: "text", text: `Invalid index.\n${formatCommands(config.commands)}` }], details: { config } };
          }
          const [removed] = config.commands.splice(index - 1, 1);
          setConfig(ctx.cwd, config);
          updateWidget(ctx);
          return { content: [{ type: "text", text: `Removed: ${removed}` }], details: { config } };
        }
        case "clear":
          config.commands = [];
          setConfig(ctx.cwd, config);
          updateWidget(ctx);
          return { content: [{ type: "text", text: "Cleared test-after-changes commands" }], details: { config } };
        case "enable":
          config.enabled = true;
          setConfig(ctx.cwd, config);
          updateWidget(ctx);
          return { content: [{ type: "text", text: "Enabled test-after-changes" }], details: { config } };
        case "disable":
          config.enabled = false;
          setConfig(ctx.cwd, config);
          updateWidget(ctx);
          return { content: [{ type: "text", text: "Disabled test-after-changes" }], details: { config } };
        case "set_run_after_changes":
          config.runAfterChanges = params.runAfterChanges ?? true;
          setConfig(ctx.cwd, config);
          updateWidget(ctx);
          return {
            content: [{ type: "text", text: `runAfterChanges=${config.runAfterChanges}` }],
            details: { config },
          };
        case "list":
        default:
          return {
            content: [
              {
                type: "text",
                text: `enabled=${config.enabled}\nrunAfterChanges=${config.runAfterChanges}\n${formatCommands(config.commands)}`,
              },
            ],
            details: { config },
          };
      }
    },
  });

  pi.registerCommand("test-after-changes", {
    description: "Manage project-scoped test commands to run after code changes",
    handler: async (args, ctx) => {
      const [action, ...rest] = args.trim().split(/\s+/).filter(Boolean);
      const config = getConfig(ctx.cwd);

      if (!action) {
        await openPanel(ctx);
        return;
      }

      switch (action) {
        case "add": {
          const command = rest.join(" ").trim();
          if (!command) {
            ctx.ui.notify("Usage: /test-after-changes add <command>", "error");
            return;
          }
          if (!config.commands.includes(command)) config.commands.push(command);
          setConfig(ctx.cwd, config);
          updateWidget(ctx);
          ctx.ui.notify(`Added: ${command}`, "info");
          return;
        }
        case "remove": {
          const index = Number(rest[0]);
          if (!Number.isInteger(index) || index < 1 || index > config.commands.length) {
            ctx.ui.notify("Usage: /test-after-changes remove <number>", "error");
            return;
          }
          const [removed] = config.commands.splice(index - 1, 1);
          setConfig(ctx.cwd, config);
          updateWidget(ctx);
          ctx.ui.notify(`Removed: ${removed}`, "info");
          return;
        }
        case "clear":
          config.commands = [];
          setConfig(ctx.cwd, config);
          updateWidget(ctx);
          ctx.ui.notify("Cleared test commands", "info");
          return;
        case "on":
        case "enable":
          config.enabled = true;
          setConfig(ctx.cwd, config);
          updateWidget(ctx);
          ctx.ui.notify("Enabled test-after-changes", "info");
          return;
        case "off":
        case "disable":
          config.enabled = false;
          setConfig(ctx.cwd, config);
          updateWidget(ctx);
          ctx.ui.notify("Disabled test-after-changes", "info");
          return;
        case "list":
          ctx.ui.notify(`Test-after-changes\n${formatCommands(config.commands)}`, "info");
          return;
        default:
          ctx.ui.notify("Usage: /test-after-changes [add|remove|clear|on|off|list]", "error");
      }
    },
  });

  pi.registerShortcut("ctrl+t", {
    description: "Open test-after-changes panel",
    handler: async (ctx) => openPanel(ctx),
  });
}
