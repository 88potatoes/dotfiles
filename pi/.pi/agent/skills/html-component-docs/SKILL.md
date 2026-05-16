---
name: html-component-docs
description: Write polished standalone HTML documentation for a component, feature, or module. Use when the user asks to document a component, create README.html docs, explain providers/hooks/API usage, or produce navigable visual docs with diagrams and code examples.
---

# HTML Component Docs

Use this skill when asked to write documentation for a component/feature/module in the polished HTML style established for Letter Sender V2 PageEditor docs.

## Output target

- Prefer `README.html` in the component/feature folder unless user names another file.
- If docs are exploratory issue notes, use a descriptive HTML file like `page-editor-issues.html`.
- Start by generating the shared boilerplate template, then replace placeholders with content:

```bash
/Users/eric/.pi/agent/skills/html-component-docs/generate-html-report-template.sh path/to/README.html "Report Title"
```

- The generated file is standalone HTML: `<!doctype html>`, embedded CSS, no build dependencies.
- Keep docs readable at fullscreen width: center and cap main content width around `1080px`.

## Required structure

Create a two-column layout:

1. Sticky left sidebar
   - Brand/title area.
   - Collapsible `<details>` groups.
   - Links jump to main content sections using anchors.
2. Main content
   - Hero summary.
   - Quickstart near top.
   - Focused sections below.

Use this rough order:

1. Summary / hero
2. Quickstart
3. Sync/update example near Quickstart, if relevant
4. Goals and non-goals
5. Provider/context diagram, if component uses React context/provider
6. Props/API table
7. Content/data contract
8. Format examples
9. Consolidated internal workings section
10. Operational notes: do/don't, limitations, future improvements

Avoid too many tiny disconnected sections. If several sections describe internals, consolidate into one `Internal workings` card with subheadings.

## Style conventions

Use embedded CSS with:

- soft neutral background (`#f8fafc`)
- white cards
- subtle borders (`#dbe3ef`)
- rounded cards (`18px`-`28px`)
- accent purple (`#5956d6` / `#7c3aed`)
- monospace code blocks with dark background
- responsive mobile behavior: sidebar becomes top block, single-column grids

Main CSS requirements:

```css
.layout {
  display: grid;
  grid-template-columns: 310px minmax(0, 1fr);
  min-height: 100vh;
}

aside {
  position: sticky;
  top: 0;
  height: 100vh;
  overflow-y: auto;
}

main {
  width: min(100%, 1080px);
  min-width: 0;
  margin: 0 auto;
  padding: 48px min(6vw, 72px) 96px;
}
```

## Quickstart rules

Quickstart should be minimal and uncoupled:

- Show imports.
- Show smallest working usage.
- Do not couple to the user's specific persistence layer unless they asked.
- Avoid names like `saveDocumentContent` unless documenting that exact integration.
- Prefer neutral names like `handleHtmlChange`, `onValueChange`, `onChange`, `handleUpdate`.
- If initial content is optional, show usage without initial content first.
- Then show optional initial content separately.
- Do not prescribe backend model details in generic component docs.

Example:

```tsx
export const MyEditor = () => {
  const handleUpdate = ({ htmlContent }: PageEditorUpdate) => {
    handleHtmlChange(htmlContent);
  };

  return (
    <PageEditorProvider onUpdate={handleUpdate}>
      <PageEditorContent />
    </PageEditorProvider>
  );
};
```

## Provider/context documentation

If the component has a provider/context:

- Include a nested-box SVG diagram.
- Show provider outer boundary.
- Show context provider boundary inside it.
- Show children that can call the hook.
- Explicitly note: hook only works inside provider boundary.
- Include invalid usage example showing hook outside provider throws.
- Remove unnecessary arrows unless they clarify data flow.

Provider diagram should visualize nesting more than flow.

Suggested diagram concepts:

- Outer box: `<ComponentProvider>`
- Inner box: `<ComponentContext.Provider value={...}>`
- Child boxes: content/toolbar/menu/etc.
- Warning box: outside provider hook throws.

## Diagrams and visualizations

Use inline SVG inside a `.diagram` card.

Good diagram types:

- Provider nesting diagram
- Data/content shape diagram
- Lifecycle diagram
- Layer diagram only if it adds value; omit if it feels redundant

Keep diagrams readable:

- Use rounded rectangles.
- Use simple labels.
- Use arrows sparingly.
- Make SVG `viewBox` wide enough and allow horizontal scroll.

CSS helpers:

```css
.diagram {
  overflow-x: auto;
  border: 1px solid var(--border);
  border-radius: 20px;
  background: linear-gradient(180deg, #ffffff, #f8fafc);
  padding: 18px;
  margin: 18px 0;
}

.diagram svg {
  display: block;
  min-width: 760px;
  width: 100%;
  height: auto;
}
```

## Internal workings section

Consolidate internals into one card with subheadings.

Include only the parts relevant to the component:

- Provider/context responsibilities
- Validation or data adaptation
- External library setup
- Rendering pipeline
- CSS/styling assumptions
- Known limitations

Example subheadings:

- Provider and context
- Validation
- Model / extensions
- Rendering
- Styling / PDF / output
- Limitations

## Content/data contract docs

Be explicit about accepted input and emitted output.

Example:

```html
<section id="content-contract" class="card">
  <h2>Content contract</h2>
  <div class="callout">
    <strong>Important:</strong> This component accepts HTML only.
  </div>
  <ul>
    <li>Valid: ...</li>
    <li>Invalid: ...</li>
  </ul>
</section>
```

If the component is intentionally generic, do not mention backend-specific content types or product persistence details.

## Code examples

- Prefer concise, real-ish TypeScript/TSX.
- Use neutral names.
- Show minimal valid usage before advanced usage.
- Escape JSX in HTML docs: `&lt;Component /&gt;`.
- Include invalid examples if the failure mode is important.

## Navigation conventions

Sidebar sections should match main content.

Recommended groups:

```html
<details open>
  <summary>Overview</summary>
  <a href="#summary">Summary</a>
  <a href="#quickstart">Quickstart</a>
  <a href="#goals">Goals and non-goals</a>
</details>
<details open>
  <summary>Public API</summary>
  <a href="#props">Props</a>
  <a href="#content-contract">Content contract</a>
  <a href="#sync-example">Sync example</a>
</details>
<details>
  <summary>Visual guide</summary>
  <a href="#provider-diagram">Provider diagram</a>
</details>
<details>
  <summary>Internal workings</summary>
  <a href="#internal-workings">Internal workings</a>
</details>
```

Remove nav links for deleted sections. Keep sidebar tidy.

## Editing existing docs

When updating an existing HTML doc:

- Preserve style and structure.
- Remove sections the user says are too noisy or too coupled.
- Keep Quickstart near top.
- Move Sync example near Quickstart if requested.
- Consolidate internals if disjoint blocks accumulate.
- Re-run `rg` for removed section ids/phrases to avoid stale nav links.

Useful checks:

```bash
rg "id=\"old-section\"|#old-section|removed phrase" path/to/README.html
```

## Tone

- Practical, direct, implementation-focused.
- Make docs easy to scan.
- Prefer “what to pass”, “what comes out”, and “where logic lives”.
- Avoid over-coupling reusable component docs to one product integration.
