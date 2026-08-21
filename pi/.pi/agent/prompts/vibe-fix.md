---
description: Fix unresolved PR review comments, commit, reply with commit links, and resolve threads
argument-hint: "[PR number or URL]"
---
Fix the unresolved review comments on the current GitHub pull request end-to-end.

Target PR: `${ARGUMENTS:-the PR associated with the current branch}`

## Goal

For every unresolved review thread:

1. Decide whether the comment is still actionable on the current PR code.
2. If it is actionable, make the smallest correct code/test change.
3. If the requested fix is already present and the comment is outdated, do not change code.
4. Commit the fixes in one focused commit after validation.
5. Push the branch.
6. Reply to every handled thread with a link to the relevant commit(s).
7. Resolve every handled thread, including outdated comments.

Do not leave a thread unresolved merely because it is outdated. Do not resolve a thread without first replying with the evidence or fix commit.

## Guardrails

- Use the GitHub CLI (`gh`) for GitHub reads and writes.
- The base repository is the API target, including for fork PRs.
- Resolve the PR unambiguously. If no current-branch PR exists, or an explicit target does not match the current checkout, stop and explain.
- Require the PR to be open and require the checked-out `HEAD` to equal the PR head SHA. Never comment on or resolve a different revision.
- Inspect the actual current code and the full thread history before deciding. A comment may have replies or may be superseded by a later commit.
- Do not touch unrelated worktree changes. If the worktree is dirty, inspect and preserve unrelated changes; stop if it is unsafe to distinguish them from this task.
- Never rewrite history, rebase, force-push, or use broad destructive git commands.
- Never use `--no-verify`. Run the narrowest relevant tests plus formatting/lint/type checks required by the repository before committing.
- Do not resolve comments that are not handled. If a comment needs a product/design decision, a new flag, infrastructure change, or other work outside this PR, reply explaining the blocker and leave it unresolved.
- Keep replies concise and kind. Do not expose secrets or large code snippets.

## Resolve the target

1. Load the repository's relevant `AGENTS.md` files and any applicable skills before changing code.
2. Resolve the PR from the explicit argument if supplied; otherwise use `gh pr view` for the current branch.
3. Fetch PR number, URL, state, base ref/OID, head ref/OID, head repository, and all review threads with their resolution/outdated state and comments.
4. Fetch the PR diff and inspect the current files and nearby tests.
5. Build a worklist containing only unresolved threads. Group duplicate or dependent comments, but preserve a reply for each original unresolved thread.

Use GraphQL `reviewThreads` rather than only the REST comments list so `isResolved` and `isOutdated` are authoritative. Use the thread node ID for `resolveReviewThread`.

## Classify each thread

Classify each unresolved thread as one of:

- **Fix needed:** the current code still has the issue. Implement the smallest root-cause fix and add/update tests when appropriate.
- **Already fixed/outdated:** the current code already addresses the comment, usually in a later commit. Do not make a no-op change. Identify the exact commit(s) that prove it.
- **Blocked/ambiguous:** cannot safely resolve without a decision or work outside the PR. Reply with the blocker and leave unresolved.

Do not blindly trust `isOutdated`: read the current code. Do not implement speculative review suggestions that conflict with the PR's stated behavior or repository conventions without calling that out.

## Implement and validate

- Make only focused changes for the fix-needed worklist.
- Prefer existing project patterns and nearby tests.
- Run targeted tests first, then the relevant formatter/linter/type check. If a test is blocked by missing local services or secrets, report the exact blocker; do not weaken production code to work around it.
- Review `git diff` and `git diff --check` before committing.
- Create one focused commit containing the fixes and tests. Use a clear message such as `fix: address PR review comments`.
- If no code changes are needed because every handled comment is already fixed, do not create an empty commit. Use the existing fixing commit SHA(s) in replies.
- Push the current branch and record the final pushed commit SHA.

## Reply and resolve

For each handled original thread, reply using the REST PR comments endpoint with `in_reply_to` set to the original comment ID. Always prefix every reply body with `Vibe-fixed: ` to make it clear the fix and reply were AI-assisted. Include direct GitHub commit links, for example:

`Vibe-fixed: Fixed in commit https://github.com/<owner>/<repo>/commit/<sha>.`

For an already-fixed/outdated comment, say what existing commit fixed it and that the current code was verified (prefixed with `Vibe-fixed: `). For a new fix, link the commit just created. If multiple commits are relevant, link each one briefly.

Only after the reply succeeds, resolve the thread using GraphQL `resolveReviewThread` and verify that it is resolved. If a reply or resolution fails, stop and report the exact thread and error rather than claiming completion.

After processing, re-fetch all review threads and verify:

- every originally unresolved handled thread is resolved;
- every handled thread has a reply from the authenticated user linking the relevant commit;
- blocked/ambiguous threads remain unresolved;
- the worktree is clean and the pushed branch contains the final commit.

## Final report

Report only the useful result:

- PR URL
- fix commit and link, or the existing commit links used when no new commit was needed
- number of code fixes, already-fixed/outdated threads, and blocked threads
- targeted validation run and any environment blockers
- unresolved threads that remain, with links and reasons
