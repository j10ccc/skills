---
name: j10c-frontend-playbook
description: j10c's personal frontend coding playbook. Invoke only when the user explicitly asks for it — NEVER auto-trigger.
---

> Personal coding preferences for AI agents to follow. Scope: **frontend React + TypeScript** projects. Instructions are kept short — don't over-constrain the agent, leave room for judgment.

## How to invoke

This playbook is **manually triggered** — not auto-discovered. Two operating modes:

- **Apply mode.** Invoked before / during writing frontend code. Treat the rules below as the spec to write against.
- **Audit mode.** Invoked to check existing or recently-edited code against the rules. Walk through the rules below, scan the target files (default: the files just edited in this session; ask the user if scope is unclear), and produce a punch list in this format:

  ```
  <file>:<line> — <rule violated> — <suggested fix>
  ```

  **Skip rules tagged `[process-only]`** — those describe conversational behavior and can't be checked from code artifacts alone. If no violations are found, say so explicitly.

## Before Implementation (Apply mode only)

Before writing or changing code, quickly scan the project for context that shapes how the rules below apply:

| Check | Affects |
|---|---|
| Is `lodash-es` already in dependencies? | If absent, **ask the user before adding it** — don't silently introduce a new dep |
| Is `@tanstack/react-query` set up? | The retry / four-state UI rules assume it |
| Tailwind or UnoCSS configured? | The layout-utility rule; if neither, don't introduce one unprompted |
| Existing `ErrorBoundary` pattern in the codebase? | Match it — don't invent a parallel implementation |
| `@/` path alias configured in `tsconfig` / `vite.config`? | If absent, ask before using `@/` |
| Monorepo with `pnpm workspace`? | Dependencies go through `catalog` |
| Existing ESLint config? | Follow it; don't propose new presets unprompted |

Skip this section in Audit mode — Audit checks code artifacts, not project setup.

## Core AI Collaboration Principles

- **Never cram all logic into a single file.** Split components, hooks, and utilities where it makes sense.
- `[process-only]` **Design before coding on complex tasks.** Don't literally implement whatever was said in a single straight line — think through the abstractions and module boundaries first.
- `[process-only]` **When uncertain, don't guess.** Offer 2–3 options and let me pick; don't decide alone.
- `[process-only]` **Keep completion reports short.** List the files changed plus a one-line summary — no per-change rationale.
- `[process-only]` **Drive-by improvements are encouraged, but assess diff size first.** Rename unclear identifiers, clean up awkward neighboring code, add missing TODOs as you go. **Provided the diff doesn't balloon** — if the change would touch many files or stray too far from the task's core scope, leave it alone, drop a TODO, or mention it in the report. Keep human review cost manageable.
- **Use `lodash-es` for data transformation, collection operations, and complex logic composition.** When you catch yourself chaining `map`/`filter`/`reduce`, building objects in a loop, or about to write a `groupBy` / `keyBy` / `partition` / `uniqBy` / `cloneDeep` / `debounce` / `get` / `set` helper — **don't roll your own**; lodash has it, and it reads better. This is the single most important rule in this document.

  ```ts
  // ❌ Bad — hand-rolling groupBy
  const grouped = items.reduce((acc, item) => {
    (acc[item.category] ??= []).push(item);
    return acc;
  }, {} as Record<string, Item[]>);

  // ✅ Good
  import { groupBy } from 'lodash-es';
  const grouped = groupBy(items, 'category');
  ```

## TypeScript

- Use `interface` for object shapes; `type` for unions, utility types, and function signatures.
- No `any`. Reach for `unknown` first; if you truly cannot type it, use `any` with a one-line comment explaining why.
- `as` assertions are allowed, but **never use them to fake a `useState` initial value** (e.g. `useState({} as User)`). Other uses are fine: DOM narrowing, `as const`, parsing external data, finishing off a type guard, double assertions.

  ```tsx
  // ❌ Bad — lying to TS about initial state
  const [user, setUser] = useState({} as User);

  // ✅ Good — model the real shape
  const [user, setUser] = useState<User | null>(null);
  ```
- Always use `interface FooProps { ... }` for props.
- Explicitly annotate function return types; **function components are exempt** — don't write `: JSX.Element`.

## React

### Component File Structure

A component directory may contain:

1. `index.tsx` — component entry.
2. `utils.ts` — business-agnostic utilities.
3. `helpers.ts` — business-specific utilities. Move functions here when component logic grows.
4. `constants.ts` — constants in `UPPER_SNAKE_CASE`.
5. `index.module.scss` — styles for business-coupled components. **Don't use SCSS variables — prefer CSS variables.** Class names in `camelCase`, no BEM.
6. `index.css` — styles for shared / non-business-coupled components. **Class names follow BEM.**
7. `components/` — subcomponent folder. **Only one level deep** — a page or shared-component entry may have `components/`, but those subcomponents must not have their own nested `components/`. Flatten everything into the same level; siblings may reference each other.

### Components and Hooks

- Keep each component file ≤300 lines; split into subcomponents or extract hooks when it grows past that.
- Don't pile state at the component root. When logic grows complex, group related state into hooks by topic.
- **When to extract a custom hook:** the logic is reused ≥2 times, or related state + effects within a single topic crowd the root component enough to obscure it (even on first use).
- For global / cross-component state, prefer `useContext`. Don't reach for a state-management library lightly.
- `useMemo` / `useCallback` / `React.memo` — don't add them by default; only when you hit an actual performance problem.

### Styling

- **Component-coupled styles → CSS modules / BEM** (per the file-structure rules above). Whenever a style block is meaningful enough to name, give it a class.
- **Layout-only styles → utility-first (Tailwind / UnoCSS),** when the project has them. Layout (flex, grid, spacing, sizing, positioning) is ad-hoc and resists good naming — atomic utility classes read more naturally than throwaway class names like `wrapper` / `inner` / `container`. **Don't extend utilities into component-style territory** — anything that deserves a name still gets a class.

## Production-Grade UI

- **Every component that fires a request must handle four states:** loading (skeleton / spinner), error (with an explicit retry affordance — a toast alone doesn't count), **empty data** (a deliberately designed placeholder, not a blank area), and successful data render. **Don't ship only the happy path.**

  ```tsx
  // ❌ Bad — only happy path
  function UserList() {
    const { data } = useQuery({ queryKey: ['users'], queryFn: fetchUsers });
    return <ul>{data.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
  }

  // ✅ Good — all four states handled
  import { isEmpty } from 'lodash-es';

  function UserList() {
    const { data, isLoading, isError, refetch } = useQuery({ queryKey: ['users'], queryFn: fetchUsers });
    if (isLoading) return <UserListSkeleton />;
    if (isError) return <ErrorState onRetry={refetch} />;
    if (isEmpty(data)) return <EmptyState message="No users yet" />;
    return <ul>{data.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
  }
  ```
- **Failed requests need retry logic.** For idempotent requests (GET, etc.), configure automatic retry with exponential backoff (tanstack-query handles this). For non-idempotent requests (POST / PUT / DELETE), do not auto-retry — let the user trigger retry via the error-state button.
- **Pages and important subtrees must be wrapped in an `ErrorBoundary`** so that a thrown error in one component doesn't white-screen the entire page. Wrap at the layout level — page roots, critical widgets.

## Naming

- File names: the linter handles this; the agent shouldn't worry about it.
- Booleans (variables / fields): mandatory prefixes — `is` / `has` / `should` / `can`.
- Event handlers: the prop is `onXxx`; the internal implementation is `handleXxx`.
- Enum values: `PascalCase` (`Status.Pending`), not `PENDING`.
- Constants: `UPPER_SNAKE_CASE`.

## Comments / Async / Errors

- Comments: public APIs require JSDoc. Internal code should be self-documenting via naming — write a comment only when the "why" is non-obvious.
- Async: always `async/await`. No `.then()` chains.
- `try/catch` only at business boundaries (API call sites, user-action entry points); let errors propagate through internal logic.
- Caught errors must be **reported and surfaced to the user** — never swallow them silently.
- Business-function failure is expressed by throwing — don't use `{ ok, data, error }` Result types.

## Code Organization

- Top-level structure by layer (`components/`, `pages/`, `hooks/`, `services/`, etc.); within each layer, group by feature.
- **Always use the `@/` path alias.** No relative paths.
- Barrel exports (`index.ts` re-exporting) are encouraged.

## Engineering Infrastructure

- **ESLint:** in existing repos, follow whatever config is in place. **When setting up a new repo, ask the user which preset to apply** — the user has their own rule set, but it varies per project; don't decide for them.
- **cspell:** for spell-checking.
- **monorepo:** bare `pnpm workspace` — no turbo / nx.
- **pnpm catalog:** monorepos must manage dependency versions via catalog.

## Audit Checklist

Quick reference for Audit mode — walk through this list against the target files. Each item points back to a rule in the sections above.

### Must follow

- [ ] Use `lodash-es` for data transformation / collection / complex logic composition
- [ ] `interface` for object shapes; `type` for unions, utility types, function signatures
- [ ] `interface FooProps` for component props
- [ ] Explicit function return types (function components exempt)
- [ ] Component file ≤300 lines
- [ ] Four states (loading / error / empty / success) on every request-firing component
- [ ] Retry: idempotent requests auto-retry + backoff; non-idempotent rely on user via error UI
- [ ] `ErrorBoundary` at page roots and critical widget subtrees
- [ ] Boolean prefixes: `is` / `has` / `should` / `can`
- [ ] Event handlers: `onXxx` (prop), `handleXxx` (impl)
- [ ] Enum values `PascalCase`; constants `UPPER_SNAKE_CASE`
- [ ] `async/await` only — no `.then()` chains
- [ ] `try/catch` at business boundaries only
- [ ] Caught errors: reported + surfaced to user
- [ ] `@/` path alias (no relative paths)
- [ ] Public APIs have JSDoc

### Must avoid

- [ ] Hand-rolled `groupBy` / `keyBy` / `partition` / `uniqBy` / `cloneDeep` / `debounce` / `get` / `set` etc.
- [ ] All logic crammed into one file
- [ ] `any` without a justifying comment (prefer `unknown`)
- [ ] `useState({} as User)` faked initial values
- [ ] Result types `{ ok, data, error }` for business failure (throw instead)
- [ ] Silently swallowed `catch` (no report, no user surface)
- [ ] SCSS variables (use CSS variables)
- [ ] BEM class names inside `index.module.scss`
- [ ] Tailwind / UnoCSS utilities used for component-style territory (anything that deserves a name)
- [ ] Nested `components/` directories more than one level deep
- [ ] Premature `useMemo` / `useCallback` / `React.memo`
- [ ] Relative paths (`../../foo`)
- [ ] State piled at the component root instead of grouped into hooks

## References

For patterns not covered in this playbook, fetch the official docs:

| Resource            | URL                                                             | Use For                                                   |
| ------------------- | --------------------------------------------------------------- | --------------------------------------------------------- |
| React               | https://react.dev                                               | Hook semantics, Suspense, ErrorBoundary patterns          |
| TypeScript handbook | https://www.typescriptlang.org/docs/                            | Type narrowing, generics, utility types                   |
| lodash              | https://lodash.com/docs                                         | Complete method list — check before hand-rolling anything |
| TanStack Query      | https://tanstack.com/query/latest/docs/framework/react/overview | Retry config, mutations, idempotency, state derivations   |
| Tailwind CSS        | https://tailwindcss.com/docs                                    | Utility class reference                                   |
| UnoCSS              | https://unocss.dev                                              | Same role as Tailwind; check the project's preset         |
| pnpm catalog        | https://pnpm.io/catalogs                                        | Workspace dependency management                           |
