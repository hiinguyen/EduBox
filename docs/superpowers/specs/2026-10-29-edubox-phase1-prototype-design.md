# EduBox Phase 1 - Android App Prototype Design

## Status

Approved by Hii on 2026-10-29.
Amended 2026-10-29 with Hii's build-kickoff decisions: account provisioning, content `status`/`classIds`, class `gradeLevel`/`subjects`, server-only `aiChats` writes with teacher and parent read access, Vietnamese UI, AI daily limit, and test start/late-submission rules.
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
- Lay a data model and architecture that Phase 2 (kiosk lock) and Phase 3 (dedicated hardware, possible backend migration) can build on without a rewrite.

## Non-goals (Phase 1)

- Kiosk/lock-task mode, device-owner provisioning, or any restriction on what else runs on the tablet.
- Custom hardware.
- Short-answer or essay auto-grading (objective/MCQ auto-grading only).
- Full parent feature set (Phase 1 ships a read-only summary view only).

## Architecture

```
Flutter App (Android tablet)
 |- Student mode: library, lessons, exercises, AI tutor chat, test room
 |- Teacher mode: content upload, assignment creation, results dashboard
 `- Parent mode: stub/read-only progress view
        |  (Firebase Auth - role-based via custom claims)
        v
Firebase Backend
 |- Firestore: users, classes, content metadata, assignments, submissions, scores, AI chat logs
 |- Storage: e-books (PDF/EPUB), video files, exercise assets
 |- Cloud Functions:
 |    |- aiProxy      -> calls OpenRouter, enforces system prompt + topic allowlist + per-student rate limit
 |    |- autoGrade    -> scores MCQ/objective exercises on submission
 |    `- contentIngest -> validates/transforms teacher-uploaded content
 `- Firebase Hosting (optional): lightweight teacher web console, same backend
```

One Flutter app serves all three roles, gated by a custom claim on the Firebase Auth user, backed by one Firestore/Storage backend. This avoids divergent data models between a "student app" and "teacher app."

### Why Flutter + Firebase

- Flutter: single codebase, strong offline/local-storage story, and Phase 2's kiosk/lock-task requirement is implemented via Android's native `DevicePolicyManager` / Lock Task API regardless of client framework - Flutter has stable platform-channel plugins for this, so Phase 1 does not block Phase 2.
- Firebase: managed auth, data, storage, and serverless functions remove infrastructure work during prototyping. Migrating to a custom backend is a deliberate, bounded Phase 3 task if the product needs it at scale, not a Phase 1 concern.

## Data model (Firestore)

- `users`: `{uid, role: student|teacher|parent, name, classIds[], linkedParentUid?}`
- `classes`: `{classId, teacherUid, name, gradeLevel, subjects[], studentUids[]}`. `gradeLevel` and `subjects[]` scope the AI tutor (see AI tutor flow).
- `content`: `{contentId, type: ebook|video|exercise, subject, gradeLevel, title, storagePath, classIds[], status: draft|approved, approvedBy: teacherUid, createdAt}`. Only content with `status == approved` for one of the student's classes is visible to students - this is the in-app enforcement point for "no unapproved content." The owning teacher approves content explicitly.
- `assignments`: `{assignmentId, classId, contentId, dueAt, type: practice|test}`
- `submissions`: `{submissionId, assignmentId, studentUid, answers[], score, gradedAt, gradedBy: auto|teacher}`
- `aiChats`: `{chatId, studentUid, messages[], subject, createdAt}`. Retained so teachers/parents can review what the AI discussed with the student.

### Firestore security rules

- Students: read only `content` where `status == approved` for one of their classes; write only their own `submissions`; read their own `aiChats`.
- `aiChats` is written only by the `aiProxy` Cloud Function, never by a client, so a student cannot forge the log or bypass the test lockout.
- Teachers: read/write `content` and `assignments` scoped to their own `classIds`; read `aiChats` of students in their own classes.
- Parents: read-only access to `submissions` and full `aiChats` transcripts for their linked student only.

### Accounts and roles

Phase 1 has no sign-up screen.
An admin/seed script creates accounts, sets the role custom claim, and links each student to one parent.
Users sign in with email and password.

### Language

The UI is Vietnamese, built on Flutter's localization system (ARB files) so further languages can be added later.

## AI tutor flow (OpenRouter)

1. Student sends a message from the in-app chat, scoped to a subject/grade context.
2. Flutter app calls the `aiProxy` Cloud Function; the client never calls OpenRouter directly.
3. `aiProxy`:
   - Loads a system prompt constraining the model to the student's subject/grade level and to study-help behavior only (no off-topic chat, no answering flagged test-mode questions, age-appropriate tone).
   - Applies a per-student rate limit (Firestore counter, default 30 messages/day, day boundary in Asia/Ho_Chi_Minh, set as a function parameter) for cost and misuse control.
   - Calls OpenRouter with a model configured in Function config (not hardcoded in the client), so the model can be swapped or A/B tested without a client release.
   - Logs the exchange to `aiChats`.
4. Response streams back to the app.
5. While a student has an in-progress test submission, `aiChats` writes are rejected server-side, disabling the AI tutor for the duration of the test to prevent its use for cheating.

The OpenRouter API key lives only in Cloud Functions configuration, never in the client binary.

## Test/exam room

- A teacher creates an assignment with `type: test`, a time limit, and a set of MCQ/objective questions.
- Starting a test requires connectivity, so the server records `startedAt` and can lock the AI tutor; losing connectivity after the start does not interrupt the test.
- The app enforces the time limit locally and auto-submits on expiry.
- The server accepts a submission that arrives after `startedAt` + time limit + a grace period, but flags it "late" for the teacher instead of rejecting it.
- On submission, `autoGrade` scores objective items immediately; results surface in the teacher dashboard and the parent summary view.
- AI tutor access is disabled for the duration of an active test (see AI tutor flow above).

## Error handling and offline behavior

- Content consumption is offline-first: downloaded e-books, videos, and exercises are cached locally (`sqflite` / local file cache); progress and submissions queue locally and sync when connectivity returns.
- The AI tutor requires connectivity; Phase 1 has no offline fallback - the UI shows an explicit "AI tutor needs internet" state rather than failing silently.
- If connectivity drops mid-test, answers are cached locally and auto-submitted on reconnect, with a visible "submission pending sync" indicator.
- Cloud Function failures (OpenRouter timeout/error, grading error) are surfaced to the user with a retry option and logged server-side; failures are never swallowed.

## Testing strategy

- Unit tests: grading logic, rate-limit logic, Firestore security rules (Firebase Rules emulator + test suite).
- Integration tests: Cloud Functions against the Firebase emulator suite (Auth, Firestore, Storage, Functions); OpenRouter calls are mocked in CI.
- E2E (Flutter `integration_test`): the three critical flows -
  1. student completes a lesson and exercise,
  2. teacher creates an assignment and sees a result,
  3. student takes a timed test with auto-submit.
- Target: 80% coverage on business logic (grading, rate-limiting, security rules).

## Open risks

- OpenRouter model choice affects both cost and answer quality for young students; start with a cheap/fast model and revisit once real usage data exists.
- Parent mode is a stub in Phase 1; its eventual feature set (notifications, detailed reports) is not yet scoped and should get its own brainstorming pass when prioritized.
- Firebase is a deliberate Phase 1 choice; if the product needs to leave Firebase at Phase 3 scale, that migration should be scoped as its own spec when it becomes a real constraint, not designed speculatively now.
