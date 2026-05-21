---
name: frontend-pr
description: Create or update a GitHub pull request with a concise PR template. Use when the user asks to make, fill, or update a PR description in any repo.
---

# PR

Create or update a GitHub PR using a concise team-style template. Keep every answer brief.

## Workflow

1. Inspect repo, branch, and diff context:
   ```bash
   git rev-parse --show-toplevel
   git branch --show-current
   git status --short
   BASE=$(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD origin/master)
   git diff --stat "$BASE"...HEAD
   git log --oneline "$BASE"..HEAD
   ```
2. Get existing PR URL if present:
   ```bash
   gh pr view --json url,title,body
   ```
3. Draft a concise PR body using this exact template:

   ```md
   ## Context
   * **Goal:** <1 short sentence>

   ## What Changed
   * <brief change 1>
   * <brief change 2>

   ## Dependencies
   * <None or brief dependency>

   ## Risk & Impact
   * **Blast Radius:** <brief scope>
   * **Rollback:** Revert PR
   * **Mobile Impact:** <N/A/Additive/Breaking + brief reason>
   * **On-Prem Impact:** <N/A/Additive/Breaking + brief reason>

   ## Checklist
   * [ ] PR title follows repo convention
   * [ ] All directories or files owned by my pod in this PR are covered by CODEOWNERS
   * [ ] I have performed a self-review of my code
   * [ ] I have added tests that prove my fix is effective or that my feature works
   * [ ] I have reviewed the AI Code Review and resolved critical comments
   ```

4. Impact notes:
   - Mobile Impact:
     - Use `N/A` if no client-facing API/schema/request/response/error behavior changed.
     - Use `Additive` for backward-compatible API/schema additions.
     - Use `Breaking` for removals/renames/type/nullability/default/error-shape changes.
   - On-Prem Impact:
     - Use `N/A` unless diff touches on-prem sensitive files/import closure.
     - Backend on-prem sensitive examples: `main_onprem.py`, `main_cloud.py`, `pyproject.toml`, `Dockerfile`, `entrypoint.sh`, `scripts/check_onprem_purity_drift.py`, `.github/workflows/onprem-*.yml`, new `pkg/<vendor>/` surfaces.
     - Frontend on-prem sensitive examples: build-profile gates, endpoint config, Tauri config, analytics deps, `next.config*`.
     - If touched, inspect repo docs/guardrails if present and classify as `Breaking` or `Additive`.
5. Write the body using a heredoc temp-file trick:
   ```bash
   cat > /tmp/pr-body.md <<'EOF'
   <body>
   EOF
   ```
6. Title:
   - Prefer existing PR title if still accurate.
   - Otherwise use repo convention if obvious from recent PRs/commits.
   - If no convention is obvious, use `<type>: <brief description>`.
   - Include ticket only when known.
7. Create or update PR:
   - If PR exists:
     ```bash
     gh pr edit --title "<title>" --body-file /tmp/pr-body.md
     ```
   - If no PR exists:
     ```bash
     gh pr create --title "<title>" --body-file /tmp/pr-body.md
     ```
8. Report PR URL only plus one terse status line.

## Style

- Be very brief.
- No long explanations.
- Prefer 1-line bullets.
- Do not mark checklist items unless the user explicitly says they are complete.
- Do not invent tests. If no tests, leave checklist unchecked.
- Use `cat > /tmp/pr-body.md <<'EOF'` for PR bodies so shell markdown characters are safe.
