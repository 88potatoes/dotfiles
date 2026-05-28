---
name: code-review
description: Review a GitHub PR or local branch diff, checking for bugs, style issues, security concerns, and suggesting improvements. Use when asked to review a PR, review code, check a diff, or critique changes.
---

# Code Review

Review code changes systematically. Find bugs, suggest improvements, enforce conventions.

## Inputs

- PR number: `review PR #123`
- Branch: `review branch feature-x`
- Files: `review changes in src/foo.ts`
- No input: review current branch against main

## Workflow

### 1. Fetch the Diff

For PR:
```bash
gh pr view <number> --json title,body,headRefName,baseRefName,additions,deletions,changedFiles
gh pr diff <number>
```

For branch:
```bash
BASE=$(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD origin/master)
git diff "$BASE"...HEAD
git diff --stat "$BASE"...HEAD
```

### 2. Understand Context

- Read PR description/commit messages.
- Identify the goal of the change.
- Note which files/areas are touched.

### 3. Review Categories

Check each category:

**Correctness**
- Logic errors, off-by-ones, null checks
- Edge cases not handled
- Race conditions in async code
- Error handling gaps

**Security**
- Input validation
- SQL/NoSQL injection
- XSS in rendered content
- Secrets/credentials exposure
- Auth/authz bypass

**Performance**
- N+1 queries
- Unnecessary re-renders
- Missing memoization where needed
- Large bundle imports

**Maintainability**
- Unclear naming
- Missing types
- Dead code
- Duplicated logic
- Missing tests for new behavior

**Style/Conventions**
- Project conventions (from AGENTS.md, work context)
- Consistent patterns with surrounding code
- Documentation for public APIs

### 4. Severity Levels

Classify each finding:

| Level | Meaning | Action |
|-------|---------|--------|
| 🔴 Blocker | Bug, security issue, data loss risk | Must fix before merge |
| 🟠 Major | Significant issue, missing error handling | Should fix |
| 🟡 Minor | Style, naming, small improvement | Nice to fix |
| 💬 Nit | Trivial preference | Optional |
| 💡 Suggestion | Refactor idea, future improvement | For consideration |

### 5. Output Format

```markdown
## Review: <PR title or branch>

**Summary**: <1-2 sentence overview of changes and overall assessment>

**Verdict**: ✅ Approve / 🔄 Request Changes / 💬 Comment

### Findings

#### 🔴 <File>:<line> - <Issue title>
<Explanation>
```suggestion
<suggested fix if applicable>
```

#### 🟠 <File>:<line> - <Issue title>
...

### What's Good
- <Positive observations>

### Questions
- <Clarifying questions if any>
```

## Rules

- Read the actual code, don't guess from filenames.
- Check AGENTS.md in the repo for project conventions.
- Praise good patterns, not just critique.
- Suggest fixes, don't just point out problems.
- If PR is large, focus on high-risk areas first.
- Don't nitpick formatting if linter handles it.
- Consider backward compatibility for API changes.

## GitHub Actions (Optional)

If user wants to post review:
```bash
# Approve
gh pr review <number> --approve --body "LGTM! <comments>"

# Request changes
gh pr review <number> --request-changes --body "<review body>"

# Comment only
gh pr review <number> --comment --body "<review body>"
```

For inline comments:
```bash
gh api repos/{owner}/{repo}/pulls/<number>/comments \
  -f body="<comment>" \
  -f path="<file>" \
  -f line=<line> \
  -f side="RIGHT"
```

## Response Style

Be direct. Lead with verdict. Group findings by severity. Include line numbers.
