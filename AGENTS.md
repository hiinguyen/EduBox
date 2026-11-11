# EduBox - agent and contributor rules

EduBox is "Nền Tảng Học Thông Minh", a smart learning platform.
It has four product areas, each designed in Stitch (see `design/edusmart/DESIGN.md` for the design system):

| Route             | Screen                                                  |
| ----------------- | ------------------------------------------------------- |
| `/hoc-tap`        | Học tập & Trợ lý AI (student learning and AI assistant) |
| `/phu-huynh`      | Cổng Phụ huynh (parent portal)                          |
| `/thi-truc-tuyen` | Làm bài & Thi trực tuyến (assignments and online exams) |
| `/giao-vien`      | Không gian Giáo viên (teacher workspace)                |

## Stack

- Next.js 16 (App Router), React 19, TypeScript strict
- Tailwind CSS v4
- PostgreSQL with Prisma
- Zod for validation at every boundary
- Vitest for tests
- pnpm only (never npm or yarn)

## Commands

| Command           | Purpose                                                 |
| ----------------- | ------------------------------------------------------- |
| `pnpm dev`        | Dev server                                              |
| `pnpm lint`       | ESLint                                                  |
| `pnpm typecheck`  | `tsc --noEmit`                                          |
| `pnpm test`       | Vitest                                                  |
| `pnpm build`      | Production build                                        |
| `pnpm format`     | Prettier write                                          |
| `pnpm check`      | lint + typecheck + test + build (run before every push) |
| `pnpm db:migrate` | Create and apply a Prisma migration                     |

Copy `.env.example` to `.env` before running anything that touches the database.

## Project layout

```
src/app/<route>/        Route segments (page.tsx, layout.tsx, route.ts)
src/lib/                Pure logic, helpers, shared types
prisma/schema.prisma    Data model
design/<screen>/        Stitch exports (screen.png, code.html), reference only
design/edusmart/        Design system (DESIGN.md)
docs/                   Design and decision notes
```

- Organize by feature and domain, not by file type.
- Keep files focused: 200-400 lines typical, 800 maximum.
- Reference only: never import from `design/`.

## Code rules

### TypeScript

- `strict` is on and stays on. No `any`, no `@ts-ignore`; use `unknown` and narrow, or `@ts-expect-error` with a reason.
- Prefer `interface` for object shapes and `type` for unions.
- Use `import type` for type-only imports.
- Use the `@/` alias for anything under `src/`.
- Exhaustively handle unions (`never` check in the default branch).

### Style and naming

- Variables and functions: `camelCase`. Booleans start with `is`, `has`, `should`, or `can`.
- Types, interfaces, components: `PascalCase`. Constants: `UPPER_SNAKE_CASE`.
- Files: `kebab-case.ts`; components `kebab-case.tsx`; route folders use Vietnamese slugs without diacritics (as in the table above).
- No magic numbers or strings: name them.
- Functions under 50 lines, nesting under 4 levels; prefer early returns.
- Prettier formats the code; do not hand-format or argue about style.
- No dead code, no commented-out code, no `console.log` in committed code.
- Comments explain why, not what.

### Immutability

- Create new objects instead of mutating existing ones.
- Use `readonly` and `as const` for fixed data.

### React and Next.js

- Server Components by default; add `"use client"` only for state, effects, or browser APIs, and push it to the smallest leaf.
- Fetch data in Server Components or route handlers, not in `useEffect`.
- Mutations go through Server Actions or route handlers that validate input with Zod.
- Every route segment that loads data has `loading.tsx` and `error.tsx`.
- Do not hold server state in client global stores.

### Validation and errors

- Validate all external input (request bodies, query params, env vars, AI responses) with Zod at the boundary, then trust the typed result inside.
- Handle errors explicitly at every level; never swallow them silently.
- Show user-friendly Vietnamese messages in the UI; log detailed context on the server only.
- Never leak stack traces, SQL, or secrets in responses.

### Database

- Schema changes only through Prisma migrations, never by editing a live database.
- Use Prisma parameterized queries; no raw SQL string concatenation.
- Paginate every list query; no unbounded `findMany`.
- Avoid N+1: use `include`, `select`, or batching.

### Security

- No secrets in code or git. Read them from env, validate at startup, keep `.env` ignored.
- Authorization is checked on the server for every action, by role (`STUDENT`, `PARENT`, `TEACHER`).
- A parent may only see their own children; a student only their own work; a teacher only their own classes.
- Treat student data (minors) as sensitive: minimal collection, no PII in logs.
- Sanitize anything rendered as HTML; never use `dangerouslySetInnerHTML` with user or AI content.
- Rate limit auth, exam submission, and AI endpoints.

### UI and accessibility

- All user-facing text is Vietnamese. Code, comments, and commits are English.
- Follow the Stitch design for each screen; match spacing, color, and type exactly.
- Mobile first and responsive; verify at phone and desktop widths.
- Semantic HTML, visible focus states, labels on every input, contrast at WCAG AA.
- Exam screens must survive refresh and flaky network without losing answers.

## Testing

- Write the test first, watch it fail, then implement (red, green, refactor).
- Minimum 80% coverage; unit tests for `src/lib`, integration tests for route handlers and actions, E2E for critical flows (login, take exam, submit, parent view).
- Test names describe behavior: `returns empty array when no exam matches`.
- Arrange-Act-Assert structure.
- Fix the implementation, not the test, unless the test is wrong.
- A flaky or failing test is a bug: fix it even if you did not cause it.
- Bug fix: reproduce it end to end the way a user would experience it before changing code.

## Git workflow

### Branches

- `main` is protected and always releasable; never commit directly to it.
- Branch from `main`: `feat/<slug>`, `fix/<slug>`, `refactor/<slug>`, `docs/<slug>`, `chore/<slug>`.
- Keep branches short lived and rebase on `main` before opening a PR.

### Commits

Format (Conventional Commits):

```
<type>(<optional scope>): <description>

<optional body>
```

- Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`.
- Description: imperative, lowercase, no trailing period, 72 characters or fewer.
- Body explains why, with each sentence on its own line.
- One logical change per commit; commit tests with the code they cover.
- Never commit secrets, `.env`, build output, or `node_modules`.
- Do not edit `CHANGELOG.md` or any auto-generated file by hand.
- Do not add AI attribution trailers.

### Before every commit

1. `pnpm format:check`, `pnpm lint`, `pnpm typecheck`, `pnpm test` all pass.
2. `git diff --staged` reviewed; no debug code, no secrets.
3. Security checklist above holds for the changed code.

### Push and PR

- Run `pnpm check` before pushing.
- Push with `git push -u origin <branch>` the first time.
- Never force push to `main`; use `--force-with-lease` only on your own feature branch.
- Never skip hooks (`--no-verify`) or bypass CI.
- PR description covers the whole branch, not just the last commit: summary, screens affected, screenshots for UI changes, and a test plan.
- Merge only with CI green and no unresolved CRITICAL or HIGH review findings.
- Commit and push only when asked to.

## Definition of done

- Behavior works end to end in the browser, not just in unit tests.
- UI matches the Stitch design at phone and desktop widths.
- Lint, typecheck, tests, and build are green; coverage is at least 80%.
- No new warnings, no TODO without an issue reference.
- Docs updated when behavior, commands, or layout changed.

<!-- BEGIN:nextjs-agent-rules -->

## This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->
