# EduBox Phase 1 - Android App Prototype Design

## Status

Approved by Hii on 2026-10-29.
Amended 2026-10-29 with Hii's build-kickoff decisions: account provisioning, content `status`/class scope, class `gradeLevel`/`subjects`, server-only AI chat log writes with teacher and parent read access, Vietnamese UI, AI daily limit, and test start/late-submission rules.
Amended again 2026-10-29: Hii dropped Firebase; the backend is a self-written Dart server on Serverpod with PostgreSQL and S3-compatible object storage.
Scope: Phase 1 only (Android app prototype).
Phase 2 (locked study/kiosk mode) and Phase 3 (custom EduBox hardware device) are noted as future direction and are explicitly out of scope for this spec.

## Background

EduBox is a planned locked-down learning product for students: a device or app that restricts access to approved educational content only (e-books, video lectures, exercises, AI tutoring, dictionary, test rooms, teacher-provided materials) and blocks games, unapproved app installs, app stores, and system configuration changes.

The product is planned in three phases:

1. Android app prototype on an off-the-shelf tablet (this spec).
2. Add a locked "study mode" (Android kiosk/lock-task mode) to the same app.
3. Fully custom EduBox hardware device with a locked OS, bundled content, AI, and account/management system.

This spec covers only Phase 1: a working Android learning app with Student, Teacher, and (stub) Parent roles, content delivery, an AI study assistant, and a test/exam room, built to carry forward cleanly into Phase 2 and 3 without a rewrite.

## Goals

- Ship a working Flutter Android app validating the core learning loop: teacher publishes content and assignments, student studies and submits work, results are visible.
- Provide an AI study assistant that is scoped to the student's subject/grade level, cannot be used to cheat during tests, and is auditable by teachers/parents.
- Keep all provider API keys (OpenRouter) server-side.
- Lay a data model and architecture that Phase 2 (kiosk lock) and Phase 3 (dedicated hardware, own account and management system) can build on without a rewrite.

## Non-goals (Phase 1)

- Kiosk/lock-task mode, device-owner provisioning, or any restriction on what else runs on the tablet.
- Custom hardware.
- Short-answer or essay auto-grading (objective/MCQ auto-grading only).
- Full parent feature set (Phase 1 ships a read-only summary view only).
- Production hosting; Phase 1 runs on a local Docker Compose stack.

## Architecture

```
Flutter App (Android tablet)
 |- Student mode: library, lessons, exercises, AI tutor chat, test room
 |- Teacher mode: content upload, assignment creation, results dashboard
 |- Parent mode: stub/read-only progress view
 `- Local store (SQLite via drift): cached metadata, downloaded files, outbox of unsynced writes
        |  (Serverpod generated client; session auth; role checked on the server)
        v
EduBox Server (Dart, Serverpod)
 |- Endpoints: auth, profile, classes, content (upload + ingest validation), assignments,
 |            submissions (+ auto-grading), tutor (streaming aiProxy to OpenRouter), parent summary
 |- PostgreSQL: users and roles, classes, content metadata, assignments, submissions, scores, AI chat logs
 `- Object storage (S3-compatible; MinIO locally): e-books (PDF/EPUB), video files, exercise assets
```

One Flutter app serves all three roles, gated by the role stored on the server for the signed-in user, backed by one server and one database.
This avoids divergent data models between a "student app" and "teacher app."

### Why Flutter + a Serverpod backend

- Flutter: single codebase, strong offline/local-storage story, and Phase 2's kiosk/lock-task requirement is implemented via Android's native `DevicePolicyManager` / Lock Task API regardless of client framework - Flutter has stable platform-channel plugins for this, so Phase 1 does not block Phase 2.
- Serverpod: the server is Dart like the app, and Serverpod generates a typed client from the server's models and endpoints, so the app and server cannot drift apart silently.
  It provides PostgreSQL access with migrations, an email/password auth module, file uploads to object storage, and streaming endpoint methods, which covers every backend need in this spec.
- Owning the backend removes the vendor dependency before Phase 3, which needs its own account and management system anyway.
- Phase 1 runs the server, PostgreSQL, and MinIO locally through Docker Compose; no cloud account or billing is needed.

## Data model (PostgreSQL)

Each entity below is a table; list-valued fields become join tables in the schema.

- `users`: `{id, role: student|teacher|parent, name, email, linkedStudentId? (parent only), linkedStudentName? (parent only)}`, linked to the Serverpod auth user.
- `classes`: `{id, teacherId, name, gradeLevel, subjects[]}` plus class membership `{classId, studentId}`. `gradeLevel` and `subjects[]` scope the AI tutor (see AI tutor flow).
- `content`: `{id, type: ebook|video|exercise, subject, gradeLevel, title, storagePath, classIds[], status: draft|approved, approvedBy: teacherId, createdAt}`. Only content with `status == approved` for one of the student's classes is visible to students - this is the in-app enforcement point for "no unapproved content." The owning teacher approves content explicitly.
- `assignments`: `{id, classId, contentId, dueAt, type: practice|test}`
- `submissions`: `{id, assignmentId, studentId, answers[], score, gradedAt, gradedBy: auto|teacher}`
- `aiChats`: `{id, studentId, messages[], subject, createdAt}`. Retained so teachers/parents can review what the AI discussed with the student.

### Authorization (enforced on the server)

Every endpoint method checks the caller's session and role before touching data; the client never decides access.

- Students: read only `content` where `status == approved` for one of their classes; write only their own `submissions`; read their own `aiChats`.
- `aiChats` is written only by the tutor endpoint on the server, never through a client write, so a student cannot forge the log or bypass the test lockout.
- Teachers: read/write `content` and `assignments` scoped to their own classes; read `aiChats` of students in their own classes.
- Parents: read-only access to `submissions` and full `aiChats` transcripts for their linked student only.

### Accounts and roles

Phase 1 has no sign-up screen.
An admin/seed script creates accounts, sets each user's role, and links each student to one parent.
Users sign in with email and password through Serverpod's auth module.
The role lives only in the server's `users` table; clients cannot change it.

### Language

The UI is Vietnamese, built on Flutter's localization system (ARB files) so further languages can be added later.

## AI tutor flow (OpenRouter)

1. Student sends a message from the in-app chat, scoped to a subject/grade context.
2. Flutter app calls the server's tutor endpoint; the client never calls OpenRouter directly.
3. The tutor endpoint (the "aiProxy"):
   - Loads a system prompt constraining the model to the student's subject/grade level and to study-help behavior only (no off-topic chat, no answering flagged test-mode questions, age-appropriate tone).
   - Applies a per-student rate limit (a PostgreSQL counter, default 30 messages/day, day boundary in Asia/Ho_Chi_Minh, set in server configuration) for cost and misuse control.
   - Calls OpenRouter with a model set in server configuration (not hardcoded in the client), so the model can be swapped or A/B tested without a client release.
   - Logs the exchange to `aiChats`.
4. Response streams back to the app through a Serverpod streaming method.
5. While a student has an in-progress test submission, the tutor endpoint refuses new messages and `aiChats` writes, disabling the AI tutor for the duration of the test to prevent its use for cheating.

The OpenRouter API key lives only in the server's secret configuration (git-ignored), never in the client binary.

## Test/exam room

- A teacher creates an assignment with `type: test`, a time limit, and a set of MCQ/objective questions.
- Starting a test requires connectivity, so the server records `startedAt` and can lock the AI tutor; losing connectivity after the start does not interrupt the test.
- The app enforces the time limit locally and auto-submits on expiry.
- The server accepts a submission that arrives after `startedAt` + time limit + a grace period, but flags it "late" for the teacher instead of rejecting it.
- On submission, the server auto-grades objective items immediately; results surface in the teacher dashboard and the parent summary view.
- AI tutor access is disabled for the duration of an active test (see AI tutor flow above).

## Error handling and offline behavior

- Content consumption is offline-first: content metadata is cached in the app's local SQLite store, and downloaded e-books, videos, and exercises are kept in a local file cache; progress and submissions go into a local outbox and sync when connectivity returns.
- The AI tutor requires connectivity; Phase 1 has no offline fallback - the UI shows an explicit "AI tutor needs internet" state rather than failing silently.
- If connectivity drops mid-test, answers are cached locally and auto-submitted on reconnect, with a visible "submission pending sync" indicator driven by the outbox.
- Server failures (OpenRouter timeout/error, grading error) are surfaced to the user with a retry option and logged server-side; failures are never swallowed.

## Testing strategy

- Unit tests: grading logic, rate-limit logic, authorization checks.
- Integration tests: server endpoints against a real PostgreSQL and MinIO in Docker (Serverpod's test tools); authorization is tested per endpoint with an allowed and a denied caller; OpenRouter calls are mocked in CI.
- E2E (Flutter `integration_test`): the three critical flows, run on an Android emulator against the local Docker Compose stack -
  1. student completes a lesson and exercise,
  2. teacher creates an assignment and sees a result,
  3. student takes a timed test with auto-submit.
- Target: 80% coverage on business logic (grading, rate-limiting, authorization).

## Open risks

- OpenRouter model choice affects both cost and answer quality for young students; start with a cheap/fast model and revisit once real usage data exists.
- Parent mode is a stub in Phase 1; its eventual feature set (notifications, detailed reports) is not yet scoped and should get its own brainstorming pass when prioritized.
- Offline-first sync is now app code (local store plus outbox) rather than a managed SDK feature; conflict handling stays simple in Phase 1 because each submission has exactly one writer, the student who owns it.
- Production hosting (server, database, object storage, backups) is not designed in Phase 1 and needs its own spec before real deployment.
