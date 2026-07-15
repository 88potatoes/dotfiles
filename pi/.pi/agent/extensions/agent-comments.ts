import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { execSync } from "node:child_process";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("address", {
    description: "Fetch unresolved agent-comments and ask the agent to address them",
    handler: async (args, ctx) => {
      let output: string;
      try {
        output = execSync("agent-comments get", {
          cwd: ctx.cwd,
          encoding: "utf-8",
          timeout: 10000,
        }).trim();
      } catch (e: any) {
        ctx.ui.notify(`Failed to run agent-comments: ${e.message}`, "error");
        return;
      }

      if (!output) {
        ctx.ui.notify("No unresolved comments found", "info");
        return;
      }

      ctx.ui.notify(`Found comments, sending to agent`, "info");

      const instruction = args.trim();
      const prefix = instruction
        ? `${instruction}\n\n`
        : `please address these comments\n\n`;

      // Remind the agent to resolve each comment it addressed via the CLI,
      // so /address closes the loop instead of leaving stale active threads.
      const suffix = `\n\nafter addressing each comment (and once any smoke checks pass), resolve it by running \`agent-comments resolve <comment_id>\` — multiple IDs are accepted in one call, or pass \`--all\` to resolve every active comment.`;

      pi.sendUserMessage(`${prefix}${output}${suffix}`, {
        deliverAs: "followUp",
      });
    },
  });
}
