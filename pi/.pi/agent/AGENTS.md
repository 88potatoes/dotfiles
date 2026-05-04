# Global Coding Conventions

## Pi Extensions

- `~/.pi` is symlinked (via stow) to `~/dotfiles/pi/.pi`
- Write pi extensions to `~/dotfiles/pi/.pi/agent/extensions/`
- Do NOT write directly to `~/.pi/agent/extensions/`

## TypeScript / JavaScript

- **Never use barrel files** (`index.ts` that only re-exports from other files). Import directly from the source module instead.

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
