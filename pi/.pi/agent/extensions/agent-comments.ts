import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { execSync } from "node:child_process";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("address", {
    description: "Fetch unresolved agent-comments and ask the agent to address them",
    handler: async (_args, ctx) => {
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

      pi.sendUserMessage(`please address these comments\n\n${output}`, {
        deliverAs: "followUp",
      });
    },
  });
}
