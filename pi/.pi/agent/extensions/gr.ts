import { exec } from "node:child_process";

/**
 * /gr — open the current repo on GitHub in the browser.
 * Deterministic: runs `gh repo view -w` directly, no LLM involved.
 */
export default function (pi: any) {
	pi.registerCommand("gr", {
		description: "Open the current repo on GitHub in the browser",
		handler: () => {
			exec("gh repo view -w", (error, stdout, stderr) => {
				if (error) {
					console.error(stderr || error.message);
				}
			});
		},
	});
}
