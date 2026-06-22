import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execSync } from "node:child_process";

export default function (pi: ExtensionAPI) {
  pi.on("agent_end", async () => {
    try {
      execSync("cmux notify", { stdio: "ignore" });
    } catch {}
  });
}
