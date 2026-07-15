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
- **Skip pre-commit hooks (`--no-verify`) on `scribe-fe-v2` frontend commits when local smoke has already passed** (formatting + lint + types + unit tests via `~/.work-contexts/skills/local-ci-smoke/scripts/`). Pre-commit is multi-minute on this repo; running it after a green smoke is wasted wall-clock. Outside the frontend, `--no-verify` still requires an explicit ask.


## Pi Extensions

- `~/.pi` is symlinked (via stow) to `~/dotfiles/pi/.pi`
- Write pi extensions to `~/dotfiles/pi/.pi/agent/extensions/`
- Do NOT write directly to `~/.pi/agent/extensions/`

## Agent Comments

Run `agent-comments help` at session start to learn the CLI interface. All communication goes through the CLI.

## Bash Tool (timeouts)

- Every `bash` call gets a timeout. The `bash-timeout` extension sets a default of 5 min, bumps anything `<= 1s` up to that default, and hard-caps at 30 min.
- For known-slow ops (`pnpm install`, full `pnpm test`, `cargo build/test`, `pnpm e2e`, etc.), pass an explicit `timeout` (seconds) sized for the job. Don't rely on the default for those.
- If a command times out, narrow it (smaller surface, more flags) or raise the timeout explicitly — don't loop re-running it.
- Read, write, edit, and other non-bash tools have their own internal limits; no extension hook required.

## TypeScript / JavaScript

- Do not run prettier/eslint after every small edit. Batch validation when useful, before handoff, or when explicitly requested.
- **Never use barrel files** (`index.ts` that only re-exports from other files). Import directly from the source module instead.
- Prefer object parameters for functions when it improves readability or future extensibility, including callbacks that may gain more fields later. Example: use `onSubmit({ optionId })` instead of `onSubmit(optionId)`.
