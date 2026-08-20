---
description: Review the current GitHub PR for fishy code and post inline comments
argument-hint: "[PR number or URL]"
---
Run a fishy code review of the current worktree's GitHub pull request and post the review comments to GitHub on my behalf.

Target PR: `${ARGUMENTS:-the PR associated with the current branch}`

## Guardrails

- This is a review-only command. Do not edit files, fix code, commit, push, approve, or request changes.
- The posting step is authorized by this command; do not ask for a second confirmation after the target checks below pass.
- If the target PR cannot be resolved unambiguously, stop and explain what is missing. Never guess a repository or PR.
- Do not post speculative, purely stylistic, or low-confidence comments. A quiet review is better than noise.
- Do not expose secrets, tokens, private data, or large code snippets in comments.

## Resolve the target safely

1. Load the `unfish` skill and use its definition of fishiness. Also read the repository's relevant `AGENTS.md` files and the PR title/body.
2. Resolve the PR from the explicit argument if provided; otherwise use the current branch with `gh pr view`.
3. Fetch these PR facts: base repository owner/name, PR number and URL, state, base ref/OID, head ref/OID, and head repository.
4. Require the PR to be open. Require the checked-out `HEAD` to equal the PR's `headRefOid`; if it does not, stop rather than reviewing or commenting on the wrong revision.
5. Review the PR diff (`gh pr diff <number>` or an equivalent diff against the exact base/head OIDs), not unrelated worktree changes. If the worktree is dirty, mention that and ignore uncommitted changes.
6. Use the GitHub CLI for GitHub reads and writes. The base repository is the API target, including for PRs raised from forks.

## Comment tiers

Use exactly two tiers:

### 🔥 FISHY

A high-confidence, material problem: likely bug or regression, dangerous behavior, clear duplication that will drift, an abstraction that obscures correctness, or a structural smell that will predictably create maintenance bugs. It should be fixed before merge.

### 🐟 KINDA FISHY

A real, actionable smell with lower impact or some subjectivity: confusing naming, unnecessary indirection, localized duplication, awkward data shape, dead code, or a simpler clear alternative. It must still be more than a preference.

For every finding, include the exact problem and a concrete fix or direction. Put the likely failure or consequence in **Problem**. Do not add a separate rationale section.

Use this compact body format:

```markdown
🔥 **Fishy**

**Problem:** ...

**Fix:** ...
```

Use the equivalent `🐟 **Kinda fishy**` heading for the lower tier. Include a small before/after code snippet in **Fix** when it makes the change clearer. Never include large code snippets. Keep comments concise, kind, and easy to read: flag the code, not the author.

## Review process

- Read the actual changed code and nearby context before deciding something is fishy.
- Prioritize correctness-impacting smells, duplication, raw positional data, unclear public names, unnecessary complexity, dead code, and indirection without value.
- Look for missing interfaces or abstraction boundaries that would let separate resources change, test, or be replaced independently. Also flag leaky abstractions, false interfaces, and direct coupling to another resource's internals when the problem is concrete.
- Do not turn every `data` local, verbose implementation, framework convention, or unusual-but-explained choice into a comment.
- Prefer one comment per distinct finding. Do not bundle unrelated issues.
- Put each finding on the smallest changed line that demonstrates it. If a finding is not line-specific, put it in the top-level review body instead of anchoring it to an arbitrary line.
- GitHub inline comments must use a line present in the PR diff, with `side: RIGHT`. Do not comment on unchanged context or deleted lines.
- Before posting, deduplicate against existing review comments authored by the authenticated GitHub user on this PR. Do not repost the same tier/title/problem for the same path and line.

## Post one GitHub review

After the complete review is ready, post one review (not one API request per comment) to the base repository's PR endpoint:

- `commit_id`: the exact `headRefOid` that was reviewed;
- `event`: `COMMENT` (never `APPROVE` or `REQUEST_CHANGES`);
- `body`: a short summary headed `## Fishy review`, including counts for each tier and any non-line-specific findings;
- `comments`: the deduplicated inline findings, each with `path`, `line`, `side: RIGHT`, and `body`.

Use `gh api` with a JSON request body via a temporary file or stdin so multiline content, punctuation, and non-ASCII text are preserved. Do not interpolate comment text into an unsafe shell command. If GitHub rejects a line anchor, do not move it to a random line; report the rejected finding and post only valid findings.

If there are no findings, do not post an empty review. Report that the PR is not fishy at the requested thresholds.

Use plain language at about a Year 10 reading level. Prefer short sentences and common words. Explain technical terms only when needed.

Finally, report:

- the PR URL;
- how many `fishy` and `kinda fishy` comments were posted;
- any skipped duplicates or unanchored findings; and
- the posted review URL, if GitHub returned one.
