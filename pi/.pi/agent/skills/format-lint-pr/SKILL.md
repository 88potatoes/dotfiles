---
name: format-lint-pr
description: Format files changed since the merge base, run lint on those changed files, commit formatting/lint fixes, push the branch, and create or update a PR. Use when the user asks to format/lint changed files since merge base or push a PR after validation.
---

# Format, Lint, Push PR

Format and lint files changed on the current branch since the merge base, then push a PR if changes exist.

## Workflow

1. Inspect repo state:
   ```bash
   git status --short
   git branch --show-current
   git remote -v
   ```
2. Determine merge base against the default upstream branch:
   ```bash
   BASE=$(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD origin/master)
   ```
3. List changed files since merge base:
   ```bash
   git diff --name-only --diff-filter=ACMR "$BASE"...HEAD
   ```
4. Format changed files that still exist:
   ```bash
   git diff --name-only --diff-filter=ACMR "$BASE"...HEAD | xargs pnpm exec prettier --write
   ```
5. Lint changed TS/TSX files only:
   ```bash
   git diff --name-only --diff-filter=ACMR "$BASE"...HEAD | grep -E '\\.(ts|tsx)$' | xargs pnpm exec eslint
   ```
   - If there are no TS/TSX files, skip lint.
6. If formatting/lint created changes:
   - Review `git diff`.
   - Commit only those changes with a clear message, e.g. `chore: format changed files`.
7. Push the current branch:
   ```bash
   git push -u origin HEAD
   ```
8. Create or update PR:
   - Check for existing PR:
     ```bash
     gh pr view --json url
     ```
   - If missing, create one:
     ```bash
     gh pr create --fill
     ```
9. Report PR URL and validation result.

## Rules

- Do not format the whole repo. Only files changed since merge base.
- Do not run broad destructive git commands.
- Do not hide lint failures. Fix narrow issues when safe; otherwise report blocker.
- Do not use `--no-verify`.
- If `gh` auth, push permission, or missing remote blocks PR creation, stop and report exact blocker.
- Keep response terse.
