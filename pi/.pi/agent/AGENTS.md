# Global Coding Conventions

## Context Updates

- When I say "remember", treat it as a request to add the information to the appropriate context in a meaningful way.
- When I say "harness", I may mean the Pi/context harness; update context when that is the meaningful interpretation.
- When I ask to add something to "context", decide whether it belongs in work context or global Pi context.
- Prefer work context (`~/.work-contexts/README.md`) for company-specific facts, repo aliases, private team conventions, PR templates, product-specific workflows, and Scribe-specific guidance.
- Use global Pi context (`~/.pi/agent/AGENTS.md` / `~/dotfiles/pi/.pi/agent/AGENTS.md`) only for company-agnostic personal coding preferences, Pi/dotfiles mechanics, or reusable OSS workflows.
- Only edit repo context when explicitly asked.

## Work Contexts

- `~/.work-contexts/README.md` contains private company/work-specific context. The work-context extension injects it into Pi context wrapped in `<work_context path="~/.work-contexts/README.md">`.
- `~/.work-contexts/skills/` contains work-specific skills. The work-context extension adds this skill path on startup/reload.
- Before editing `~/.work-contexts`, inspect git status and avoid mixing with pre-existing user changes.
- After editing files under `~/.work-contexts`, commit and push the work-context repo once at task completion.
- Use commit messages like `Update work context: <brief summary>`.

## Git

- When asked to "commit", interpret it as "stage all current repo changes, then commit" unless explicitly told otherwise.
- Before pushing code changes, run the relevant smoke test or validation command unless explicitly told to skip it.
- Never rebase. Always merge when bringing in changes from another branch.
- **Never use `--no-verify`** when committing. Always let pre-commit hooks run.

## Pi Extensions

- `~/.pi` is symlinked (via stow) to `~/dotfiles/pi/.pi`
- Write pi extensions to `~/dotfiles/pi/.pi/agent/extensions/`
- Do NOT write directly to `~/.pi/agent/extensions/`

## Agent Comments

`agent-comments` is a per-repo inline comment system stored in `.idea/agent-comments.json`. Use it to leave review notes, TODOs, or feedback on specific lines of code.

### CLI Usage

```bash
agent-comments add <file> <lines> <message>   # lines: 10 or 10:20
agent-comments get [resolved|unresolved]       # list comments (JSON when piped)
agent-comments get <file>                      # comments for a specific file
agent-comments resolve <comment_id>            # mark as resolved
agent-comments unresolve <comment_id>          # reopen
agent-comments delete <comment_id>             # remove
```

Short 8-char ID prefixes work for `comment_id`.

### When to use

- **Reviewing code:** leave comments on specific lines with `agent-comments add` instead of just describing issues in chat. When running the `code-review` skill, always use `agent-comments add` for each finding.
- **Addressing comments:** when Eric says "address comments" or "fix comments", run `agent-comments get unresolved` to see open comments. Comments may be questions or discussion prompts, not necessarily requests for code edits; answer those in chat instead of changing code. For actual requested changes, fix the code, then `agent-comments resolve <id>` each one.
- **Checking for comments:** before finishing a task, run `agent-comments get unresolved` to see if there are outstanding comments to address.

### Workflow for addressing comments

1. `agent-comments get unresolved` — read all open comments
2. For each comment: fix the code at the referenced file/lines
3. `agent-comments resolve <id>` — mark resolved after fixing
4. Repeat until `agent-comments get unresolved` returns empty

## TypeScript / JavaScript

- Do not run prettier/eslint after every small edit. Batch validation when useful, before handoff, or when explicitly requested.
- **Never use barrel files** (`index.ts` that only re-exports from other files). Import directly from the source module instead.
- If a function is used only once, do not extract it. Inline the logic instead.
- Prefer object parameters for functions when it improves readability or future extensibility, including callbacks that may gain more fields later. Example: use `onSubmit({ optionId })` instead of `onSubmit(optionId)`.
