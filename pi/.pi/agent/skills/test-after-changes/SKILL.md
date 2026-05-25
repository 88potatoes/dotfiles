---
name: test-after-changes
description: Remember and run user-specified test commands after making code changes. Use when the user asks to run specific unit tests, test files, or validation commands after changes are made, e.g. "run xyz unit tests after you make changes".
---

# Test After Changes

Use this skill when the user asks to make changes and also asks that specific tests run afterwards.

## Goal

Treat the user's requested test command(s) as a post-change obligation. After you finish editing code, run those command(s) before reporting done.

## Workflow

1. Identify the requested test command(s).
   - Prefer the exact command the user wrote.
   - If the user names tests but not a command, infer the narrowest repo-appropriate command.
   - For frontend unit tests, prefer scoped commands such as:
     ```bash
     pnpm test --testPathPattern=<path>
     ```
   - Do not run broad repo-wide typecheck/lint/test unless the user explicitly asks.
2. State briefly which command(s) you will run after changes.
3. Make the requested code changes.
4. Run the requested test command(s) after the edits.
5. If tests fail:
   - Read the failure.
   - Fix failures caused by your changes.
   - Re-run the same targeted command(s).
   - Repeat until passing or blocked.
6. Final response must include:
   - What changed.
   - Test command(s) run.
   - Pass/fail status.

## Rules

- Do not silently skip the requested test command(s).
- If a requested command is unsafe, unavailable, or needs secrets/services, stop and report the blocker.
- If the command is too broad or likely OOM-prone, ask before running it unless the user explicitly requested that exact broad command.
- If no files were changed, say so and ask whether to run the tests anyway.
- Keep the command scoped to the changed area when inferring a command.
- Do not replace the user's explicit command with a different one unless the explicit command is invalid; explain any substitution.

## Examples

User: "Change this hook and run useFoo.test.ts after changes."

Run after editing:
```bash
pnpm test --testPathPattern=useFoo.test.ts
```

User: "After changes run pnpm test --testPathPattern=letter-sender."

Run exactly:
```bash
pnpm test --testPathPattern=letter-sender
```
