---
description: Answer and act on my Hunk review comments, then reply inline in the session
argument-hint: "[repo path]"
---

Address the Hunk review comments on the current repo's live Hunk session.

1. Run `hunk session list --json` and pick the session whose `repoRoot` matches the current repo (or the `${1:-}` path if given). If no live session matches, stop and say so — do not guess.
2. Read the hunk-review skill: `hunk skill path` gives the location; load that `SKILL.md`.
3. List my notes with `hunk session comment list --repo <repoRoot> --type user --json`. Also check for your own prior replies (`--type agent`) so you don't duplicate answers.
4. For each note, inspect the real code at the note's file/line, then classify:
   - **Question** ("what is this?", "why do we…?") — answer it. No code changes.
   - **Feedback** ("this is wrong", "rename this", "handle X") — make the smallest targeted fix, validate (lint/tests per repo conventions), and commit.
5. Reply to every note in the session with `hunk session comment add --repo <repoRoot> --reply-to <note-id> --summary <answer>` — one reply per note, concise, no filler. For feedback notes, include the fixing commit hash.
6. Never delete or clear the user's notes. Don't re-answer notes you already replied to.
7. When done, report: notes answered, notes actioned (with commit), any blocked or deferred notes and why.

Target repo: ${1:-the current working directory}
