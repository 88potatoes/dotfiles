---
description: Smoke fix, push branch, and create or update a PR
argument-hint: "[PR title or notes]"
---
Run the end-to-end PR flow for the current branch.

1. Use the `local-ci-smoke` skill. Run the combined smoke script. Fix actionable failures from formatting, lint, type-check, and targeted tests. Re-run the failed smoke step or full smoke until it passes.
2. If smoke reports merge conflicts with `origin/main`, stop and report the conflict. Do not merge unless explicitly asked.
3. If smoke reports CODEOWNERS coverage failure, stop and ask how to proceed. Do not auto-add owners.
4. If smoke created or required local changes, stage all current repo changes and commit them. Use this message if provided: `$ARGUMENTS`. If no message is provided, derive a concise message from the diff. Never use `--no-verify`.
5. Push the current branch.
6. Use the `frontend-pr` skill to create or update the PR. Use these notes if provided when drafting title/body: `$ARGUMENTS`.

Report only the PR URL plus one terse status line.
