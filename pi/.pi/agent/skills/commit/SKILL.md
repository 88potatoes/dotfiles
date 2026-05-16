---
name: commit
description: Commit staged git changes with a message, monitor pre-commit hooks, fix hook failures, stage fixes, and retry until git commit succeeds. Use when the user asks to commit changes or invokes /commit.
---

# Commit

Commit staged changes while repairing pre-commit failures.

## Inputs

User arguments are the commit message. If no message is provided, use `wip`.

## Workflow

1. Determine commit message:
   - Use all user arguments as the message.
   - If empty/whitespace, use `wip`.
2. Inspect repo state:
   - Run `git status --short`.
   - If no staged changes exist, stop and tell the user nothing is staged. Do not stage unrelated work.
3. Run:
   ```bash
   git commit -m "<message>"
   ```
4. If commit succeeds, report success with the commit hash.
5. If commit fails due to pre-commit/lint/type/test issues:
   - Read the hook output.
   - Fix only the reported issues.
   - Prefer targeted file edits.
   - Run the narrowest relevant validation command for the fix.
   - Stage only files you changed to fix hook failures (`git add <paths>`).
   - Retry the exact same `git commit -m "<message>"`.
6. Repeat until commit succeeds or the failure is not safely fixable.

## Rules

- Never use `--no-verify`.
- Never change the commit message during retries.
- Do not stage unrelated files.
- Do not run broad destructive git commands (`git reset --hard`, `git checkout --`, etc.) unless the user explicitly asks.
- If a hook requires user secrets, external services, or a long-running command keeps getting killed, stop and explain.
- If there are unstaged user changes unrelated to the hook failure, leave them alone.
- Keep response terse: success hash or blocker.
