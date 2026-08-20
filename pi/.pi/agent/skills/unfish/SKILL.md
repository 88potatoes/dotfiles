---
name: unfish
description: Review code for SOLID-related fishiness — tangled responsibilities, rigid or leaky abstractions, missing decoupling boundaries, oversized interfaces, and hard-wired dependencies — and fix it. Use when asked to "unfish", "make this less fishy", "is this fishy", "smell check", "clean this up", or when pointing at code and asking if something looks off. Not a full architecture audit or PR review — this is surgical cleanup of code that works but violates SOLID principles.
---

# Unfish

Make code not fishy anymore. Surgical cleanup of working code that smells.

## Trigger

- "is this fishy?"
- "unfish this"
- "smell check"
- "clean this up"
- User points at code and asks if something looks off

## SOLID Review Lens

Fishiness is code that works but makes the design harder to change, test, or reason about. Review in this order, and only flag a principle when the violation creates a concrete maintenance or correctness problem:

1. **Single Responsibility Principle** — one module, class, hook, or function owns multiple unrelated reasons to change. Split domain logic, orchestration, I/O, rendering, and side effects only when the boundary is real.
2. **Open/Closed Principle** — adding a supported case requires editing a growing conditional, switch, or unrelated callers. Prefer a focused strategy, registry, or polymorphic boundary when it makes extension local and explicit; do not abstract speculative variants.
3. **Liskov Substitution Principle** — an implementation, subtype, or adapter violates the contract of the abstraction it replaces: surprising no-ops, narrowed inputs, incompatible errors, or state assumptions that callers cannot rely on.
4. **Interface Segregation Principle** — consumers depend on broad parameter bags, god interfaces, or props containing unrelated capabilities. Keep contracts focused so callers do not implement or mock what they do not use.
5. **Dependency Inversion Principle** — core behavior constructs concrete services, reaches into global state, or couples directly to framework, network, or time APIs. Depend on a small meaningful boundary and inject it only when that improves testing or substitution.
6. **Resource decoupling and abstraction boundaries** — separate resources (for example, domain logic, persistence, network clients, UI, queues, or external integrations) should not share concrete implementation knowledge when they need to change, test, or be replaced independently. Look for missing interfaces, ports, adapters, or facades that would create a meaningful seam, as well as leaky or false abstractions that merely forward calls, expose resource-specific types, or couple two resources through shared mutable state. Prefer a narrow, behavior-focused contract owned by the consuming resource; do not add an interface solely because a second implementation might exist someday.

When assessing an interface or abstraction, ask:

- Does it let each resource evolve, be tested, or be replaced independently?
- Does it express a meaningful capability rather than mirror a concrete class or resource API?
- Does it keep implementation details and resource-specific data on the correct side of the boundary?
- Is the abstraction owned by the consumer that needs the contract, rather than by the implementation it happens to wrap?

Also flag the supporting smells when they reveal a SOLID problem:

- **Duplication** that will drift because knowledge has multiple owners.
- **Raw positional data or vague names** that hide a domain contract.
- **Dead code, unused parameters, or forwarding wrappers** that obscure responsibility without adding a seam.
- **Type unsafety** where a known contract is weakened with `Any` or casts.
- **Cross-resource coupling** where one resource reaches through another's internals, passes its concrete types across the boundary, or duplicates knowledge of its lifecycle and storage details.

Do not flag verbosity, framework conventions, or a single implementation merely because an abstraction could exist. Do not treat every direct dependency as fishy: a boundary is justified only when it reduces meaningful coupling or creates a real testing/replacement seam. Prefer the smallest change that restores a clear responsibility, contract, or decoupling boundary.

## Review Finding Format

For each finding, use one of these headings and keep the structure the same:

```markdown
🔥 **Fishy**

**Problem:** Say what the code does wrong in clear, direct language. Include the likely failure in this section if it helps.

**Fix:** Say what to change. Include a small before/after code snippet when code would make the fix clearer.
```

Do not add a separate **Why it matters** section. Put any important consequence in **Problem** instead.

For example:

````markdown
🔥 **Fishy**

**Problem:** Each renderer casts `columnDef.meta` to the full handler bag. TanStack cannot check this cast, so a column can omit a handler and fail at runtime. The renderer also depends on handlers it does not use.

**Fix:** Give each renderer a small typed context and pass only the values it needs.

```ts
// Before
const meta = column.columnDef.meta as OrganizationMemberColumnMeta;
return <NameCell label={meta.label} onEdit={meta.onEdit} />;

// After
type NameCellContext = Pick<OrganizationMemberColumnMeta, "label" | "onEdit">;

function renderNameCell(value: string, context: NameCellContext) {
  return <NameCell value={value} {...context} />;
}
```
````

## Review Tiers

When writing a fishy code review, use exactly these two tiers:

- 🔥 **Fishy** — a high-confidence, material problem: likely bug or regression, dangerous behavior, clear duplication that will drift, an abstraction that obscures correctness, or a structural smell that will predictably create maintenance bugs. It should be fixed before merge.
- 🐟 **Kinda fishy** — a real, actionable smell with lower impact or some subjectivity: confusing naming, unnecessary indirection, localized duplication, awkward data shape, dead code, or a simpler clear alternative. It must still be more than a preference.

For inline review comments, use the corresponding heading:

```markdown
🔥 **Fishy**
```

or:

```markdown
🐟 **Kinda fishy**
```

## What Is NOT Fishy

- Working code that's just verbose — verbosity is fine if it's clear
- Code that looks unusual but has a comment explaining why
- Framework boilerplate (Pydantic model_config, pytest fixtures, FastAPI Depends)
- Performance-motivated complexity with a comment

## Workflow

1. **Read the target** — the file, function, or directory the user pointed at
2. **Assess** — list what's fishy and what's fine, briefly
3. **If asked to fix**: make the changes, verify (compile/lint), commit and push
4. **If only asked "is this fishy?"**: report findings, ask if they want fixes

## Rules

- One concern at a time. Don't refactor the world.
- Keep public APIs stable unless the user explicitly asks to rename.
- Match existing code style in the file/repo.
- Run the relevant lint/compile check before committing.
- Don't introduce new dependencies to fix a smell.
- If a fix would touch 5+ files, flag it and ask before proceeding.
- Prefer the simplest fix. A dataclass beats a metaclass. A loop beats a nested comprehension. A spelled-out name beats a comment explaining an abbreviation.

## Response Style

Lead with verdict: "Fishy." / "Not fishy." / "A little fishy."

Then bullet the findings. Short. No essays about design philosophy.

Use plain language at about a Year 10 reading level:

- Prefer short sentences and common words.
- Explain a technical term when it is needed, or use a simpler word.
- Be direct about the problem and the fix.
- Include a focused code snippet in **Fix** when it helps show the change.

If fixing, show what changed and why in one line per change.
