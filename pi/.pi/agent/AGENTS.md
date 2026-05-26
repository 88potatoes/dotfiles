# Global Coding Conventions

## Context Updates

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

- `grm` is available from zshrc as `git restore --source=main "$1"`. When asked to `grm` a file, restore that file to how it is on `main` (not `git rm`).

## Pi Extensions

- `~/.pi` is symlinked (via stow) to `~/dotfiles/pi/.pi`
- Write pi extensions to `~/dotfiles/pi/.pi/agent/extensions/`
- Do NOT write directly to `~/.pi/agent/extensions/`

## TypeScript / JavaScript

- Do not run prettier/eslint after every small edit. Batch validation when useful, before handoff, or when explicitly requested.
- **Never use barrel files** (`index.ts` that only re-exports from other files). Import directly from the source module instead.
- Prefer object parameters for functions when it improves readability or future extensibility, including callbacks that may gain more fields later. Example: use `onSubmit({ optionId })` instead of `onSubmit(optionId)`.
