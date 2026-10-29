# Phase 1 contract (P2)

Spec: `docs/superpowers/specs/2026-10-29-edubox-phase1-prototype-design.md`.
Roadmap: `docs/build/roadmap.md` (Phase 1, its 17 exit criteria, Carried items,
Rulings and User decisions).
Branch: `phase-1`; this contract continues commit
`694427d wip: phase 1 contract (server side, handed over to opencode)`.
Screens: the six confirmed briefs in `docs/design/shapes/`; visual direction in
`docs/design/app-direction.md`.

This document is the interface between the backend track and the frontend
track. Either track can build and test against it without the other. The screen
briefs remain the source for screen behaviour; this contract fixes the data,
error, cache, fixture and localization seams the screens consume.

## 1. Frozen seams

The contract owns these shapes. A track may implement or fix behaviour behind
them, but changing a DTO field, enum value, exception reason, repository
signature, ARB key, fixture key, or CI command is a contract change:

- Server models, enums, exceptions, table definitions and migrations:
  `edubox_server/lib/src/models/**`, `edubox_server/migrations/**`.
- Generated server/client protocol (never edited by hand):
  `edubox_server/lib/src/generated/**`,
  `edubox_server/test/integration/test_tools/**`,
  `edubox_client/lib/src/protocol/**`.
- Authorization guard and role parsing:
  `edubox_server/lib/src/authz/**`.
- Endpoint method signatures and doc comments:
  `edubox_server/lib/src/profile/**`,
  `edubox_server/lib/src/classes/**`,
  `edubox_server/lib/src/content/**`,
  `edubox_server/lib/src/diagnostics/**`,
  `edubox_server/lib/src/auth/email_idp_endpoint.dart`,
  `edubox_server/lib/src/auth/jwt_refresh_endpoint.dart`.
- Shared fixtures: `edubox_fixtures/**`.
- App contract types, repository interfaces, fake and cache schema:
  `edubox_flutter/lib/src/contract/**`,
  `edubox_flutter/lib/src/fake/**`,
  `edubox_flutter/lib/src/local/local_store.dart` and its generated
  `local_store.g.dart`.
- Localization: `edubox_flutter/lib/l10n/app_vi.arb`,
  `edubox_flutter/lib/l10n/generated/**`, `edubox_flutter/l10n.yaml`.
- Stack and CI: `compose.yaml`, `tool/bootstrap.sh`,
  `tool/coverage_gate.dart`, `.github/workflows/ci.yml`, the root pub
  workspace manifests and `pubspec.lock`.
- This document.

## 2. Server contract

### 2.1 Models and migration

Serverpod 4.0.4, PostgreSQL, no Redis. The first migration is
`edubox_server/migrations/20261029133845455/` and is applied by the compose
`server` service with `--apply-migrations`.

| Table | Fields (contract-relevant) |
| --- | --- |
| `users` | `id`, `authUserId` -> `serverpod_auth_core_user`, raw nullable `role` text, `name`, `email`, nullable `linkedStudentId` -> `users`, nullable `linkedStudentName` |
| `classes` | `id`, `teacherId` -> `users`, `name`, `gradeLevel` (int) |
| `class_subjects` | `classId`, `position`, `subject`; `position` preserves the teacher's order |
| `class_members` | `classId`, `studentId`, unique pair |
| `content` | `id`, `ownerTeacherId`, `type` (`ebook|video|exercise`), `subject`, `gradeLevel`, `title`, nullable `storagePath` (phase 2), `status` (`draft|approved`), nullable `approvedBy`, `createdAt` |
| `content_classes` | `contentId`, `classId`, unique pair (the content's class scope) |

`users.role` is deliberately raw text, not a database enum: a null, empty or
unknown stored value must be representable and must resolve to `notSetUp`
instead of a deserialization error.

DTOs and enums: `ProfileResult`, `Profile`, `ClassSummary`, `StudentClass`,
`StudentLibrary`, `LibraryItem`, `PingMessage`, `UserRole`, `ProfileStatus`,
`ContentType`, `ContentStatus`, `AccessDeniedReason`, `AccessDeniedException`.
All are generated into both the server and `edubox_client`.

### 2.2 Endpoints, DTOs and typed failures

| Endpoint method | Auth | Returns | Failure surface |
| --- | --- | --- | --- |
| `emailIdp.login` | unauthenticated exception | `AuthSuccess` (auth module) | `EmailAccountLoginException(reason: invalidCredentials|tooManyAttempts|unknown)`, `AuthUserBlockedException` |
| `jwtRefresh.refreshAccessToken` | unauthenticated exception (needs a refresh token) | `AuthSuccess` | module refresh exceptions |
| `profile.me` | any authenticated caller | `ProfileResult` (`ready` or `notSetUp`) | `NotAuthorizedException` when unauthenticated; never an error for `notSetUp` |
| `classes.mine` | teacher | `List<ClassSummary>` | `AccessDeniedException(reason: notSetUp|wrongRole)`, `NotAuthorizedException` |
| `content.library` | student | `StudentLibrary` | `AccessDeniedException(reason: notSetUp|wrongRole)`, `NotAuthorizedException` |
| `diagnostics.pingStream` | student, teacher, parent | `Stream<PingMessage>` (3, then close) | `AccessDeniedException(reason: notSetUp|wrongRole)`, `NotAuthorizedException` |

`emailIdp.login` is a hand-written endpoint that does **not** extend
`EmailIdpBaseEndpoint`. The generated client therefore has no
`startRegistration`, registration verification/finish, password-reset,
`hasAccount`, or account-request call at all. The module's base methods are
tested through the real dispatch path and must remain uncallable
(`MethodNotFoundException`) while creating no auth user and no `users` row.
`jwtRefresh` is the only other unauthenticated call with a valid refresh token.

`profile.me` resolves the caller's `users` row by `authUserId` on every call.
It returns `ProfileStatus.notSetUp` with `signedInEmail` when the caller has no
`users` row, a null role, or an unparseable role. It never returns another
user's profile, and it never answers `notSetUp` with a server error.

`content.library` reads the caller's `class_members` rows, then returns only
`content.status == approved` rows scoped through `content_classes` to at least
one of those classes, newest first. Draft content, another class's content and
another teacher's class are never joined into the result.

### 2.3 Authorization guard and matrix

`EduboxEndpoint.requireLogin` is `true`, so Serverpod rejects an
unauthenticated call before EduBox code runs. Inside each method, `requireCaller`
or `requireRole` reads `users` from the session on every call and throws
`AccessDeniedException` with:

- `unauthenticated`: no session (second line of defence),
- `notSetUp`: no `users` row, null role, empty role, or an unknown role,
- `wrongRole`: the parsed role is not in the method's allowed set.

No role is cached in the session; a role change applies to the caller's next
call without signing in again (exit criterion 13).

The matrix lives in
`edubox_server/test/integration/authorization/authorization_matrix.dart` and is
checked by `authorization_matrix_test.dart`:

- `eduboxMethodMatrix`: every EduBox method, its allowed callers and its
  invoker. Every other `MatrixCaller` (student, teacher, parent, no profile,
  null role, anonymous) must be denied.
- `moduleUnauthenticatedExceptions`: `emailIdp.login`,
  `jwtRefresh.refreshAccessToken`, `serverpod_auth_core.status.isSignedIn`,
  `.signOutDevice`, `.signOutAllDevices`, each with a test.
- `frameworkUnauthenticatedExceptions`: the three Serverpod
  `serverpod_cloud_storage` raw routes, each tested over real HTTP.
- `moduleDeniedUnauthenticated`: `serverpod_auth_core.userProfileInfo.get`.

The check reads the live dispatch table, so a generated endpoint method that
appears in no list fails the suite. It also fails on duplicate rows and on rows
for methods the server no longer dispatches. Every EduBox method is denied for
the anonymous caller both directly and through the HTTP dispatch path.

### 2.4 Error shapes and the shape-brief states

| Shape-brief state | Server / transport signal | App error | l10n key |
| --- | --- | --- | --- |
| Wrong credentials (email unknown or password wrong) | `EmailAccountLoginException(invalidCredentials)` | `WrongCredentialsError` | `signInWrongCredentials` |
| Too many attempts | `EmailAccountLoginException(tooManyAttempts)` after the module's 5 attempts / 5 minutes | `TooManyAttemptsError` | `signInTooManyAttempts` |
| Account disabled | `AuthUserBlockedException` | `AccountDisabledError` | `signInAccountDisabled` |
| Unexpected auth failure | `EmailAccountLoginException(unknown)` or any other auth exception | `UnexpectedBackendError` | `signInUnknownError` |
| Server unreachable | socket failure, client timeout, closed port | `BackendUnreachableError` | `backendUnreachable` + `backendUnreachableHint`, `retry` |
| Not set up | `ProfileResult(status: notSetUp)`, or `AccessDeniedException(notSetUp)` | `NotSetUpError` / `AuthSession.isNotSetUp` | `accountNotSetUp` |
| Permission denied | `AccessDeniedException(wrongRole)` | `PermissionDeniedError` | no dedicated copy; route guards should prevent it, otherwise show the screen's load-error key with `retry` |
| Unauthenticated | `NotAuthorizedException`, or `AccessDeniedException(unauthenticated)` at the guard | `PermissionDeniedError` | route to `sign-in`; no screen state |
| Offline with no cache | local store has no snapshot | `OfflineNoCacheError` | `studentHomeLibraryOfflineNoCache`, `libraryOfflineNoData`, `teacherClassesOfflineNoData`, `parentHomeOfflineNoData` |
| Offline with cache | local store snapshot present | data + `networkOffline` strip | `networkOffline` / `networkOfflineStale` |
| Unknown data failure | anything else | `UnexpectedBackendError` | the screen's load-error key + `retry` |

Carried-item decision: **both** `signInTooManyAttempts` and
`signInAccountDisabled` are kept and mapped. Serverpod 4.0.4 does provide the
signals (`EmailAccountLoginException.tooManyAttempts` and
`AuthUserBlockedException`), so dropping them would lose real states. The UI
copy is the brief's proposed copy; the keys are the contract.

`BackendError` is the app-side sealed hierarchy in
`edubox_flutter/lib/src/contract/backend_result.dart`. Repositories return
`BackendResult<T>` (`BackendOk` / `BackendFailure`), never throw a
`BackendError`. A stream throws `BackendException(error)` because a stream
cannot return a result per event.

### 2.5 Implemented now versus backend-track stubs

Implemented and tested now:

- Auth services (email identity provider only; JWT refresh; no registration,
  reset, or account requests), `emailIdp.login`, `jwtRefresh`.
- Authorization guard, role parsing, `profile.me`, `classes.mine`,
  `content.library`, `diagnostics.pingStream`.
- Fixture loader, phase 1 fixtures, migration and database schema.
- Configuration loader, object-store interface, seed-step CLI enum and reset
  table list, database coverage of the authorization module (95.5% line
  coverage; gate passes).
- The authorization matrix, sign-in, profile, classes, library, ping-stream
  and module-endpoint integration suites.

Sign-in tests use `rollbackDatabase: RollbackDatabase.disabled` and seed once
per group: `emailIdp.login` opens its own transaction for the rate limiter,
which the test-tool rollback wrapper cannot nest. The wrong-password and
unknown-email calls are awaited sequentially for the same reason. This is a
test-harness requirement, not a product exception.

Stubs for the backend track, with failing tests marked `backend-pending`:

- `S3ObjectStore` in `edubox_server/lib/src/storage/object_store.dart`: all four
  methods throw `UnimplementedError`. The storage spike lands with
  `serverpod_cloud_storage_s3_compat` against MinIO.
  `test/integration/storage/object_store_test.dart` is tagged
  `backend-pending`; it asserts put, byte-identical get, a working signed URL,
  and a denied unsigned read.
- `runSeedStep` in `edubox_server/lib/src/seed/seed_command.dart` throws
  `UnimplementedError`. `test/integration/seed/seed_command_test.dart` is
  tagged `backend-pending`; it asserts the reset writes accounts, classes and
  content. The `bin/seed` executable and its Dockerfile target are also part of
  this stub; the compose `seed` service entrypoint (`./bin/seed`) stays
  unrunnable until the backend track adds them.
- The production `NetworkController` source (connectivity events plus a server
  reachability probe) is the frontend track's implementation of the contract
  interface; phase 1 ships the seam and a directly switchable test controller.
- Feature repository implementations (the generated-client binding) are the
  frontend track's phase 5 seam.

`dart_test.yaml` skips the `backend-pending` tag with a clear message. Remove
the tag once the implementation lands; the tests then run against real
PostgreSQL/MinIO and must pass without weakening.

### 2.6 Seed command

Interface in `edubox_server/lib/src/seed/seed_command.dart`:

- `SeedStep { reset, reconnectLibrary, reconnectClasses, assignRole }` with
  stable CLI names `reset`, `reconnect-library`, `reconnect-classes`,
  `assign-role`, parsed by `SeedStep.tryParse`.
- `runSeedStep(Session, SeedStep, {required ObjectStore e2eStore})`.
- `reset` truncates every table in `seedResetTables` (EduBox data plus all
  Serverpod auth tables; never the schema or migration bookkeeping), empties
  the e2e bucket through `ObjectStore.deletePrefix`, then loads
  `FixtureSet.phase1()` with credentials for every account.
- `reconnectLibrary` inserts the new approved 7A item; `reconnectClasses`
  inserts class 8B for teacher Lan; `assignRole` sets the null-role fixture's
  role to `student`. These back exit criterion 7 and the account-not-set-up
  check-again coverage.
- The seed CLI runs after the compose `server` health check, with the
  development database and e2e bucket.

Committed fixtures (`edubox_fixtures/lib/src/phase1_fixtures.dart`,
`devPassword = 'EduBox-dev-2026'`, dev/test only):

| Fixture | Purpose |
| --- | --- |
| `student_an` (Nguyễn Minh An) | student in 7A; the criterion 1 student |
| `student_ha` (Trần Thu Hà) | student in 7B |
| `student_bao` (Lê Quốc Bảo) | student in teacher Nam's 9A |
| `student_no_class` (Phạm Gia Huy) | student with no class |
| `teacher_lan` (Võ Thị Lan) | teacher of 7A, 7B, 8A |
| `teacher_nam` (Đỗ Văn Nam) | teacher of 9A |
| `parent_binh` (Nguyễn Văn Bình) | parent linked to student An |
| `parent_no_child` (Lý Thanh Thảo) | parent with no linked child |
| `no_profile` | auth user with no `users` row |
| `null_role` (Đặng Hữu Phúc) | `users` row with null role |
| `blocked_student` (Hoàng Thị Mai) | blocked auth user |

Classes: 7A (grade 7; Toán, Ngữ văn, Khoa học tự nhiên; An), 7B (grade 7;
Toán, Tiếng Anh; Hà), 8A (grade 8; empty subjects; no students; Lan's edge
case), 9A (grade 9; Vật lý; Bảo; Nam). Content: six approved items for 7A, the
draft geometry item, the other-class approved video for 9A, and the 7B grammar
item. The library oracle is `FixtureSet.libraryOfStudent`.

### 2.7 Object storage

`ObjectStore` is the frozen interface: `put`, `get`, `signedGetUrl`,
`deletePrefix`. `S3ObjectStore` is the backend-track implementation against
`serverpod_cloud_storage_s3_compat`, path-style addressing, the private bucket
from `StorageConfig`, and a second client configured with `publicEndpoint` for
presigned URLs only. The server reaches MinIO at `minio:9000` in compose and
`localhost:9000` from host tests; the AVD needs `10.0.2.2:9000` in the signed
host. `minio-init` creates the private `edubox-dev`, `edubox-test` and
`edubox-e2e` buckets and denies anonymous access. The interface is implemented
by the backend track; phase 1 tests for it are `backend-pending`.

## 3. App contract

Package: `edubox_flutter` (Flutter 3.47.8 / Dart 3.13.7). Theme tokens are the
frontend track's; this contract does not define colours, fonts or component
styles.

### 3.1 Backend config

`edubox_flutter/lib/src/contract/backend_config.dart`:

- default `http://10.0.2.2:8080` (the Android emulator's host alias),
- `BackendConfig.fromEnvironment()` reads the compile-time
  `EDUBOX_SERVER_URL` define,
- `BackendConfig.fromEnvironment(override: ...)` and
  `BackendConfig(serverUrl: ...)` let tests and integration-test files bypass
  the define.

The closed-port criterion-4 integration test constructs its own
`BackendConfig`; it never edits the default.

### 3.2 Session and role resolution

`AuthSession` carries `signedInEmail` and the server's `ProfileResult`.
`isReady` means `ProfileStatus.ready` with a non-null profile; `role` is the
resolved `UserRole`. `isNotSetUp` is the inverse and routes to
account-not-set-up. A null/unknown stored role is `notSetUp`, never a parse
exception.

`AuthRepository`:

- `signIn(email, password)` -> `BackendResult<AuthSession>`,
- `restoreSession()` -> `BackendResult<AuthSession?>` (`null` = nothing
  stored); it must survive offline when the session manager has a stored
  session,
- `refreshProfile()` for account-not-set-up "check again"; no re-auth,
- `signOut()`.

`ProfileRepository.me()` exposes `profile.me` for callers that need the
current profile. Parent home data is `ParentHomeData { linkedStudentName }`;
the real binding derives it from `profile.me` (phase 1 has no parent endpoint).

### 3.3 Repository interfaces

`edubox_flutter/lib/src/contract/repositories.dart`:

| Interface | Method | Server method |
| --- | --- | --- |
| `AuthRepository` | `signIn`, `restoreSession`, `refreshProfile`, `signOut` | `emailIdp.login`, session manager, `profile.me`, client sign-out |
| `ProfileRepository` | `me` | `profile.me` |
| `ClassesRepository` | `mine` | `classes.mine` |
| `LibraryRepository` | `library` | `content.library` |
| `ParentRepository` | `home` | derived from `profile.me` |
| `DiagnosticsRepository` | `pingStream` | `diagnostics.pingStream` |

`EduBoxBackend` aggregates the six getters and `dispose()`. It is the single
seam: screens take `EduBoxBackend`, tests take `EduBoxBackend`, and the phase 5
server binding implements it.

### 3.4 Local store (drift) and outbox

`edubox_flutter/lib/src/local/local_store.dart` (schema version 1) owns:

| Table | Purpose |
| --- | --- |
| `cached_snapshots` | `kind` + `cachedAt`; distinguishes a cached empty snapshot from "never cached" |
| `cached_profiles` | signed-in email, profile status, role, name, email, linked child |
| `cached_classes` | teacher-home `ClassSummary` rows in order |
| `cached_library_classes`, `cached_library_items` | student library classes and items in order |
| `cached_parent_homes` | linked child name (may be null) |
| `outbox_entries` | operation, JSON payload, createdAt, state, attempts, lastError |

`CachedDataStore` saves/reads each snapshot; `clearAll` wipes the store on
sign-out. `Outbox` (in `lib/src/contract/outbox.dart`) is the interface;
`DriftOutbox` implements enqueue, ordered `pending`, `all`, `markSent`,
`markFailed` (permanent failure, attempts + 1), and `retry`. Phase 1 writes no
outbox rows; phase 3 uses this shape for progress and submissions.

### 3.5 Network seam

`NetworkController` (in `lib/src/contract/network_controller.dart`) implements
`Listenable` and exposes `NetworkStatus { online, offline, reconnecting }`,
`isOnline`, and a `changes` stream. `ManualNetworkController` is the
directly switchable implementation for tests and previews. The production
source combines connectivity events with a reachability probe; probe failures
must surface as offline, never as uncaught errors. The shell's strip and every
offline state read this one seam.

### 3.6 Fake backend

`edubox_flutter/lib/src/fake/fake_backend.dart` implements `EduBoxBackend` from
`edubox_fixtures`, so the frontend can build every screen state without the
server:

- `FakeMode.online`: normal fixture answers, role checks enforced.
- `FakeMode.offlineWithCache`: role homes still return their fixture-backed
  data; sign-in and ping are `backendUnreachable` (sign-in needs the server).
- `FakeMode.offlineWithoutCache`: `profile.me`, classes, library and parent
  home return `OfflineNoCacheError`; ping throws
  `BackendException(BackendUnreachableError)`.
- Per-call switches: `signInError`, `restoreError`, `profileError`,
  `classesError`, `libraryError`, `parentError`, `pingError`, `signOutError`,
  covering wrong credentials, too many attempts, account disabled, unreachable,
  not-set-up, permission denied, offline-no-cache and unexpected.
- `signInAs(key)` for previews and `setRole(key, role)` to simulate an admin
  fix; `clearFailures()` resets the switches.
- The blocked fixture returns `AccountDisabledError`; unknown email and wrong
  password both return `WrongCredentialsError`.

### 3.7 Contract tests and the real-server seam

- `edubox_flutter/test/contract/contract_suite.dart` defines
  `runBackendContractTests({name, createBackend})`.
- `backend_contract_test.dart` runs it against `FakeBackend` now.
- Phase 5 adds `server_backend_contract_test.dart` that imports the same
  function and passes the generated-client implementation of `EduBoxBackend`.
  No screen or contract test changes when that happens.
- Fake-specific failure/offline tests are in `fake_backend_test.dart`; drift
  round-trip and outbox tests are in `test/local/local_store_test.dart`.

### 3.8 Localization

Vietnamese (`vi`) is the only supported and default locale, ARB-based:
`edubox_flutter/lib/l10n/app_vi.arb` is the template, `l10n.yaml` sets
`app_vi.arb`, `AppLocalizations` is generated under `lib/l10n/generated`, and
`MaterialApp` uses `AppLocalizations.delegates` and `supportedLocales`.

The final phase 1 key list (98 keys). Shared keys appear once; `signingOut` is
resolved to `signOutBusy`, and `eduboxMarkSemantics` is resolved to
`appMarkSemantics`.

| Key | Vietnamese |
| --- | --- |
| `appName` | EduBox |
| `appOpening` | Đang mở EduBox… |
| `appMarkSemantics` | EduBox |
| `signInTitle` | Đăng nhập |
| `emailLabel` | Email |
| `passwordLabel` | Mật khẩu |
| `signInButton` | Đăng nhập |
| `signInSubmitting` | Đang đăng nhập… |
| `showPassword` | Hiện mật khẩu |
| `hidePassword` | Ẩn mật khẩu |
| `emailRequired` | Vui lòng nhập email |
| `emailInvalid` | Email chưa đúng định dạng |
| `passwordRequired` | Vui lòng nhập mật khẩu |
| `signInWrongCredentials` | Email hoặc mật khẩu không đúng |
| `backendUnreachable` | Không kết nối được với EduBox |
| `backendUnreachableHint` | Kiểm tra kết nối mạng rồi thử lại. |
| `retry` | Thử lại |
| `retrying` | Đang thử lại… |
| `signInTooManyAttempts` | Đã thử quá nhiều lần. Vui lòng đợi vài phút rồi thử lại. |
| `signInAccountDisabled` | Tài khoản này đang bị tạm khóa. Vui lòng liên hệ nhà trường. |
| `signInUnknownError` | Không đăng nhập được. Vui lòng thử lại. |
| `signInHelp` | Quên mật khẩu hoặc chưa có tài khoản? Vui lòng liên hệ nhà trường. |
| `accountNotSetUp` | Tài khoản chưa được thiết lập |
| `accountNotSetUpBody` | Bạn đã đăng nhập đúng, nhưng tài khoản này chưa được gán vai trò (học sinh, giáo viên hoặc phụ huynh). Việc này do nhà trường thực hiện, không phải lỗi của bạn. |
| `accountNotSetUpContact` | Hãy nhờ giáo viên hoặc quản trị viên của trường thiết lập giúp, rồi bấm "Kiểm tra lại". |
| `accountSignedInAs` | Đang đăng nhập bằng |
| `accountSignedInAsSemantics` | Đang đăng nhập bằng {email} |
| `accountCheckAgain` | Kiểm tra lại |
| `accountChecking` | Đang kiểm tra… |
| `accountStillNotSetUp` | Vẫn chưa được thiết lập. |
| `accountCheckedAt` | Đã kiểm tra lúc {time} |
| `accountCheckFailedOffline` | Chưa kiểm tra được vì không có kết nối mạng. |
| `signOut` | Đăng xuất |
| `signOutBusy` | Đang đăng xuất… |
| `signOutConfirmTitle` | Đăng xuất khỏi EduBox? |
| `signOutConfirmBody` | Em sẽ cần nhập lại email và mật khẩu để vào lại. |
| `signOutOfflineWarning` | Đang ngoại tuyến nên em sẽ chưa đăng nhập lại được cho tới khi có mạng. |
| `signOutFailed` | Không đăng xuất được. Hãy thử lại. |
| `cancel` | Hủy |
| `navHome` | Trang chủ |
| `navLibrary` | Thư viện |
| `navTeacherOverview` | Tổng quan |
| `studentHomeGreeting` | Chào {name} |
| `studentHomeGreetingNoName` | Xin chào |
| `studentHomeDateLine` | {className} · {date} |
| `studentHomeDateOnly` | {date} |
| `studentHomeLibraryTitle` | Mới thêm vào thư viện |
| `studentHomeLibraryCount` | {count} tài liệu cho lớp em |
| `studentHomeOpenLibrary` | Mở thư viện |
| `studentHomeLoadingLibrary` | Đang tải thư viện |
| `studentHomeLibraryError` | Không tải được thư viện. |
| `studentHomeLibraryOfflineNoCache` | Không tải được thư viện vì đang ngoại tuyến. |
| `studentHomeProfileError` | Không tải được thông tin tài khoản. |
| `studentNoClass` | Em chưa được xếp vào lớp nào. |
| `studentNoClassHint` | Hãy nhờ giáo viên thêm em vào lớp. |
| `libraryTitle` | Thư viện |
| `libraryTotal` | {count} tài liệu |
| `libraryListSemantics` | Danh sách tài liệu |
| `librarySubjectOther` | Môn khác |
| `libraryLoading` | Đang tải thư viện |
| `libraryEmpty` | Thư viện của lớp chưa có tài liệu nào. |
| `libraryEmptyHint` | Khi giáo viên duyệt tài liệu, tài liệu sẽ hiện ở đây. |
| `libraryOfflineNoData` | Máy chưa lưu danh sách tài liệu. Kết nối mạng để xem thư viện. |
| `libraryLoadError` | Không tải được thư viện. |
| `libraryLoadErrorWithTime` | Không tải được thư viện. Cập nhật lần cuối {time}. |
| `libraryItemSemantics` | {title}, {type} |
| `contentTypeEbook` | Sách |
| `contentTypeVideo` | Video |
| `contentTypeExercise` | Bài tập |
| `contentRowSemantics` | {title}, {type}, {subject} |
| `lastUpdatedAt` | Cập nhật lần cuối {time}. |
| `networkOffline` | Đang ngoại tuyến. Tài liệu đã tải về vẫn mở được. |
| `networkOfflineStale` | Đang ngoại tuyến. Dữ liệu hiển thị có thể chưa mới nhất. |
| `networkReconnecting` | Đã kết nối lại, đang cập nhật… |
| `accountMenuTooltip` | Tài khoản |
| `parentMenuTooltip` | Tùy chọn |
| `teacherClassesTitle` | Lớp của tôi |
| `teacherClassesCount` | {count} lớp |
| `classColumnName` | Lớp |
| `classColumnGrade` | Khối |
| `classColumnSubjects` | Môn học |
| `classColumnStudents` | Học sinh |
| `classGradeValue` | Khối {grade} |
| `classStudentCount` | {count} học sinh |
| `classRowSemantics` | {name}, khối {grade}, môn {subjects}, {count} học sinh |
| `valueMissing` | - |
| `teacherRoleLabel` | Giáo viên |
| `teacherClassesLoading` | Đang tải danh sách lớp |
| `teacherClassesLoaded` | Đã tải {count} lớp |
| `teacherClassesEmpty` | Bạn chưa được phân công lớp nào. Liên hệ quản trị viên của trường để được thêm vào lớp. |
| `teacherClassesOfflineNoData` | Chưa có danh sách lớp trên máy này. Danh sách sẽ hiện khi có mạng. |
| `teacherClassesError` | Không tải được danh sách lớp. |
| `teacherClassesStaleError` | Không cập nhật được danh sách lớp. Cập nhật lần cuối {time}. |
| `parentHomeStudentLabel` | Học sinh |
| `parentHomeStudentSemantics` | Học sinh: {name} |
| `parentHomeNoChild` | Tài khoản này chưa được liên kết với học sinh nào. Hãy liên hệ nhà trường để được hỗ trợ. |
| `parentHomeLoadError` | Không tải được thông tin học sinh. |
| `parentHomeOfflineNoData` | Chưa có thông tin học sinh trên máy này. Hãy kết nối mạng để tải. |

Tests: `test/l10n/l10n_test.dart` checks the locale list, key presence, no
duplicate keys and the resolved aliases. `test/l10n/literal_strings_test.dart`
parses every Dart file under `lib/` except generated l10n and fails when a
string literal is passed to a user-facing slot (`Text`, `SelectableText`,
`TextSpan`, `Semantics` label/hint/tooltip, `Tooltip.message`,
`InputDecoration` labels/errors, app/bar titles, `semanticsLabel`). E2E
assertions must use `lookupAppLocalizations(Locale('vi'))`, never literal text.

## 4. CI

`.github/workflows/ci.yml` runs on `pull_request` to `main` and `push` to
`main`, with Flutter pinned to 3.47.8 and Serverpod CLI pinned to 4.0.4.

Server job:

- PostgreSQL 16 service on `localhost:9090` with the test database/password
  from `passwords.example.yaml`; no MinIO service yet because the storage tests
  are `backend-pending`.
- `dart pub global activate serverpod_cli 4.0.4`, `dart pub get`,
  `bash tool/bootstrap.sh`.
- `serverpod generate`; fail on a diff in generated server/client/test-tool
  code.
- `dart format --output=none --set-exit-if-changed .`,
  `dart analyze --fatal-infos`.
- `dart test --coverage=coverage`, `coverage:format_coverage`, then
  `dart run tool/coverage_gate.dart edubox_server/coverage/lcov.info`.
- Pub cache is cached by `pubspec.lock`.

App job:

- `flutter pub get`, `flutter gen-l10n`, stale-l10n diff check.
- `flutter analyze`, `dart format --output=none --set-exit-if-changed .`,
  `flutter test`.
- Pub cache is cached by `pubspec.lock`.

No Android emulator E2E in CI yet. That is a later addition: it needs the
`edubox_tablet` AVD, the `e2e` compose profile, a working seed command and
`flutter test integration_test`; see section 5. Actionlint
(`docker run --rm -v $PWD:/repo -w /repo rhysd/actionlint:latest`) is clean.

## 5. Commands as they really run now

Set the toolchain first:

```sh
export PATH="$HOME/development/flutter/bin:$HOME/.pub-cache/bin:$PATH"
```

Bootstrap and services for server tests:

```sh
bash tool/bootstrap.sh
docker compose up -d --wait postgres_test minio
docker compose run --rm minio-init   # creates the private buckets
```

Server:

```sh
(cd edubox_server && serverpod generate)
(cd edubox_server && dart format --output=none --set-exit-if-changed .)
(cd edubox_server && dart analyze --fatal-infos)
(cd edubox_server && dart test)
(cd edubox_server && dart test --coverage=coverage \
  && dart run coverage:format_coverage --lcov --in=coverage \
     --out=coverage/lcov.info --report-on=lib \
  && dart run ../tool/coverage_gate.dart coverage/lcov.info)
```

Server build (AOT; `dart compile exe` is not usable because Serverpod 4.0.4
packages use build hooks):

```sh
(cd edubox_server && dart build cli --target bin/main.dart --output build)
```

App:

```sh
(cd edubox_flutter && flutter pub get)
(cd edubox_flutter && flutter gen-l10n)
(cd edubox_flutter && flutter analyze)
(cd edubox_flutter && dart format --output=none --set-exit-if-changed .)
(cd edubox_flutter && flutter test)
```

App build (requires the Android SDK, which is not installed in this
environment; CI does not run it):

```sh
(cd edubox_flutter && flutter build apk --debug)
```

E2E (later addition; needs the AVD, a running compose stack and the seed
command):

```sh
tool/bootstrap.sh
docker compose --profile e2e up -d --build --wait
docker compose run --rm minio-init
docker compose run --rm seed
(cd edubox_flutter && flutter test integration_test \
  -d "$EDUBOX_E2E_DEVICE" \
  --dart-define=EDUBOX_SERVER_URL=http://10.0.2.2:8080/)
```

Roadmap-header replacements (the roadmap itself is not edited):

| Roadmap header command | Replacement / note |
| --- | --- |
| `dart compile exe bin/main.dart -o build/edubox_server` | `dart build cli --target bin/main.dart --output build`; Serverpod 4.0.4 packages use build hooks. |
| `flutter build apk --debug` | Unchanged, but not run in this environment (no Android SDK) or in CI. |
| `dart run tool/coverage_gate.dart` from `edubox_server/` | The script lives at repo-root `tool/coverage_gate.dart`; run it as `dart run ../tool/coverage_gate.dart coverage/lcov.info` from `edubox_server/`. |
| `flutter test --coverage` | `flutter test` is the contract command and CI command; coverage is optional for the app. |
| `docker compose up -d --wait` | The server-test command needs only `postgres_test minio`; the full form also starts `postgres`. |
| Seed in the e2e command | `runSeedStep`/`bin/seed` are backend-track stubs, so the e2e command is not runnable yet. |

## 6. Path ownership

| Owner | Paths | Notes |
| --- | --- | --- |
| Contract (frozen) | `edubox_server/lib/src/models/**`, `migrations/**`, `lib/src/authz/**`, endpoint signatures listed in section 1, `edubox_server/lib/src/config/**`, `edubox_server/lib/src/storage/object_store.dart` interface, `edubox_server/test/integration/authorization/**`, `edubox_server/test/integration/auth/**`, `edubox_server/test/integration/support/**`, `edubox_server/test/integration/test_tools/**`, `edubox_client/**` generated protocol, `edubox_fixtures/**` | Change only with a contract change; backend fixes inside a method body are allowed if signatures and DTOs stay fixed. |
| Backend track | The stub methods in `edubox_server/lib/src/storage/object_store.dart`, `lib/src/seed/**` implementation, `bin/seed.dart`, `Dockerfile` seed target, `test/integration/storage/**`, `test/integration/seed/**` (remove `backend-pending` tags), `tool/coverage_gate.dart` fixes | Storage spike, seed command, MinIO setup. |
| Frontend track | `edubox_flutter/lib/main.dart`, `lib/src/app/**`, `lib/src/shell/**`, `lib/src/screens/**`, `lib/src/features/**`, `lib/src/data/**` (repository implementations), `lib/src/network/**` (production network source), `lib/src/theme/**`, `test/widget/**`, `integration_test/**` | Screens, theme tokens, production repositories and network probe. |
| Contract (app) | `edubox_flutter/lib/src/contract/**`, `lib/src/fake/**`, `lib/src/local/local_store.dart` + `local_store.g.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/generated/**`, `l10n.yaml`, `test/contract/**`, `test/local/local_store_test.dart`, `test/l10n/**` | The interfaces, fake, cache schema, ARB keys and their tests. |

## 7. Open items

- No product decision blocks phase 1. The only deliberate gaps are the
  backend-track stubs in section 2.5; they are marked with skipped tests and
  must be removed before the phase 1 gate.
- Android emulator E2E is not part of CI yet (section 4); it needs the AVD and
  the seed command.
