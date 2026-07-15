import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { execSync } from "node:child_process";

/**
 * /restack [onto <branch>]
 *
 * Bring the current branch up-to-date with whatever it's stacked on — the
 * stacked-PR workflow's "rebase" step, but using `merge` per repo convention
 * (never rebase). When called without arguments, walks the local + remote
 * refs to find the most likely "stack parent" branch; when called with
 * `onto <branch>` (or just `<branch>`), uses the explicit target.
 *
 * The command itself does no git writes. It identifies the target branch and
 * hands the rest of the work to the agent via `pi.sendUserMessage`, which is
 * where the convention-aware merge, smoke, and push steps actually happen.
 *
 * Detection heuristic (best effort, falls back to "ask the user"):
 *   1. Walk local refs only (refs/heads). Remote-tracking refs are skipped
 *      because in stacked-PR workflows the parent lives locally after a
 *      fetch; scanning them bloats the loop in repos with many stale
 *      remotes.
 *   2. Drop HEAD, the current branch, and any branch already merged into
 *      origin/main (trunk-merged; not a parent any more).
 *   3. Pick the candidate whose tip is an ancestor of HEAD AND whose
 *      `git rev-list --count <tip>..HEAD` is smallest — i.e. the branch that
 *      sits directly under the current branch on the stack.
 */

const META_WORDS = new Set(["onto", "from", "using", "target", "base"]);

/** Trim `[onto|from|using|target|base] <branch>` down to just `<branch>`. */
function parseTarget(args: string): string | null {
  const tokens = args
    .trim()
    .split(/\s+/)
    .map((t) => t.replace(/[,:]/g, ""))
    .filter((t) => t.length > 0);
  const targetTokens = tokens.filter((t) => !META_WORDS.has(t.toLowerCase()));
  return targetTokens.length > 0 ? targetTokens.join(" ") : null;
}

/** Walk the ref tree to find the most likely "stack parent" of HEAD. */
function detectStackParent(cwd: string): string | null {
  // Resolve HEAD + the current branch name (so we can drop ourselves).
  const headBranch = execSync("git rev-parse --abbrev-ref HEAD", {
    cwd,
    encoding: "utf-8",
  }).trim();

  // origin/main is the trunk filter — skip any branch whose tip is also an
  // ancestor of origin/main (already merged into the trunk).
  let mainSha = "";
  try {
    mainSha = execSync("git rev-parse --verify refs/remotes/origin/main", {
      cwd,
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
  } catch {
    mainSha = "";
  }

  // `set -e` so any failed git call short-circuits the loop body. The
  // subshell wrapping is needed so the inner git merge-base failures (which
  // exit non-zero on "not an ancestor") don't bubble out of the while-read.
  const script = [
    "set -e",
    `head_branch="${headBranch}"`,
    `main_sha="${mainSha}"`,
    `head_sha=$(git rev-parse HEAD)`,
    // Skip HEAD itself; refs/heads/<current> and refs/remotes/<remote>/<current>
    // are usually the same SHA but we don't want either as the candidate.
    `git for-each-ref --format='%(refname:short)' refs/heads`,
    // Filter out HEAD, the current branch (locally and on each remote), the
    // branch matching HEAD's SHA, and any ref that doesn't resolve.
    `| grep -vE '^HEAD$|^${headBranch}$|^(origin|upstream)/${headBranch}$'`,
    `| while read -r ref; do`,
    `  sha=$(git rev-parse --verify "$ref" 2>/dev/null) || continue`,
    // Drop refs that point at HEAD itself (detached-symrefs, mirrors).
    `  [ "$sha" = "$head_sha" ] && continue`,
    // The candidate must be an ancestor of HEAD — that's what makes it a
    // stack parent rather than a sibling/child.
    `  git merge-base --is-ancestor "$sha" HEAD 2>/dev/null || continue`,
    // Skip already-trunk-merged branches so we don't pick `feat/foo` after
    // it ships to origin/main.
    `  if [ -n "$main_sha" ]; then`,
    `    git merge-base --is-ancestor "$sha" "$main_sha" 2>/dev/null && continue`,
    `  fi`,
    `  distance=$(git rev-list --count "$sha..HEAD")`,
    `  printf '%s|%s\\n' "$distance" "$ref"`,
    `done`,
    // Smallest distance ⇒ closest stack parent.
    `| sort -t'|' -k1,1n | head -n 1`,
  ].join("\n");

  const result = execSync(`bash -c '${script.replace(/'/g, "'\\''")}'`, {
    cwd,
    encoding: "utf-8",
    stdio: ["ignore", "pipe", "pipe"],
  }).trim();
  if (!result) return null;
  const idx = result.indexOf("|");
  if (idx < 0) return null;
  const ref = result.slice(idx + 1).trim();
  // Pretty-print: drop the leading refs/remotes/<remote>/ prefix when a
  // local branch of the same name exists (we'd usually rather see `main`
  // than `origin/main`).
  const localMatch = ref.match(/^refs\/remotes\/[^/]+\/(.+)$/);
  if (localMatch) {
    const short = localMatch[1];
    try {
      execSync(`git rev-parse --verify "refs/heads/${short}"`, {
        cwd,
        stdio: ["ignore", "ignore", "ignore"],
      });
      return short;
    } catch {
      return ref;
    }
  }
  return ref;
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("restack", {
    description:
      "Merge the current branch's stack parent into HEAD (stacked-PR workflow). Usage: /restack [onto <branch>]",
    handler: async (args, ctx) => {
      const explicitTarget = parseTarget(args);
      const headBranch = execSync("git rev-parse --abbrev-ref HEAD", {
        cwd: ctx.cwd,
        encoding: "utf-8",
      }).trim();

      if (
        headBranch === "HEAD" ||
        headBranch === "main" ||
        headBranch === "master"
      ) {
        ctx.ui.notify(
          `Refusing to restack — current branch is '${headBranch}'. 'restack' only applies to feature branches.`,
          "error",
        );
        return;
      }

      const target = explicitTarget ?? detectStackParent(ctx.cwd);
      if (!target) {
        ctx.ui.notify(
          "Couldn't detect a stack parent branch. Run `/restack onto <branch>` to specify one (e.g. `/restack onto main`).",
          "error",
        );
        return;
      }

      // Be loud about what we picked so the user can correct it before the
      // agent starts the merge.
      ctx.ui.notify(
        explicitTarget
          ? `Restack ${headBranch} ⇐ ${target} (explicit)`
          : `Restack ${headBranch} ⇐ ${target} (auto-detected). Confirm in next message, or run \`/restack onto <other>\` to override.`,
        "info",
      );

      const brief = explicitTarget ? "explicit" : "auto-detected";
      const instruction = [
        `Restack \`${headBranch}\` on top of \`${target}\` (${brief}).`,
        "",
        "Stacked-PR workflow: bring the latest changes from the parent branch into HEAD so this branch sits cleanly on top.",
        "",
        "Steps:",
        `1. \`git fetch origin ${target}\``,
        `2. \`git merge --no-ff origin/${target} -m "Merge branch '${target}' into ${headBranch}'"\``,
        "3. Resolve any conflicts per the existing project convention (this repo disallows rebase — only merge).",
        "4. Run the relevant smoke checks (formatting + types + unit tests via `~/.work-contexts/skills/local-ci-smoke/scripts/`) for the changed files in the merge.",
        "5. Push with \`git push\` if green.",
        "",
        `Working directory: \`${ctx.cwd}\``,
        "",
        "When done, report back the merge result (clean / conflicts), and whether anything smoking failed. Do not push if smoke fails.",
      ].join("\n");

      pi.sendUserMessage(instruction, { deliverAs: "followUp" });
    },
  });
}
