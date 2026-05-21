---
name: frontend-pr
description: Create or update a scribe-fe-v2 pull request with the frontend PR template filled very briefly. Use when the user asks to make, fill, or update a PR description for the frontend repo.
---

# Frontend PR

Create or update a `scribe-fe-v2` PR using the team template. Keep every answer brief.

## Workflow

1. Inspect branch and diff context:
   ```bash
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
   * **On-Prem Impact:** <N/A/Additive/Breaking + brief reason>

   ## Checklist
   * [ ] PR title follows `type(SCR-XXXX): brief description` format (e.g., `feat(SCR-1234): add patient export`)
   * [ ] All directories or files owned by my pod in this PR are covered by `.github/CODEOWNERS`
   * [ ] I have performed a self-review of my code
   * [ ] I have added tests that prove my fix is effective or that my feature works
   * [ ] I have reviewed the AI Code Review and resolved critical comments
   ```

4. On-Prem Impact:
   - Use `N/A` unless diff touches on-prem sensitive files:
     - `src/utils/buildProfile.ts`
     - `isOnPrem`-gated providers
     - `tauri-config.js`
     - `src-tauri/tauri.conf*.json`
     - `src/utils/endpoints.ts`
     - `package.json` analytics deps
     - `next.config*`
   - If touched, inspect `.ai-context/onprem-guardrails.md` if present and classify as `Breaking` or `Additive`.
5. Write the body using a heredoc temp-file trick:
   ```bash
   cat > /tmp/frontend-pr-body.md <<'EOF'
   <body>
   EOF
   ```
6. Title format:
   - Use `(feat|fix|chore)(integrations): {brief description} {LINEAR_TICKET_NUMBER}` when the ticket is known.
   - If no ticket is known, omit it.
   - Do not follow the generic title format in the template checklist.
7. Create or update PR:
   - If PR exists:
     ```bash
     gh pr edit --title "<title>" --body-file /tmp/frontend-pr-body.md
     ```
   - If no PR exists:
     ```bash
     gh pr create --title "<title>" --body-file /tmp/frontend-pr-body.md
     ```
8. Report PR URL only plus one terse status line.

## Style

- Be very brief.
- No long explanations.
- Prefer 1-line bullets.
- Do not mark checklist items unless the user explicitly says they are complete.
- Do not invent tests. If no tests, leave checklist unchecked.
- Use `cat > /tmp/frontend-pr-body.md <<'EOF'` for PR bodies so shell markdown characters are safe.
