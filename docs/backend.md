# EduBox backend foundation

This document is the contract between the foundation (phase BE-0) and the domain agents.
Domain agents must not edit `prisma/schema.prisma`, `src/lib/auth/**`, `src/lib/rate-limit/**`, `src/proxy.ts` or `src/lib/db.ts`.
If the contract is missing something, report it to the foundation owner.

## Local setup

1. `cp .env.example .env`, then set `AUTH_SECRET` (`openssl rand -base64 32`) and keep the Postgres values in sync with `DATABASE_URL`.
2. `docker compose up -d` starts Postgres 17 on `127.0.0.1:5432` with a named volume and a healthcheck.
3. `pnpm db:generate` generates the Prisma client into `src/generated/prisma` (git-ignored). Run it after install and after every schema change.
4. `pnpm db:migrate --name <name>` creates and applies a migration. `pnpm db:deploy` only applies existing ones.
5. `pnpm db:seed` loads idempotent demo data.
   It refuses unless `ALLOW_DEMO_SEED=1` is set (it is in `.env.example`, for local use only), `DATABASE_URL` points at `localhost`, `127.0.0.1` or `::1`, and `NODE_ENV` is not `production`.
   Re-running it is safe: the demo student's `StudyDay` and `SubjectWeekScore` rows are deleted and re-inserted, so rows written with wrong dates by an older seed are replaced.
   Week starts are the last 6 Monday-start VN weeks (`vnWeekStarts` in `prisma/seed-lib/dates.ts`) and study days are VN calendar days, both stored as UTC midnight like the app does.
   The seed creates no `ExamAttempt`; an attempt exists only after the student starts the exam.
6. `pnpm test` runs unit tests and needs no database.
7. `pnpm test:integration` runs `*.integration.test.ts` against a separate `<db>_test` database (created and migrated automatically, never the dev data). Override with `TEST_DATABASE_URL`.

## Environment variables

`src/lib/env.ts` validates them with Zod (`getEnv()`), and `src/instrumentation.ts` calls it at server start so a bad config fails fast.
Error messages list variable names and rules only, never values.

| Variable                                            | Purpose                                                      |
| --------------------------------------------------- | ------------------------------------------------------------ |
| `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` | Docker Compose database credentials                          |
| `DATABASE_URL`                                      | App connection string                                        |
| `AUTH_SECRET`                                       | Auth.js JWT secret, at least 32 characters                   |
| `AUTH_URL`                                          | Public app URL, https required in production                 |
| `TRUSTED_PROXY_HOPS`                                | Trusted reverse proxies in front of the app, default 0       |
| `ALLOW_DEMO_SEED`                                   | Set to `1` to allow `pnpm db:seed` (local only)              |
| `OPENCODE_API_KEY`, `OPENCODE_BASE_URL`, `AI_MODEL` | AI tutor, optional; the base URL must be https in production |
| `SEED_DEMO_PASSWORD`                                | Optional demo password for seeded accounts                   |

`TRUSTED_PROXY_HOPS` is the number of reverse proxies that append to `x-forwarded-for` in front of the app.
With `0` every forwarding header is attacker-controlled and ignored, so sign-in is limited per email and by a global cap only.
With `N > 0` the client IP is the N-th entry counted from the right of `x-forwarded-for`.
Set it only to the number of proxies you really run.

## Demo accounts (development only)

Every seeded login uses `SEED_DEMO_PASSWORD`, or the dev constant `Demo@12345` when unset.
The seed only runs behind the guard described in Local setup, so the constant never reaches a shared or production database.

| Role    | Email                    | Notes                                                                          |
| ------- | ------------------------ | ------------------------------------------------------------------------------ |
| Student | `minh.anh@edubox.test`   | Nguyễn Minh Anh, lớp 12A1, child of Bác Hùng                                   |
| Student | `gia.bao@edubox.test`    | Trần Gia Bảo, lớp 11B2, the outsider for ownership checks                      |
| Parent  | `van.hung@edubox.test`   | Bác Nguyễn Văn Hùng, parent of Minh Anh                                        |
| Parent  | `thi.lan@edubox.test`    | Chị Trần Thị Lan, parent of Gia Bảo                                            |
| Teacher | `thu.ha@edubox.test`     | Cô Nguyễn Thu Hà: 12A1, 12A2, 12D1                                             |
| Teacher | `quang.minh@edubox.test` | Thầy Trần Quang Minh: 11B2 only                                                |
| Teacher | `duc.dung@edubox.test`   | Thầy Trần Đức Dũng: co-teaches 12A1, authored the exam and the featured lesson |

The other students named in the teacher fixtures and the numbered filler students have no credential, so they cannot sign in.
Class sizes match the fixtures (48, 47, 47, 36) and the first quiz has 18 pending submissions.

## Auth design

- Auth.js v5 (`next-auth@5.0.0-beta.32`, compatible with Next 16 and React 19) with a Credentials provider (email and password).
- Sessions are JWT, 8 hours.
  The Credentials provider cannot use database sessions in Auth.js, and a stateless token keeps the proxy cheap.
  The token carries only the user id and role.
  `getSessionUser()` re-reads the user from the database on every request, so a deleted account or changed role takes effect immediately.
- Passwords use argon2id through `@node-rs/argon2` (OWASP parameters: 19 MiB, 2 iterations).
  It is a prebuilt native binding with no node-gyp step, and argon2id is the current OWASP first choice.
- The hash lives in its own `Credential` table, read only by `src/lib/auth/credentials.ts`.
- Failure path: malformed input, unknown email and wrong password all return `null` after one argon2 verification, so neither the message nor the timing reveals which accounts exist.
- Rate limiting is applied inside `authorize` (`src/lib/auth/sign-in-limits.ts`), so it covers both the form action and `/api/auth/callback/credentials`.
  Order of checks, all before any argon2 work: a global cap of 120 attempts per minute, then 30 per IP per 15 minutes (only when `TRUSTED_PROXY_HOPS` > 0), then 8 per email per 15 minutes.
  Email and IP key parts are HMAC-SHA256 (keyed with `AUTH_SECRET`) hex digests, so raw emails are never stored and key length is bounded.
  The IP comes from `x-forwarded-for` only through `TRUSTED_PROXY_HOPS`; a forged leading entry cannot rotate the limiter.
  A per-email limit also lets an attacker lock a known email out for 15 minutes, and the global cap lets a flood delay everyone's sign-in for a minute; both trade-offs are accepted.
- Expired `RateLimitBucket` rows are purged opportunistically: each limiter hit has a 1% chance of deleting buckets older than 24 hours.
- `src/proxy.ts` (Next 16 name for middleware) uses the edge-safe `src/lib/auth/config.ts`.
  Anonymous visitors to the four screens are redirected to `/dang-nhap?callbackUrl=...`.
  A signed-in user with the wrong role gets a 404.
  The proxy is a coarse first gate only; pages and actions still enforce roles.
- After sign-in, `/dang-nhap/chuyen-huong` sends the user to an allowed callback or their home: STUDENT `/hoc-tap`, PARENT `/phu-huynh`, TEACHER `/giao-vien`.
  Callbacks are accepted only as same-origin paths.
- Wrong role in a page is `notFound()` (404), chosen over `forbidden()` because that API is still experimental and a 404 does not reveal that the screen exists.
- Security headers (CSP baseline, nosniff, referrer policy, frame-ancestors none, X-Frame-Options, permissions policy) are set in `next.config.ts`.
  `Strict-Transport-Security` (two years, `includeSubDomains`) is added in production only.
  The CSP allows `'unsafe-inline'` scripts and styles because there are no nonces yet.

## The contract for domain agents

Import from `@/lib/auth/session` (server-only):

```ts
getSessionUser(): Promise<SessionUser | null>
requireUser(callbackPath?: string): Promise<SessionUser>            // redirects to /dang-nhap
requireRole(role | roles[]): Promise<SessionUser>                   // redirects if anonymous, notFound() if wrong role
requireRoleForAction(role | roles[]): Promise<ActionAuthResult>     // never redirects or throws
// SessionUser = { id, role, name, email, profileId }
// ActionAuthResult = { ok: true, user } | { ok: false, error: { code: "UNAUTHENTICATED" | "FORBIDDEN", message } }
```

`profileId` is the StudentProfile, ParentProfile or TeacherProfile id depending on the role, and is what every `access.ts` helper takes.

Import from `@/lib/auth/access` (server-only) the Prisma `where` fragments:
`childrenOfParent`, `studentsOfTeacher`, `classesOfTeacher`, `classesOfStudent`, `classesOfParent`, `lessonsOfTeacher`, `lessonsVisibleToStudent`, `chatThreadsOfStudent`, `notesOfStudent`, `assessmentsOfTeacher`, `assessmentsOfStudent`, `assessmentsOfParent`, `attemptsOfStudent`, `submissionsOfStudent`, `submissionsOfTeacher`, `submissionsOfParent`, `activityOfParent`, `contactBookOfParent`, `contactBookOfTeacher`, `notificationsOfUser`.
And the boolean guards:
`canParentViewChild`, `canTeacherAccessClass`, `canTeacherAccessStudent`, `canTeacherAccessAssessment`, `canTeacherAccessSubmission`, `canStudentAccessAssessment`, `canStudentAccessAttempt`, `canStudentAccessLesson`.

Rate limiting: `import { rateLimit } from "@/lib/rate-limit"`, then `await rateLimit(key, { limit, windowMs })` returns `{ isAllowed, remaining, retryAfterMs }`.
Use it for exam submission and AI endpoints, with a key like `exam-submit:${user.id}`; never put raw PII in a key.

### Shared server modules

- `@/lib/server/action-result` (pure, importable from client code): `ActionResult<T>`, `ActionErrorCode`, `ok`, `fail`, `failFromAuth`, `failFromZod`, `DEFAULT_ERROR_MESSAGES` (Vietnamese).
- `@/lib/server/log` (server-only): `logServerError(scope, error, context?)` logs the error name, code and ids only, never message text or PII.
- `@/lib/server/request-guard`: `assertSameOriginJson(request, { maxBytes })` rejects cross-origin POSTs, non-JSON content types and an oversized `Content-Length`; `readJsonBody(request, maxBytes)` reads the body through a byte-capped stream (also for chunked bodies).
  Both return typed results with an HTTP `status`, and never throw.
- `@/lib/format/date`: `DISPLAY_TIME_ZONE`, `getVnCalendarDay`, `startOfVnDay`, `startOfVnWeek`, `addVnDays`, `addDaysToVnDay`, `formatVnClock`, `formatRelativeDayLabel`, `formatRelativeAgo`.
  They never depend on the process time zone.
- `@/lib/format/time` (`MS_PER_MINUTE`, `MS_PER_HOUR`, `MS_PER_DAY`), `@/lib/format/number` (`roundTo`), `@/lib/format/name` (`getGivenName`).
- `@/lib/student/streak`: `computeStreak`, `MIN_STREAK_SECONDS`.

Definitions shared by every domain:

- A week is the Monday-start Vietnam week: it begins at `startOfVnWeek(date)`, Monday 00:00 in `Asia/Ho_Chi_Minh`.
- The study streak is the number of consecutive VN calendar days, ending today (or yesterday while today has no study yet), with at least 15 minutes (`MIN_STREAK_SECONDS`) studied.
  Nothing else may compute a streak.

### Domain behavior

Exams (`/thi-truc-tuyen`):

- Opening the page never starts an exam.
  Only the `startAttempt` Server Action (`start-attempt.ts`) creates the `ExamAttempt`, with `endsAt = min(now + duration, dueAt)`.
- Saving answers and submitting re-check that the assessment is `PUBLISHED` and the student is still enrolled in its class.
- An expired attempt is finalized lazily the next time it is touched.
  `finalizeExpiredAttempts(now, limit)` in `expire-attempts.ts` finalizes overdue attempts in bulk and is meant for a future scheduled job.
- Rate-limit keys: `exam-start:<userId>` 10 per minute, `exam-save:<userId>` 60 per minute, `exam-submit:<userId>` 10 per minute.

Progress records (`src/lib/student/progress-records.ts`), all taking a transaction client:

- `recordStudyTime` adds seconds to the `StudyDay` of the VN calendar day.
- `recordActivity` appends an `ActivityLog` row.
- `recordSubjectScore` upserts the `SubjectWeekScore` of the VN week (Monday start); the latest graded score of the week wins, clamped to 0..10 with one decimal.
- Hoc-tap progress saves credit at most 5 minutes of study time per save, increment `Lesson.viewCount` on the first view, record an activity on the first completion and keep `CourseEnrollment.progressPercent` in step.
- Exam finalization records an activity, and a subject score only when the attempt is fully auto-graded (no essay part).
- Giao-vien `saveGrade` records an activity and a subject score when a grade is new or its essay score changes.
  Parents are notified once per score value: only when the teacher asks for it and the score changed or no notice was sent yet.

Parent dashboard: `getParentDashboard` returns a status object, `{ status: "ready", dashboard }`, `{ status: "no-children" }` or `{ status: "not-found" }`, never `null`.

AI chat route (`POST /api/ai/chat`):

- It calls `assertSameOriginJson` and `readJsonBody` (8 KB cap) before reading the body, then `requireRoleForAction("STUDENT")`.
- Errors use only the shared `ActionErrorCode` values, mapped to HTTP status; a missing AI configuration or provider failure is `INTERNAL` with a Vietnamese message.
- While the student has an in-progress exam attempt the route returns `FORBIDDEN` with a lock message.
- `Retry-After` carries the real remaining window of the limit that was hit.
- Rate-limit keys: `ai-chat:<userId>` 20 per minute, `ai-chat-daily:<userId>` 200 per day, `ai-chat-global` 600 per minute.
- Lesson notes use `note-save:<userId>` 30 per minute and at most 50 notes per student per lesson.

### Configuring the AI

Set these in the git-ignored `.env`, never in a committed file:

```
OPENCODE_BASE_URL=https://opencode.ai/inference/go/openai/v1
AI_MODEL=deepseek-v4.1-flash
OPENCODE_API_KEY=<your key>
```

`AI_MODEL` is a bare model id.
The client appends `/chat/completions` to the base URL, and without all three variables the tutor reports that the AI is not configured.
The endpoint and the model id were taken from the opencode docs and still need one real call to confirm once a key is available.

### Rules

1. Every page calls `requireRole(...)` first (the foundation did not edit the screen pages, so each domain agent adds this line to its own `page.tsx`).
   Hoc-tap and thi-truc-tuyen: `STUDENT`. Phu-huynh: `PARENT`. Giao-vien: `TEACHER`.
2. Every Server Action and route handler starts with `requireRoleForAction(...)` and returns `error` to the client when `ok` is false.
3. Every query on a protected model ANDs in an `access.ts` fragment: `where: { AND: [submissionsOfTeacher(user.profileId), { ... }] }`.
   Single-resource reads and writes use the matching `canX` guard or the same fragment inside `where`.
   Never trust an id from the client without scoping.
4. Every external input (form data, params, query, body, AI output) is parsed with Zod at the boundary.
5. Every list query paginates (`take` with a cap, cursor or offset). No unbounded `findMany`.
6. Correct answers live only in `AnswerKey`.
   Never select `AnswerKey` in code that builds a response for a student; `Option` carries no correctness on purpose.
   Grade the attempt on the server from `AnswerKey`.
7. `ExamAttempt.startedAt` and `endsAt` are set by the server only.
   Answers are accepted until `endsAt` plus `SUBMIT_GRACE_MS` (30 seconds, to absorb network latency on the final autosave) and rejected on the server after that.
8. No PII in logs: log ids and error codes, not names, emails or answers.
9. Show Vietnamese messages in the UI and log details on the server only.
10. Do not add a `console.log`.
11. Every Server Action and route handler returns `ActionResult<T>` from `src/lib/server/action-result.ts` and logs failures with `logServerError`.
    Rate limiting happens inside the `try`, so a limiter failure returns `INTERNAL` instead of throwing.
12. Route handlers that accept a POST body call `assertSameOriginJson` and `readJsonBody` before parsing with Zod.

## Data model summary

- Identity: `User`, `Credential`, `StudentProfile`, `ParentProfile`, `TeacherProfile`, `ParentChild` (parent owns child), `ParentSettings` (per parent and child), `StudentDevice`.
- Classes: `SchoolClass`, `Enrollment`, `TeacherClass`.
- Learning: `Course`, `CourseEnrollment`, `Lesson` (+ `LessonClass`, `LessonChapter`, `LessonProgress`, `Note`), `Material`.
- AI tutor: `ChatThread`, `ChatMessage`.
- Assessment: `Assessment`, `Question`, `Option`, `AnswerKey`, `ExamAttempt` (one per student and assessment), `AttemptAnswer`, `Submission`, `Grade` (a submission without a Grade is pending), `TeacherInsight`, `KnowledgeGap`.
- Parent portal and progress: `ParentTeacherNote` (contact book), `ActivityLog`, `StudyDay`, `SubjectWeekScore`, `Badge`, `StudentBadge`, `Notification`.
- Infrastructure: `RateLimitBucket`.

Notes:

- Scores are `Float` on a 10-point scale.
- Teacher stats (pending count, completion rate, average) and class `studentCount` are derived from rows, not stored.
- `Lesson.viewCount`, `ratingAverage` and `ratingCount` are denormalised counters.
  The intended rule is that they are maintained inside the hoc-tap and giao-vien actions that change the underlying data, as documented once the domain wave lands, and never recomputed ad hoc in pages.
- `CourseEnrollment.progressPercent` is a stored aggregate for the course cards.
- JSON columns (`Question.prompt`, `Question.figure`, `Submission.aiSuggestion`, `ActivityLog.description`, `ActivityLog.tags`) must be validated with Zod on read and write.

## Known limitations and next steps

- Exam notes are stored only in the browser draft; `AttemptAnswer` has no note column.
  Adding `note String?` is the schema change needed if server storage is wanted.
- Essay questions have no student input UI, so an exam with essay questions has no answers for that part and stays pending for the teacher.
- Grade notifications are in-app only; there is no Zalo or email sender.
- Two concurrent saves of the same grade with the notify box ticked could in theory notify twice; a serializable transaction would close it.
- `finalizeExpiredAttempts` needs a scheduler in production; until then expired attempts are finalized only when touched.
- The CSP still allows `'unsafe-inline'`; nonces are planned.
- An unauthorized resource page responds with HTTP 200 and the 404 body, because `loading.tsx` streams first.
  The response is identical for unknown and foreign ids, so no existence leaks.

## Open items

- The sign-out button exists in `user-menu.tsx` and `mobile-navigation.tsx`.
- The sidebar is filtered by role through `getPrimaryNavForRole`.
- `CURRENT_USER` has been removed; pages read the user with `requireRole(...)`.
- `upcomingAssessmentsOfStudent(studentId, now)` in `access.ts` is the single definition of a student's upcoming work; domain code should adopt it.
- Integration tests should use `createTaggedWorld()` from `src/test/world.ts`, which removes only its own tagged rows.
  `resetDatabase()` truncates whole tables, is only for suites that explicitly need an empty `<db>_test`, and relies on `fileParallelism: false`.
