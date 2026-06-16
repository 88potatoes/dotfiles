---
name: recent-work-summary
description: Summarize Eric's recent work across local git repositories by scanning commits in /Users/eric/Code. Use when asked what Eric did recently, in the past N days/weeks, across repos, or for a weekly/status summary from git history.
---

# Recent Work Summary

Use local git history to summarize recent work across repos.

## Defaults

- Root: `/Users/eric/Code`
- Time window: user-provided, else `2 weeks ago`
- Author: global git identity plus common variants:
  - `git config --global user.name`
  - `git config --global user.email`
- Include all refs with `--all` so local branches and remotes count.
- Prefer authored commits. If activity seems missing, mention scope and ask before broadening to all commits.
- Treat `refs/stash` as WIP evidence only. Do not count it as shipped work unless useful.

## Workflow

1. Find git repos under the root:

   ```bash
   find /Users/eric/Code -maxdepth 3 -type d -name .git -prune | sed 's#/.git$##' | sort
   ```

2. Get author identity:

   ```bash
   git config --global user.name
   git config --global user.email
   ```

3. Collect commits per repo:

   ```bash
   for repo in $(find /Users/eric/Code -maxdepth 3 -type d -name .git -prune | sed 's#/.git$##' | sort); do
     cd "$repo" || continue
     commits=$(git log --all --since='2 weeks ago' --author='Eric Lang\|eric@heidihealth.com' --date=short --pretty=format:'%ad%x09%h%x09%d%x09%s' 2>/dev/null)
     if [ -n "$commits" ]; then
       echo "===== ${repo#/Users/eric/Code/} ====="
       printf '%s\n' "$commits"
       echo
     fi
   done
   ```

   Adjust `--since` and `--author` to match the user request / detected git identity.

4. If the output is huge, summarize by theme. Do not paste raw full log unless requested.

5. Optional deeper read for important repos:

   ```bash
   git log --all --since='<window>' --author='<author-regex>' --name-only --pretty=format:'--- %ad %h %s' --date=short
   ```

   Use this only when commit subjects are too vague.

## Summary format

Keep concise.

Recommended sections:

- Scope: root, time window, author filter.
- Big themes: 3-6 bullets.
- Repo summary: repo-by-repo grouped bullets.
- Repos with no authored commits found, if useful.
- Caveats: local git only, not GitHub PRs/issues unless checked separately.

## Interpretation rules

- Merge commits: mention only if they show meaningful integration/conflict work.
- `WIP`, `fix stuff`, `things`: infer from nearby named commits and branch names, but label as WIP/local branch work when unclear.
- Remote PR merge commits with `(#123)` likely shipped. Say “landed” or “merged”.
- Branch-only commits without PR marker likely ongoing/local work. Say “worked on”.
- If multiple repos point to one feature, group into one cross-repo theme.
