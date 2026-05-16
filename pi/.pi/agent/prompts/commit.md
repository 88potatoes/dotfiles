---
description: Commit staged changes, fixing pre-commit issues until commit succeeds
argument-hint: "[message]"
---
Use the commit skill. Commit staged changes with message: `$ARGUMENTS`.

If no message is provided, use `wip`.
Run `git commit -m <message>`, monitor pre-commit, fix hook failures, stage only your fixes, and retry until commit succeeds. Never use `--no-verify`.
