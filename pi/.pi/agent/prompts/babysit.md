---
description: Babysit CI — minimal fixes until green, picks local-smoke or remote-CI mode automatically
argument-hint: "[target-ref]"
---

Babysit the current branch's CI until it is green, or until unfixable.

1. Load the `babysit-work-context` skill first. It tells you what mode to use (local smoke vs remote sentinel) and which sibling skills exist.
2. Pick mode and follow the chosen skill end-to-end. Fix only the smallest thing that unblocks green. No refactors, no functional changes.
3. Loop: detect failure → minimal fix → push → re-check. Stop when green, blocked, or 1h elapsed.

Optional target ref: `$1` (default: current `HEAD`).
