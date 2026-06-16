---
name: bang-for-buck-refactors
description: Suggest and implement high-ROI maintainability refactors using SRP, interface extraction, and dependency injection. Use when asked to clean up code, make logic more testable, split responsibilities, add interfaces, or do bang-for-buck refactors.
---

# Bang For Buck Refactors

Goal: make code easier to test and maintain with minimal churn.

## When to Use

Use when user asks for:
- cleanup for maintainability
- Single Responsibility Principle review
- dependency injection
- interface extraction
- better unit tests via fake implementations
- bang-for-buck refactor suggestions or implementation

## Approach

1. Inspect the target code first.
2. Identify responsibilities currently mixed together:
   - pure domain/math logic
   - DOM or framework measurement
   - I/O or side effects
   - orchestration
   - rendering
   - persistence/serialization
3. Suggest only high-ROI splits. Avoid architecture astronaut.
4. Prefer interfaces for hard-to-test boundaries.
5. Use dependency injection only where it improves tests or reduces coupling.
6. Reduce parameter passing when it improves abstraction: prefer hooks/components that read nearby context or own their side effects instead of threading callback/ID props through parents.
7. Prefer grouped return objects or small child components over hooks that expose many loose values.
8. Keep public APIs stable unless user asks for a rename.
9. Add docstrings to new exported types, interfaces, classes, and functions.
10. Add focused unit tests using fake implementations where useful.

## Good Refactor Targets

### Pure Logic Extraction

Move deterministic logic into pure functions/classes.

Good examples:
```ts
interface LayoutEngine {
  calculate(input: LayoutInput): LayoutResult;
}
```

Use tests with simple inputs and outputs.

### Side-Effect Boundary

Wrap DOM, network, storage, clock, object URLs, file downloads, or third-party libraries.

Good examples:
```ts
interface DomMeasurer {
  measure(element: HTMLElement): Measurement;
}

interface Clock {
  requestFrame(callback: FrameRequestCallback): number;
  cancelFrame(id: number): void;
}

interface FileDownloader {
  download(file: File, fileName: string): void;
}
```

### Orchestration Service

Use a class only when coordinating multiple dependencies.

Good example:
```ts
class PdfService {
  constructor(
    private readonly pageFactory: PrintablePageFactory,
    private readonly renderer: PdfRenderer,
    private readonly merger: PdfMerger
  ) {}
}
```

Avoid classes for simple stateless helpers unless interface substitution is valuable.

## Implementation Rules

- Keep changes small and local.
- Prefer direct imports. Do not add barrel files.
- Do not run full repo typecheck unless explicitly asked.
- Run targeted tests for changed logic.
- If adding React UI strings, follow repo localization rules.
- If creating modals, follow lazy modal pattern from global context.

## Testing Pattern

For each new interface:
- test the default implementation if it contains logic
- test orchestration with fake implementations
- avoid jsdom layout reliance by injecting fake measurers

Example:
```ts
class FakeMeasurer implements DomMeasurer {
  measure() {
    return { width: 100, height: 200 };
  }
}
```

For pure logic:
```ts
expect(engine.calculate(input)).toEqual(expected);
```

## Docstring Standard

Add brief JSDoc to each new exported:
- type/interface: what it represents and who consumes it
- class: responsibility and whether it has side effects
- method/function: what it returns and why it exists

Example:
```ts
/** Reads DOM layout for pagination. Tests can inject a fake implementation. */
export interface PageDomMeasurer {
  /** Measures editable blocks in content-layer coordinates. */
  measureBlocks(): BlockLayout[];
}
```

## Review Checklist

Before handoff:
- responsibilities separated?
- pure logic testable without React/DOM?
- side effects behind interfaces?
- public API mostly stable?
- new exported symbols documented?
- focused tests pass?

## Response Style

Be terse. Say what was split, what interfaces were added, and tests run.
