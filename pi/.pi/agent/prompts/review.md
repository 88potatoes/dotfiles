---
description: Run the code-review skill on a PR, branch, or local diff
argument-hint: "[PR URL, branch, or notes]"
---
Use the `code-review` skill.

Review target: `${ARGUMENTS:-current branch diff against main}`.

If no target is provided, review the current branch diff against `origin/main` (or `origin/master` if main is unavailable).
Follow the code-review skill instructions exactly, including using `agent-comments add` for each finding.

Report findings tersely. If no issues, say so.
