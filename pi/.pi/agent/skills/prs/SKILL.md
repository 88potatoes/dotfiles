---
name: prs
description: Show recent PRs, stacked PR chains, bottom-of-stack merge targets, CI status, and critical comments. Use when asked for recent work, PRs, PR status, stacked PRs, or when /prs is invoked.
---

# PRs and Stacked PR Status

Provides an immediate, high-signal dashboard of recent PRs, stacked PR hierarchies, CI status, critical comments, and action items across all repos.

## Motivation & Problems Solved

- **Track Active PRs**: Quickly see what's open across all repos (`scribe-fe-v2`, `ml-scribe`, `infra`).
- **Stacked PR Clarity**: Solves the confusion of stacked PRs by clearly identifying the bottom of stack that targets trunk, and indenting subsequent PRs underneath so you can see what's next without status noise on upper PRs.
- **Actionability**: Surfaces exactly what needs attention right now (failing CI check names, reviewer blockers, merge conflicts/DIRTY, Hubert [CRITICAL] comments).
- **ADHD-friendly**: No clunky tables. High signal bullet lists, no bloated prose.

## Workflow

1. Run the PR retrieval script:
   ```bash
   python3 ~/.pi/agent/skills/prs/scripts/get-prs.py $ARGUMENTS
   ```
   Supported arguments:
   - Empty / no argument: Fetches across all repos by default.
   - `<repo>` or alias (`backend`, `ml-scribe`, `frontend`, `fe`, `infra`): Filters to that specific repo.
   - `--limit <n>`: PR limit (default 30).
   - `--json`: Output raw JSON for programmatic inspection.

2. Presentation Format:
   - **`### 🟢 To Merge`**: PRs with all required approvals + green CI + clean merge state.
   - **`### 🔴 Action Needed`**: Bottom-of-stack or standalone PRs with failing CI (with check name), changes requested (with blocker), or merge conflicts. If stacked, subsequent PRs in the stack are indented underneath.
   - **`### ⏳ In Review / Waiting`**: PRs waiting on reviewers or CI. If stacked, subsequent PRs are indented underneath so you see the chain.
