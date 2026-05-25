# Global Coding Conventions

## Context Updates

- When I ask to add something to "context", default to the Pi agent context (`~/.pi/agent/AGENTS.md` / `~/dotfiles/pi/.pi/agent/AGENTS.md`), not repo context. Only edit repo context when explicitly asked.

## Project Aliases

- "frontend" refers to `scribe-fe-v2`
- "backend" refers to `ml-scribe`
- "widget" refers to `scribe-js-plugin`

## Pi Extensions

- `~/.pi` is symlinked (via stow) to `~/dotfiles/pi/.pi`
- Write pi extensions to `~/dotfiles/pi/.pi/agent/extensions/`
- Do NOT write directly to `~/.pi/agent/extensions/`

## TypeScript / JavaScript

- Do not run full repo typecheck commands unless explicitly asked. They are too slow/OOM-prone. Only type-check changed files.
- Do not run prettier/eslint after every small edit. Batch validation when useful, before handoff, or when explicitly requested.
- **Never use barrel files** (`index.ts` that only re-exports from other files). Import directly from the source module instead.
- Prefer object parameters for functions when it improves readability or future extensibility, including callbacks that may gain more fields later. Example: use `onSubmit({ optionId })` instead of `onSubmit(optionId)`.
- When aliasing React Query mutation `mutate`, use a `mutate*` name, e.g. `const { mutate: mutateSyncDocument } = useMutateIntegrationsMixinSyncDocument();`.

## scribe-fe-v2 Localization

- Use `react-intl` for new UI and hook user-facing strings. Prefer `useIntl().formatMessage(...)` or `<FormattedMessage />` over legacy `useTranslations` / i18next patterns.
- React-intl IDs must be content hashes: `sha512(defaultMessage)` as base64, first 10 chars. Example: `defaultMessage: 'Notes successfully pushed'` -> `id: 'QYKLru0Wm4'`.

## scribe-fe-v2 Dialogs

- For design-system dialogs, keep Radix accessibility primitives while using typography components: wrap typography with `DialogTitle asChild` and `DialogDescription asChild`.
- Preferred modal header pattern:
  ```tsx
  <DialogTitle asChild>
    <TypographyH5>Title</TypographyH5>
  </DialogTitle>
  <DialogDescription asChild>
    <TypographyP2 className="text-text-tertiary">Description</TypographyP2>
  </DialogDescription>
  ```
- Do not replace `DialogTitle` / `DialogDescription` with plain typography only; this breaks dialog accessible names/descriptions.

## React Modals

Modals should be lazy loaded. Use this file structure:

```
my-modal.tsx        # Public API - lazy loads the implementation
my-modal-impl.tsx   # Implementation (data fetching, state, providers)
my-modal-content.tsx # UI/presentation (optional, for complex modals)
```

**Pattern for the public API (`my-modal.tsx`):**
```tsx
import { useAtomValue } from 'jotai';
import { lazy } from 'react';
import { showMyModalAtom } from '../atoms';

const MyModalImpl = lazy(() =>
  import('./my-modal-impl').then((mod) => ({ default: mod.MyModalImpl }))
);

export const MyModal = () => {
  const isOpen = useAtomValue(showMyModalAtom);

  if (!isOpen) {
    return null;
  }

  return <MyModalImpl />;
};
```

This ensures the modal chunk is only loaded when the user opens it.
