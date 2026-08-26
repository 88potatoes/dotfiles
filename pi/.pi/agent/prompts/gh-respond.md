---
description: Respond to GitHub PR review comments, resolve handled threads, and surface anything blocked
argument-hint: "[PR number or URL]"
---

Respond to unresolved review comments on the current GitHub pull request.

1. Load the `gh-respond` skill first.
2. Verify the target PR is open, the current checkout is the PR branch, and `HEAD` matches the PR head SHA. If the worktree is clean and behind the PR head, fast-forward only; never rebase or force-push.
3. Fetch all unresolved review threads with GraphQL, plus full REST comment history. Inspect the actual current code and relevant commits before deciding.
4. Classify each thread as fixed, stale, needs-fix, blocked, or advisory/out-of-scope.
5. If the user asked only to respond or says fixes are already done, do not edit code or create an empty commit. If the user explicitly asks for fixes, make the smallest targeted changes, validate, commit, push, then respond.
6. Reply to every handled thread using `in_reply_to`, prefixing every reply with `Vibe-fixed: ` and linking the relevant fixing/removal commit.
7. Resolve each handled thread only after its reply succeeds. Leave blocked/deferred threads unresolved.
8. Re-fetch and verify handled threads, then report the PR URL, handled/resolved counts, commit links, remaining blocked threads, and validation status.

Target PR: `${ARGUMENTS:-the PR associated with the current branch}`
