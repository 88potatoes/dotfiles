import { execSync } from "node:child_process";

/**
 * /gvr — mirror of the shell alias `gvr="gh pr view -w"`, with a repo fallback.
 * Deterministic: shells out to gh, no LLM involved.
 * 1. If the current branch has an open PR, open that PR in the browser.
 * 2. Otherwise, open the repo at the current branch (not main).
 */
export default function (pi: any) {
	pi.registerCommand("gvr", {
		description:
			"Open the current PR in the browser (falls back to the repo at the current branch)",
		handler: () => {
			try {
				const branch = execSync("git branch --show-current", { encoding: "utf8" }).trim();
				if (branch) {
					try {
						const url = JSON.parse(
							execSync(`gh pr view ${JSON.stringify(branch)} --json url`, {
								encoding: "utf8",
								stdio: ["ignore", "pipe", "ignore"],
							})
						).url as string;
						if (url) {
							execSync(`open ${JSON.stringify(url)}`);
							return;
						}
					} catch {
						// No PR on this branch: open the repo at the branch instead of main.
						execSync(`gh browse -b ${JSON.stringify(branch)}`);
						return;
					}
				}
				// Detached HEAD / no branch: just open the repo.
				execSync("gh repo view -w");
			} catch (error) {
				console.error(String(error));
			}
		},
	});
}
