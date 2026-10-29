# EduBox roadmap

Spec: docs/superpowers/specs/2026-10-29-edubox-phase1-prototype-design.md
Git authority: phase-branch commits yes; merge to main after gate: yes (the main branch is `master`; branch `phase-N` comes off `master` after phase N-1 is merged)
Stack: Flutter (Android tablet, Vietnamese UI via Flutter l10n/ARB) + Firebase (Auth, Firestore, Storage, Cloud Functions v2 in TypeScript on Node); emulator-only project `demo-edubox`, no real cloud project, no billing; OpenRouter mocked (an optional real key can be supplied through the git-ignored `functions/.secret.local`)
Commands: build `(cd app && flutter build apk --debug) && npm --prefix functions run build` | lint `(cd app && flutter analyze && dart format --output=none --set-exit-if-changed .) && npm --prefix functions run lint` | test `(cd app && flutter test --coverage) && firebase emulators:exec --project demo-edubox --only auth,firestore,storage,functions "npm --prefix functions test -- --coverage"` | e2e `firebase emulators:exec --project demo-edubox --only auth,firestore,storage,functions "npm --prefix functions run seed:emulator && cd app && flutter test integration_test -d $EDUBOX_E2E_DEVICE"`

Prerequisites (installed by the user, not by the pipeline):
- Flutter SDK (stable) with the Android toolchain, Android SDK, and an x86_64 tablet AVD named `edubox_tablet` (API 34 or newer).
- JDK 21 or newer (the Firestore and Storage emulators run on Java).
- Node 22 and the Firebase CLI (`firebase-tools`).

Notes on commands:
- `EDUBOX_E2E_DEVICE` is the device ID of the running `edubox_tablet` AVD as printed by `flutter devices` (normally `emulator-5554`); start it first with `flutter emulators --launch edubox_tablet`.
- The Android emulator reaches the host's Emulator Suite at `10.0.2.2`; the app reads emulator host and ports from a backend config object so tests can override them.
- `npm --prefix functions test` runs Cloud Functions unit tests, Functions integration tests against the emulators, and the Firestore and Storage security-rules suites (`@firebase/rules-unit-testing`).
- Coverage gates (80% minimum) apply to grading, rate-limit, lockout, and Firestore security-rules logic; Firestore rules coverage is read from the Firestore emulator's rule-coverage report; Storage rules have no coverage report, so they are gated by a per-branch test matrix instead (see Rulings).
- `seed:emulator` creates the demo accounts with role custom claims, parent links, classes with `gradeLevel` and `subjects[]`, and fixture content used by E2E tests.
- Paths `app/` (Flutter) and `functions/` (TypeScript) are an ASSUMPTION; the phase 1 contract-architect may rename them and must update these commands.

## Status

| Phase | Goal | Status | Branch | Contract tag | Gate round | Updated |
|---|---|---|---|---|---|---|
| 1 | Each role signs in to a Vietnamese UI and lands on its own home; student sees only approved content; a streaming function reaches the app | shaping | phase-1 | - | - | 2026-10-29 |
| 2 | Teacher uploads and approves content; student reads, watches, and downloads it for offline use | planned | - | - | - | - |
| 3 | Teacher assigns a lesson-linked practice exercise; student submits (online or offline); auto-grade result shows on the teacher dashboard | planned | - | - | - | - |
| 4 | Student chats with a streaming, scoped, rate-limited AI tutor; every exchange is logged by the server | planned | - | - | - | - |
| 5 | Student takes a timed test with online start, auto-submit, offline survival, late flagging, and the AI tutor locked out | planned | - | - | - | - |
| 6 | Parent reads the linked child's results and full AI transcripts; teacher reviews AI chats of own classes | planned | - | - | - | - |

Status values, in order: planned, shaping, contracting, planning, building, integrating, reviewing, fixing, done.
`blocked` can replace any of them when a deadlock stops the phase; only the user's decision clears it.

## Phase 1: Role-gated sign-in, approved library, and backend round trip (walking skeleton)

- Outcome (demoable): On the `edubox_tablet` AVD talking to the Emulator Suite, a seeded student, teacher, and parent each sign in through a Vietnamese UI and land on their own role home; the student's library lists only approved content for the student's classes; an integration test proves a streaming callable Cloud Function reaches the app.
- Screens: `sign-in`, `account-not-set-up` (signed-in user with no role claim), `student-home`, `student-library`, `teacher-home`, `parent-home` (placeholder showing the linked child's name only)
- Backend capabilities:
  - Account provisioning by the seed/admin script only (no sign-up screen): email/password users, `role` custom claim (`student|teacher|parent`) set through the Admin SDK, each student linked to one parent.
  - Firestore collections `users`, `classes` (with `gradeLevel` and `subjects[]`), `content` (metadata fixtures with `status: draft|approved` and `classIds[]`), all seeded.
  - Firestore security rules for `users`, `classes`, `content`: role read from the custom claim only, never from a client-writable field; student reads only `content` with `status == approved` for one of their classes; teacher reads and writes content and classes they own; parent reads only their own `users` doc (which carries the linked child's UID and name, see Rulings); default deny everywhere else.
  - A minimal streaming callable `pingStream` (authenticated; streams three chunks containing the caller's role claim, then a final result) to prove the Functions emulator to Flutter streaming path before phase 4 depends on it.
  - Rules test suite and emulator harness (`firebase.json`, `demo-edubox`, `emulators:exec`) wired into the test and e2e commands.
  - Flutter app shell: backend config object (emulator host, ports), auth state, role-based routing from the ID-token claim, design tokens seeded from DESIGN.md.
  - Localization scaffolding: `flutter_localizations`, `intl`, `l10n.yaml`, template ARB `app_vi.arb`, `vi` as the only supported and default locale, `intl` date and number formatting in `vi`.
- Exit criteria:
  1. E2E: seeded student signs in and sees exactly the approved fixtures for their classes in `student-library`; the seeded draft fixture and another class's approved fixture are absent.
  2. E2E: seeded teacher signs in and lands on `teacher-home`; seeded parent signs in and lands on `parent-home` showing the linked child's name.
  3. E2E: a seeded user with no role claim lands on `account-not-set-up` showing l10n key `accountNotSetUp` (vi: "Tài khoản chưa được thiết lập") and a sign-out action, never on a role home.
  4. E2E: wrong credentials show l10n key `signInWrongCredentials` (vi: "Email hoặc mật khẩu không đúng"); a dedicated integration test file starts the app with the Auth emulator port set to a closed port and asserts l10n key `backendUnreachable` (vi: "Không kết nối được với EduBox") with a `retry` action (vi: "Thử lại").
  5. E2E: an integration test running on the AVD calls `pingStream` through the `cloud_functions` plugin against the Functions emulator, receives at least two chunks before the final result, and the chunks carry the signed-in user's role.
  6. Rules tests: a student reading a draft content doc, another class's content, or another user's `users` doc is denied; a student writing their own `role` or `classIds` is denied; a teacher writing content or a class they do not own is denied; a parent reading the child's `users` doc or any `classes` doc is denied; unauthenticated access to every collection is denied.
  7. Rules tests: changing the `role` field on a `users` doc does not change what that user can read (rules trust only the custom claim).
  8. Firestore rules coverage report shows at least 80% for phase 1 rules, and every `allow` statement has at least one allowed-case and one denied-case test.
  9. l10n: every user-visible string in `app/lib/` comes from `AppLocalizations`; a test fails on string literals passed to `Text`, semantics labels, hints, or tooltips outside generated l10n code; E2E assertions look strings up with `lookupAppLocalizations(Locale('vi'))` instead of hardcoding text.
  10. `flutter analyze`, functions lint, and all test and e2e commands pass in a clean checkout on a machine with only the listed prerequisites (no real cloud project, no billing).
  11. Flutter accessibility guideline tests (`androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`) pass on every phase 1 screen.
- Depends on: none
- Risks:
  - Custom claims only refresh on ID-token refresh; role routing must force a refresh after sign-in or the user sees the wrong home.
  - The AVD reaching the host Emulator Suite (`10.0.2.2`, cleartext network config for debug) is the first integration that can fail; if `integration_test` cannot drive the emulators reliably, the E2E strategy changes.
  - If streaming callables do not work against the Functions emulator from the Flutter plugin, phase 4 switches to an HTTPS function with server-sent events and manual ID-token verification; finding that here is the point of criterion 5.
  - Display and body fonts chosen from DESIGN.md must cover the full Vietnamese diacritic set; a font without it forces a design change.

## Phase 2: Teacher publishes content, student studies it offline

- Outcome (demoable): A teacher uploads a PDF e-book and a video, approves them for a class, and the student opens the e-book and plays the video, downloads them, then reads the e-book with the app offline.
- Screens: `teacher-content-list`, `teacher-content-upload`, `teacher-content-detail` (preview plus approve action), `student-content-detail` (with download state), `student-ebook-reader`, `student-video-player`
- Backend capabilities:
  - Storage upload paths per teacher and class, with Storage security rules (teacher writes only to own classes with size and MIME limits; student reads only files of approved content in their classes).
  - `contentIngest` Cloud Function (Storage finalize trigger) with the scope fixed in Rulings: validates type (PDF, EPUB, MP4), size, and readability; normalizes metadata (MIME, size, page count or duration); writes or updates the `content` doc's ingest status (`processing|ready|rejected` plus reason); logs failures server-side.
  - Explicit approval by the owning teacher (`draft` to `approved`), restricted by rules; approved content becomes visible to students through phase 1 rules.
  - Local content cache: downloaded files in the app's file cache, cache index in `sqflite`, Firestore offline persistence for metadata.
  - Network seam: an app-level `NetworkController` whose offline mode calls Firestore `disableNetwork()`, makes Storage, Functions, and AI calls fail fast as offline, and drives every offline UI state; its production source is connectivity events, and tests switch it directly.
  - Named l10n states for upload progress, ingest failure with retry, and download status.
- Exit criteria:
  1. E2E: teacher uploads a fixture PDF and MP4 from `teacher-content-upload`; both reach `ready` in `teacher-content-list`; the teacher approves both; the student then sees both in `student-library`.
  2. E2E: student opens the e-book and `student-ebook-reader` shows page 1 with a page indicator whose total equals the fixture's page count; student opens the video and `student-video-player` reports a duration greater than zero and a playback position that advances.
  3. E2E: student downloads the e-book; with the network seam switched offline, the e-book still opens from cache and `student-content-detail` shows l10n key `contentAvailableOffline` (vi: "Đã tải về máy"); a not-downloaded item shows `contentNeedsInternet` (vi: "Cần kết nối mạng để mở") instead of a spinner.
  4. Functions integration test: uploading a disallowed file type or an oversize file makes `contentIngest` mark the content `rejected` with a reason; widget test: the teacher UI shows that reason with a replace action; rules test: rejected content is never readable by students.
  5. Rules tests (Firestore): student cannot write `content`; teacher cannot approve another teacher's content; a client cannot set ingest status or normalized metadata fields that only `contentIngest` may set.
  6. Storage rules test matrix: every `allow` condition in the Storage rules has at least one allowed-case and one denied-case test, including student upload denied, student read of a draft content file denied, teacher upload to another teacher's class denied, and oversize or wrong-MIME upload denied.
  7. E2E: an upload started while the network seam is offline shows l10n key `uploadFailed` (vi: "Tải lên thất bại") with a `retry` action, and retry after switching online completes the upload.
  8. Unit and widget tests cover the cache index (download, evict, lookup), the network seam, and the offline and online content states; Flutter accessibility guideline tests pass on every phase 2 screen.
- Depends on: Phase 1
- Risks:
  - EPUB rendering in Flutter is less mature than PDF; may force a DECISION to ship PDF-only in phase 2 and EPUB later.
  - Large video files on the Storage emulator and tablet storage; cache size limits and eviction policy may need a contract change.
  - The network seam simulates offline inside the app; real radio loss is covered only through the seam's connectivity-event source (unit-tested), not by E2E.

## Phase 3: Lesson-linked practice assignments with auto-grading (core learning loop)

- Outcome (demoable): A teacher writes an MCQ exercise linked to a lesson and assigns it to a class as practice; the student reads the lesson, marks it complete, completes the exercise, and sees a score; the teacher sees that score on the results dashboard, even when the student submitted offline and synced later.
- Screens: `teacher-exercise-editor` (MCQ questions, optional question images, answer key, linked lesson), `teacher-assignment-editor` (practice type, class, exercise, due date), `teacher-results-dashboard`, `student-assignments`, `student-lesson-and-exercise` (lesson link, mark complete, start exercise), `student-exercise`, `student-exercise-result`
- Backend capabilities:
  - Exercise content (`type: exercise`) holding question stems and options plus optional `lessonContentId` pointing to an approved e-book or video; question images stored in Storage as exercise assets; answer keys in a separate teacher-only store readable by `autoGrade`.
  - Collections `assignments`, `submissions`, `progress` (lesson completion: `studentUid`, `contentId`, `status`, `updatedAt`).
  - Assignments rules: teacher creates, updates, and deletes assignments only for classes they own; student reads assignments only for their own classes; students and parents never write assignments.
  - Submissions and progress rules: student creates and updates only their own submission and only answer fields, and only for assignments of their classes; score, grading, and status-after-submit fields are server-only; teacher reads submissions of their own classes; student writes only their own progress.
  - `autoGrade` Cloud Function (Firestore trigger when a submission's status becomes `submitted`): scores MCQ/objective items against the answer key, writes `score`, `gradedAt`, `gradedBy: auto`, `status: graded`, and denormalizes assignment title, type, and max score onto the submission; grading errors set `status: grading_failed`, are logged, and can be retried by the teacher.
  - Offline exercises: opening an assignment downloads the exercise doc and its question images into the content cache; the offline submission queue is Firestore's on-disk offline persistence, and the pending-sync indicator reads snapshot pending-write metadata.
- Exit criteria:
  1. E2E (spec flow 1): student opens an assignment, opens its linked e-book lesson from `student-lesson-and-exercise`, marks it complete (a `progress` doc appears), completes the exercise, submits, and sees the auto-graded score on `student-exercise-result`.
  2. E2E (spec flow 2): teacher creates an exercise and a practice assignment for a class; after the seeded student submits, the teacher sees that student's score and status `statusGraded` (vi: "Đã chấm") on `teacher-results-dashboard`.
  3. E2E: student opens an exercise online, then with the network seam offline completes and submits it; `student-assignments` shows l10n key `submissionPendingSync` (vi: "Bài nộp đang chờ đồng bộ"); the test then calls Firestore `terminate()`, re-creates the app root (in-process restart that reloads from the on-disk cache), switches the seam online, and the submission syncs, is graded, and the status changes to `statusGraded`.
  4. E2E: an exercise never opened online shows `contentNeedsInternet` while offline; an exercise with question images opened online renders its images while offline.
  5. Functions integration test: when grading fails (for example a missing answer key), the submission gets `grading_failed`, the failure is logged, the teacher sees `statusGradingFailed` (vi: "Chưa chấm được") with a `retry` action, the student sees `statusSubmittedAwaitingGrade` (vi: "Đã nộp, đang chờ chấm"), and retry produces a score.
  6. Unit tests: grading covers all-correct, all-wrong, partial, unanswered items, single-select vs multi-select, duplicate submission, and answer-key edits after submission; grading logic coverage is at least 80%.
  7. Rules tests (submissions, answer keys, progress): student cannot write `score`, `gradedAt`, `gradedBy`, or `status: graded`; student cannot read another student's submission or any answer key; student cannot submit to an assignment of a class they are not in; teacher cannot read submissions outside their classes.
  8. Rules tests (assignments): teacher creating or editing an assignment for another teacher's class is denied; student reading an assignment of another class is denied; any student or parent write to `assignments` is denied; student reading an assignment of their own class is allowed.
  9. Firestore rules coverage stays at least 80% with the new collections; Flutter accessibility guideline tests pass on every phase 3 screen; every status is shown as an l10n word, not color or icon alone.
- Depends on: Phase 2
- Risks:
  - A Firestore trigger grading a submission that syncs late can race with answer-key edits; the contract must fix which key version grades.
  - Answer-key isolation is a security boundary; a wrong model leaks answers to students.
  - The in-process restart (Firestore `terminate()` plus root re-create) approximates a process kill; if it proves unrepresentative, the harness needs an adb-driven relaunch.

## Phase 4: AI study tutor through aiProxy

- Outcome (demoable): A student opens the AI tutor for one of their class subjects, asks a study question in Vietnamese, and watches the answer stream in; an off-topic or out-of-scope request is declined; after the daily limit the tutor says so; offline the tutor shows that it needs internet; every exchange appears in `aiChats`, written by the server.
- Screens: `student-ai-tutor` (subject picker from the student's class subjects, conversation list of past chats, streaming chat, named states: needs internet, daily limit reached, error with retry)
- Backend capabilities:
  - `aiProxy` Cloud Function (authenticated, student role only) that: builds the system prompt from the requested subject and the class's `gradeLevel` (study help only, no off-topic chat, refuses to solve test questions, age-appropriate tone, replies in Vietnamese); rejects subjects not in the `subjects[]` of the student's classes (topic allowlist); enforces the per-student daily limit with a transactional Firestore counter (function param, default 30 per day, day boundary Asia/Ho_Chi_Minh); reads the OpenRouter model ID from a function param and the key from a function secret; streams the response; logs the exchange to `aiChats`.
  - OpenRouter client behind an interface; the mock is used in all tests and by default in the emulator; a real key in `functions/.secret.local` (git-ignored) switches the local emulator to real OpenRouter.
  - Rules: `aiChats` and rate-limit counters are never client-writable; student reads only their own `aiChats`; teacher reads `aiChats` of students in their own classes.
- Exit criteria:
  1. E2E: student picks a subject and sends a question in `student-ai-tutor`; the mocked response renders incrementally (at least two chunks observed before completion); after leaving and reopening the screen, the chat appears in the conversation list and opens with both messages.
  2. Functions integration test: the request sent to the mocked OpenRouter contains a system prompt naming the student's subject and class grade level and uses the model ID from the function param; changing the param changes the model with no client change.
  3. Functions integration test: a request for a subject outside the student's classes' `subjects[]` is rejected with a named error and nothing is sent to OpenRouter.
  4. Functions integration test: the 31st message in one Asia/Ho_Chi_Minh day is rejected with a named limit error (UI: `aiDailyLimitReached`, vi: "Bạn đã dùng hết lượt hỏi hôm nay"); the counter resets at local midnight (tested with an injected clock across 23:59 to 00:00 ICT); concurrent requests never exceed the limit; rate-limit logic coverage is at least 80%.
  5. Functions integration test: every successful exchange writes the `aiChats` entry with student UID, subject, both messages, and timestamp; a failed or cut-off exchange is logged server-side, and whether it counts against the limit is fixed by the contract and asserted by a test.
  6. E2E: with the network seam offline, `student-ai-tutor` shows `aiTutorNeedsInternet` (vi: "Gia sư AI cần kết nối mạng") and sending is disabled; with the mock forced to time out, the UI shows `aiTutorError` with a `retry` action, and retry succeeds.
  7. Rules tests: a student cannot create, update, or delete any `aiChats` doc or rate-limit counter; a student cannot read another student's `aiChats`; a teacher can read `aiChats` of a student in their class and cannot read one outside their classes.
  8. Functions integration test: a teacher or parent calling `aiProxy` is rejected with a named permission error.
  9. Static check: the built APK and the Flutter source contain no OpenRouter key or OpenRouter URL; `functions/.secret.local` is listed in `.gitignore`.
- Depends on: Phase 1 (classes with `gradeLevel` and `subjects[]`, streaming path proven); scheduled after Phase 3 by order only.
- Risks:
  - Logging after a stream is cut mid-way (partial answers) needs a contract rule.
  - Model answers in Vietnamese for young students vary by model; the mock cannot test quality (spec open risk).

## Phase 5: Timed test room with online start, auto-submit, and AI lockout

- Outcome (demoable): A teacher creates a short MCQ test; the student starts it online, the AI tutor shows it is paused, the timer runs out, and the test auto-submits and is graded; a second run with the network cut mid-test keeps saving answers, shows pending sync, and auto-submits on reconnect; a submission arriving after the grace window is graded and flagged late.
- Screens: `teacher-assignment-editor` (extended with test type, time limit, question set), `student-test-lobby` (rules, time limit, start action, online-required state), `student-test-room` (questions, local countdown, submit), `student-test-submitted` (submitted, pending sync, graded, or late status), plus the paused state in `student-ai-tutor`
- Backend capabilities:
  - Assignment field `timeLimitSec` for tests; submission lifecycle `in_progress|submitted|graded|grading_failed` with server `startedAt` and server `submittedAt`.
  - `startTest` callable: requires connectivity by design, checks enrollment and that no other test is in progress, creates the `in_progress` submission with server `startedAt`; rules forbid clients from creating `in_progress` test submissions directly.
  - Local timer derived from `startedAt` (not a running counter), with auto-submit on expiry, surviving backgrounding and in-process restart; answers saved incrementally to the in-progress submission through Firestore offline persistence; auto-submit on reconnect.
  - Late flag: rules require `submittedAt == request.time` (server commit time, so an offline-queued submit is timed when it reaches the server); grading marks `late: true` when `submittedAt` is after `startedAt + timeLimitSec + grace` (grace is a function param); late submissions are accepted, never rejected.
  - `aiProxy` test-mode lockout: rejects every request while the student has an `in_progress` test submission, so no `aiChats` entry can be written during a test.
- Exit criteria:
  1. E2E (spec flow 3): student starts a seeded short test, answers some items, and lets the timer expire; the test auto-submits with no user action, `student-test-submitted` shows the graded score, and the teacher dashboard shows the result.
  2. E2E: with the network seam offline, `student-test-lobby` shows `testNeedsInternetToStart` (vi: "Cần kết nối mạng để bắt đầu bài kiểm tra") and the start action is disabled.
  3. E2E: while a test is in progress, `student-ai-tutor` shows `aiTutorPausedDuringTest` (vi: "Gia sư AI tạm dừng trong lúc làm bài kiểm tra"); functions integration test: a direct `aiProxy` call for that student is rejected and no `aiChats` doc is written; after submission the tutor works again.
  4. E2E: the network seam goes offline mid-test; answers keep saving; on expiry the screen shows `submissionPendingSync`; after switching online the submission syncs automatically, is graded, and the status changes to `statusGraded`.
  5. E2E: during a test the app performs the in-process restart (Firestore `terminate()` plus root re-create); the student returns to `student-test-room` with saved answers and remaining time computed from `startedAt`; when the injected clock is already past expiry, the test auto-submits on re-create.
  6. Functions integration test: a submission whose server `submittedAt` is after `startedAt + timeLimitSec + grace` is graded and carries `late: true`, and the teacher dashboard shows `statusLate` (vi: "Nộp muộn"); one inside the window carries `late: false`.
  7. Rules and functions tests: a student cannot create an `in_progress` test submission without `startTest`, cannot change `startedAt`, `submittedAt`, or `timeLimitSec`, cannot reopen a submitted test, and cannot hold two in-progress tests.
  8. Unit tests: timer logic (remaining time, expiry, clock-skew bounds) and the lockout check; combined grading, rate-limit, and lockout coverage is at least 80%; Flutter accessibility guideline tests pass on every phase 5 screen, and the countdown is announced to screen readers at fixed intervals, not every second.
- Depends on: Phase 3 (submissions, autoGrade, offline queue), Phase 4 (aiProxy)
- Risks:
  - Timed tests with real timers are slow and flaky; the contract must define an injectable clock for app and functions.
  - The local timer can be gamed on-device; the server-side late flag is the only backstop, by the user's decision.

## Phase 6: Parent summary, teacher AI chat review, and release gate

- Outcome (demoable): A parent signs in and reads the linked child's assignment and test results and full AI tutor transcripts, with no way to change anything; a teacher reviews the AI chat log of a student in their class; the full suite (three spec E2E flows, rules, functions) passes in one run with coverage gates met.
- Screens: `parent-summary` (replaces the phase 1 placeholder), `parent-ai-chat-log`, `teacher-ai-chat-review`
- Backend capabilities:
  - Rules: parent reads only the linked child's `submissions` and full `aiChats` transcripts (exactly the spec's parent scope; the link is checked against the student's `linkedParentUid`); no parent writes anywhere; teacher `aiChats` read for own classes is already in place from phase 4.
  - Parent summary shows results from the denormalized assignment title, type, score, and status on each submission, so the parent needs no access to `assignments` or `content`.
  - Release hardening: one e2e run executes all three spec E2E flows plus every earlier phase's E2E tests; the coverage report for grading, rate-limit, lockout, and Firestore rules is checked against the 80% threshold.
- Exit criteria:
  1. E2E: seeded parent sees the child's practice and test results on `parent-summary`, each with title, score, and an l10n status word (submitted, pending, graded, late); opening `parent-ai-chat-log` shows the child's chats by subject and date, and each opens as a full read-only transcript.
  2. E2E: `parent-summary` and `parent-ai-chat-log` offer no create, edit, or delete action; rules tests confirm every parent write to every collection is denied.
  3. Rules tests: parent cannot read an unlinked student's submissions or aiChats, and cannot read `assignments`, `content`, `progress`, or `classes`.
  4. E2E: teacher opens `teacher-ai-chat-review` for a student in their class and sees that student's logged chats as read-only transcripts.
  5. Full suite: the e2e command runs spec flows 1, 2, and 3 green in one run on fresh emulator state, three consecutive times with no flake.
  6. Coverage: grading, rate-limit, lockout, and Firestore security-rules logic each report at least 80%; every Storage rules `allow` condition has an allowed and a denied test; the report is saved under `docs/build/phase-6/evidence/`.
  7. Flutter accessibility guideline tests pass on every screen in the app, and the literal-string l10n test passes for all of `app/lib/`.
- Depends on: Phase 3, Phase 4, Phase 5
- Risks:
  - The parent feature set is a stub by design; requests for notifications, detailed reports, or lesson progress are out of scope and need their own brainstorming pass.

## Carried items

- None yet.

## Rulings and decisions

- 2026-10-29 User decision: toolchain -> the user installs Flutter, JDK, Android SDK, and the Firebase CLI; the pipeline does not install them.
- 2026-10-29 User decision: backend environment -> emulator-only project `demo-edubox`, no real cloud project, no billing; OpenRouter mocked, with an optional real key in git-ignored `functions/.secret.local`.
- 2026-10-29 User decision: git -> commit on `phase-N` branches; merge to `master` after a passed gate.
- 2026-10-29 User decision: UI language -> Vietnamese, built on Flutter l10n (ARB) so more languages can be added later.
- 2026-10-29 User decision: provisioning -> seed/admin script creates email/password accounts, sets the role claim, and links each student to one parent; no sign-up screen.
- 2026-10-29 User decision: content approval and scope -> `content` has `status: draft|approved` and `classIds[]`; the owning teacher approves explicitly.
- 2026-10-29 User decision: AI scope data -> `classes` has `gradeLevel` and `subjects[]`, seeded from phase 1; these drive the topic allowlist and system prompt.
- 2026-10-29 User decision: AI chat logs -> `aiChats` is written only by `aiProxy`; teachers read chats of their own classes; parents read full transcripts of their linked child.
- 2026-10-29 User decision: AI limit -> default 30 messages per day per student, day boundary Asia/Ho_Chi_Minh, set as a function param.
- 2026-10-29 User decision: tests -> starting a test requires connectivity (server `startedAt`); losing connectivity mid-test is fine; late submissions are accepted and flagged late (after `startedAt` + time limit + grace).
- 2026-10-29 User decision: roadmap (K2) -> approved as written, 6 phases.
- 2026-10-29 User decision: contentIngest scope -> validation plus metadata normalization only, no transcoding.
- 2026-10-29 User decision: parent view -> results and full AI transcripts only, no lesson-completion progress.
- 2026-10-29 User decision: design direction (K3) -> approved docs/design/app-direction.md: achromatic-ledger, accent ink-blue #1F4C8F, Bitter / Be Vietnam Pro / IBM Plex Mono bundled offline.
- 2026-10-29 Ruling: PRODUCT.md and the DESIGN.md seed were already approved, so K3 skipped the impeccable interviews.
- 2026-10-29 Ruling: riskiest integrations first - phase 1 proves custom-claim roles, Firestore rules, l10n, and a streaming callable against the emulators end to end before feature work - cost if wrong: late discovery that E2E or streaming against the emulators is unreliable invalidates later exit criteria.
- 2026-10-29 Ruling: `contentIngest` scope is validation (type, size, readability) plus metadata normalization (MIME, size, page count or duration); it does no transcoding or format conversion, which narrows the spec's "validates/transforms" for the prototype - confirmed by the user.
- 2026-10-29 Ruling: E2E harness - offline is simulated through the app's `NetworkController` seam (Firestore `disableNetwork()` plus fail-fast for Storage, Functions, and AI); app restart is simulated in-process with Firestore `terminate()` and a re-created app root; an unreachable backend is simulated by a test file that points Auth at a closed port; nothing stops an emulator inside `emulators:exec` - cost if wrong: an adb-driven relaunch and airplane-mode harness would be needed.
- 2026-10-29 Ruling: Firestore rules are gated by the emulator's rule-coverage report (at least 80%) plus an allowed and a denied test per `allow` statement; Storage rules, which have no coverage report, are gated by an allowed and a denied test per `allow` condition - cost if wrong: none; it is stricter than a single metric.
- 2026-10-29 ASSUMPTION: role lives only in the Auth custom claim; the `users.role` field is a display mirror that rules never trust - why: a client-editable role would be a privilege-escalation hole - cost if wrong: none.
- 2026-10-29 ASSUMPTION: the seed script also writes `linkedStudentUid` and `linkedStudentName` on the parent's own `users` doc, so `parent-home` needs no read access to the child's `users` doc and the parent's read scope stays exactly the spec's (`submissions` and `aiChats`) - why: Firestore rules cannot project fields, and granting the child's `users` doc would expose more than the spec allows - cost if wrong: small schema change.
- 2026-10-29 ASSUMPTION: exercise questions live on the exercise content (stems and options only), answer keys live in a separate teacher-only store readable by `autoGrade`, and question images are Storage exercise assets - why: the spec has no question model and students must never read answers - cost if wrong: phase 3 data model rework.
- 2026-10-29 ASSUMPTION: a "lesson" is an e-book or video content item; an exercise links to its lesson through an optional `lessonContentId`; completing a lesson writes a `progress` doc (`studentUid`, `contentId`, `status`, `updatedAt`) - why: spec flow 1 needs a lesson-to-exercise link and a completion record the data model lacks - cost if wrong: flow 1 and the phase 3 screens change.
- 2026-10-29 ASSUMPTION: submissions get `status` (`in_progress|submitted|graded|grading_failed`), `startedAt`, `submittedAt`, `late`, and denormalized assignment title, type, and max score; assignments get `timeLimitSec` for tests; the late grace is a function param (default 60 seconds) - why: the lockout, timed tests, late flag, and parent summary need fields the data model lacks - cost if wrong: phase 3 and 5 contracts change.
- 2026-10-29 ASSUMPTION: the offline submission queue is Firestore's on-disk offline persistence, and the pending-sync indicator reads snapshot pending-write metadata; `sqflite` plus the file cache hold downloaded content and exercises only - why: it avoids a second hand-built queue that could diverge from Firestore - cost if wrong: phase 3 adds a custom `sqflite` queue.
- 2026-10-29 ASSUMPTION: `autoGrade` is a Firestore trigger on a submission's status becoming `submitted`, and a test starts through a `startTest` callable - why: offline-queued submissions grade automatically when they sync, and a callable makes "online to start" explicit and records server `startedAt` - cost if wrong: phase 3 and 5 contracts change.
- 2026-10-29 ASSUMPTION: the system prompt keeps a general "do not solve test questions" instruction, but the spec's per-question "flagged test-mode questions" mechanism is dropped; the full tutor lockout during an active test covers it - why: the spec defines no flagging mechanism - cost if wrong: phase 4 adds a teacher-flagged question list.
- 2026-10-29 ASSUMPTION: the optional Firebase Hosting teacher web console, the dictionary (in PRODUCT.md, absent from the spec), kiosk mode, and short-answer grading are out of scope for this roadmap - why: the spec marks them optional or non-goals, or does not specify them - cost if wrong: an extra phase.
- 2026-10-29 ASSUMPTION: every phase's exit includes Flutter accessibility guideline tests on its new screens, and every status is shown as an l10n word - why: PRODUCT.md requires WCAG 2.1 AA and DESIGN.md's Named State Rule - cost if wrong: none.
- 2026-10-29 ASSUMPTION: Vietnamese strings quoted in exit criteria are proposed copy; the l10n key is the contract, and the final text lives in `app_vi.arb` - why: copy can be refined without changing tests, because tests look strings up by key - cost if wrong: none.

## Lessons

- None yet.
