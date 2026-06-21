import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { execSync } from "node:child_process";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("address", {
    description: "Fetch unresolved agent-comments and ask the agent to address them",
    handler: async (_args, ctx) => {
      const projectDir = ctx.cwd;

      // Try to find agent-comments-2 from cwd or common paths
      const possibleDirs = [
        projectDir,
        `${projectDir}/agent-comments-2`,
        `${projectDir}/..`,
        `${projectDir}/../agent-comments-2`,
      ];

      let commentsDir = "";
      for (const dir of possibleDirs) {
        try {
          execSync("test -f src/index.ts", { cwd: dir, stdio: "pipe" });
          commentsDir = dir;
          break;
        } catch {
          // not this dir
        }
      }

      if (!commentsDir) {
        ctx.ui.notify("Could not find agent-comments-2 project", "error");
        return;
      }

      let output: string;
      try {
        output = execSync("agent-comments get", {
          cwd: commentsDir,
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
