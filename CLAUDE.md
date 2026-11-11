# CLAUDE.md

@AGENTS.md

The shared rules live in `AGENTS.md` so every agent reads the same source.
Everything below applies to Claude Code only.

## Claude-specific rules

- Never use the em dash character; use a plain dash "-".
- In Markdown files, put each full sentence on its own line.
- Never edit `CHANGELOG.md` or any file marked auto-generated.
- Read a file before editing it; prefer Edit over rewriting whole files.
- Prefer the dedicated Read, Grep, Glob tools over shell equivalents.
- Run independent tool calls in parallel.
- When a request has real ambiguity about public API, data, security, or hard-to-reverse choices, ask first; otherwise pick the conventional option and say so.
- Reuse and extend existing code before writing new code; check `src/lib` first.
- Prefer quality, simplicity, and long term maintainability over development cost.

## Design work

- Source of truth for UI is `design/<screen>/`; open `screen.png` and `code.html` before building a screen.
- If those files are missing, say so and ask for them instead of inventing a design.
- Be exacting about pixels: if something clearly looks off while testing, fix it even when unrelated to the task.

## Verification

- After code changes run `pnpm lint && pnpm typecheck && pnpm test`; run `pnpm build` before claiming a feature done.
- Report failures with the actual output; never claim success without running the check.
- For UI changes, load the page in a browser and check phone and desktop widths.

## Agents and review

- Use a code-reviewer pass after writing or modifying code.
- Use a security review for auth, user input, database queries, file access, external API calls, and AI endpoints.
- Use parallel agents for independent work.
- If a fix or review loop stops converging, stop and report to the user instead of escalating.

## Git

- Follow the Git workflow in `AGENTS.md`.
- Do not commit or push unless the user asks.
- Never run destructive git commands (`reset --hard`, `clean -f`, force push) without explicit approval.
