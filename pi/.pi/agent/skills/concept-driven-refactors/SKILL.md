---
name: concept-driven-refactors
description: Turn messy parameter bags, unclear data shapes, and hard-to-debug logic into named concepts with explicit responsibilities. Use when code has too many arguments, vague structs, tangled calculations, or when debugging would be easier with clearer domain concepts.
---

# Concept Driven Refactors

Goal: turn implementation mess into concepts humans can reason about.

Use this when code is technically working but hard to explain, debug, or modify.

## Core Principle

If a set of values always move together, give them a name.

Bad smell:
```ts
calculate({
  contentHeight,
  gap,
  marginTop,
  marginBottom,
  bottomGuard,
});
```

Better:
```ts
calculate({
  layout: {
    pageStyle,
    spacing,
  },
});
```

Best when helper concepts expose the why:
```ts
const contentGap = calculateContentGap(layout);
const pageStride = calculatePageStride(layout);
```

## When to Use

Use for:
- functions with many parameters
- objects with vague names like `config`, `geometry`, `options`, `data`
- repeated arithmetic using related fields
- code that needs a paragraph of explanation to debug
- tests that hide intent behind raw numbers
- domain logic mixed with implementation details

## Refactor Steps

1. Read the code and tests.
2. Ask: what real-world/domain concepts are hiding here?
3. Group fields by responsibility, not by convenience.
4. Rename vague structs to domain names.
5. Add tiny helper functions for derived concepts.
6. Update call sites so they read like the explanation.
7. Add tests for the named concepts.
8. Add docstrings explaining the concepts in plain English.

## Group by Responsibility

Prefer this:
```ts
type PageStyleInfo = {
  contentHeight: number;
  marginTop: number;
  marginBottom: number;
};

type PageSpacing = {
  pageGap: number;
};

type PaginationLayout = {
  pageStyle: PageStyleInfo;
  spacing: PageSpacing;
};
```

Over this:
```ts
type Geometry = {
  contentHeight: number;
  gap: number;
  marginTop: number;
  marginBottom: number;
};
```

Because `PageStyleInfo` and `PageSpacing` explain what changes together and why.

## Derived Concept Helpers

When arithmetic encodes meaning, name it.

Bad:
```ts
const stride = contentHeight + gap + marginBottom + marginTop;
```

Good:
```ts
const contentGap = calculateContentGap(layout);
const pageStride = calculatePageStride(layout);
```

With docs:
```ts
/** Distance from the bottom of page N content to the top of page N+1 content. */
const calculateContentGap = (layout: PaginationLayout) =>
  layout.pageStyle.marginBottom + layout.spacing.pageGap + layout.pageStyle.marginTop;
```

## Naming Rules

- Use names from how a teammate would explain the feature.
- Avoid generic names unless the domain truly is generic.
- Prefer `pageGap` over `gap`.
- Prefer `pageStyle` over `geometry` if it means margins/page dimensions.
- Prefer `contentGap` over inline margin/gap sums.
- Prefer `layout` only when it composes smaller named concepts.

## Tests

Add small tests for each derived concept.

Example:
```ts
expect(calculateContentGap(layout)).toBe(124);
expect(calculatePageStride(layout)).toBe(424);
```

Then behavior tests can reuse the concept object:
```ts
calculatePageBreaks({ layout, blocks });
```

This makes failures easier to debug.

## Docstring Standard

Every new exported type/helper should say:
- what concept it represents
- what values belong to it
- why it exists for debugging/reasoning

Example:
```ts
/**
 * Page styling values that affect the vertical content area for pagination.
 * These describe the page itself, not the gap between separate rendered pages.
 */
export type RendererPageStyleInfo = { ... };
```

## Review Checklist

Before handoff, verify:
- can you explain the code in plain English using the new names?
- did raw parameter soup become named concepts?
- did repeated arithmetic become named helper functions?
- are tests written around concepts, not magic bags of numbers?
- are docstrings useful for a future debugger?
- did you avoid over-engineering and keep changes local?

## Response Style

Be terse. Say which messy shapes became which concepts, what helpers were added, and tests run.
