VERDICT: FIX

Scope: `git diff abc5e4e..cac1212` (commit cac1212, FE Task 4).
Later commits fd62f45 and dca5bd9 (Task 5) were not reviewed.

Spec match: all 8 Dart files are byte-identical to the plan's code blocks in frontend.md Task 4, and `pubspec.yaml` adds exactly `serverpod_auth_idp_client: 4.0.4`.
Only frontend-owned paths changed (`lib/src/data/**`, `test/data/**`, `edubox_flutter/pubspec.yaml`); `test/contract/**` is untouched.
`pubspec.lock` is unchanged in the range, and `dart pub get` on a clean snapshot of cac1212 leaves it byte-identical, so no lock commit was needed.
No user-facing literals in `lib/src/data/**`.

Verification (run by the reviewer, the implementer never reported):
- Isolated snapshot of cac1212 (git archive into scratchpad): `flutter analyze` No issues found; `dart format --set-exit-if-changed` 0 changed; `flutter test` +105 All tests passed; `flutter test test/data` +34 passed 3 runs in a row (deterministic).
- Branch HEAD (dca5bd9, includes Task 5): analyze clean, format clean, `flutter test` +128 All tests passed, `flutter gen-l10n` then `git status --porcelain` empty.
- The frozen contract suite runs against `CachedBackend` over `FixtureEduBoxApi` and passes.

Checked and correct: offline/reconnecting reads never dial (test asserts `api.calls` unchanged), stale results keep the snapshot `cachedAt` with `isStale: true`, `OfflineNoCacheError` when no snapshot, `signIn`/`refreshProfile` fail fast offline, offline `restoreSession` returns the cached session as stale, `signOut` clears auth and cache even offline, reconnect refreshes `profile.me` and the role home.
Unary-call mapping matches the real serverpod_client 4.0.4: the IO delegate wraps `SocketException`, `http.ClientException` and `TimeoutException` into `ServerpodClientNetworkException`; 401 is `ServerpodClientUnauthorized`; `signOutDevice` swallows the server failure and clears the stored session in `finally`.

FINDINGS:
- [HIGH] edubox_flutter/lib/src/data/error_mapping.dart:45 - method-stream (ping) failures from the real client are not mapped: serverpod_client 4.0.4 streams throw `MethodStreamException` subtypes, not `ServerpodClient*Exception`. An unauthenticated or expired caller gets `OpenMethodStreamException(authenticationFailed)` (the ping endpoint has `requireLogin => true`, so the guard's `AccessDeniedException(unauthenticated)` is never reached), and a closed port or timeout gets `WebSocketConnectException` / `ConnectionAttemptTimedOutException` (also `WebSocketClosedException`, `ConnectionClosedException`, `WebSocketListenException`, `MethodStreamIdleTimeoutException`). All of them fall to `_ => UnexpectedBackendError` at line 50 - evidence: `~/.pub-cache/hosted/pub.dev/serverpod_client-4.0.4/lib/src/client_method_stream_manager.dart:116-166,616-638` and `method_stream/method_stream_manager_exceptions.dart`; `edubox_server/lib/src/authz/edubox_endpoint.dart:10`; contract.md 2.4 requires closed port/timeout -> `BackendUnreachableError` and unauthenticated -> `SessionExpiredError`, and the frozen suite (`test/contract/contract_suite.dart:271-279`) asserts signed-out ping is `BackendException(SessionExpiredError)`, which will fail when phase 5 runs the suite against the real client. It passes on host only because `FixtureEduBoxApi.pingStream` (test/data/fixture_api.dart:40,121) throws `ServerpodClientUnauthorized` / `ServerpodClientNetworkException`, which the real streaming client never throws, so the fixture's "same exception types" claim is false for streams. Fix: map `OpenMethodStreamException(authenticationFailed)` -> `SessionExpiredError` (and decide `authorizationDeclined`), the transport `MethodStreamException` subtypes -> `BackendUnreachableError`; make the fixture's ping throw those real types; add them to error_mapping_test.dart - owner: frontend implementer (plan code in frontend.md Task 4 carries the gap).
- [MEDIUM] edubox_flutter/lib/src/data/cached_backend.dart:152 - `signIn` stores the auth session in `api.login` before `profileMe`; if `profileMe` (or the cache save) then fails, the result is a failure (for example `BackendUnreachableError`) but the stored auth is left in secure storage, so the next app start silently restores a session the user was told failed. Clear stored auth (`api.clearStoredAuth()`) when the post-login step fails, and add a test - owner: frontend implementer.
- [LOW] edubox_flutter/lib/src/data/cached_backend.dart:86 - `_refreshAfterReconnect` is fire-and-forget from the network listener; repository calls are guarded, but a throw from `store.readSession()` (drift error) becomes an uncaught async error in the zone instead of a logged failure. Wrap the body in try/catch and log - owner: frontend implementer.
- [LOW] edubox_flutter/lib/src/data/cached_backend.dart:211,214 - `signOut` calls `api.clearStoredAuth()` outside any try; a secure-storage failure escapes as a thrown exception, breaking the contract rule that repositories return `BackendResult` and never throw (2.4) - owner: frontend implementer.
- [LOW] edubox_flutter/lib/src/data/cached_backend.dart:167 - `restoreSession` while the seam is `online` but the server call fails as unreachable (probe passed, request timed out) returns `BackendFailure(BackendUnreachableError)` instead of falling back to the cached session as stale; contract 3.2 only mandates the fallback when the seam is offline, so this is not a violation, but cold start on a flaky link lands on an error rather than the cached role home - owner: frontend implementer (consider with Task 5 shell).
- [LOW] edubox_flutter/test/data/error_mapping_test.dart:67 - mapping tests omit `HttpException`, the four `RefreshToken*Exception` types and `ServerpodClientForbidden`, all of which the mapping handles explicitly; there is also no test for online `signOut` when the server call fails - owner: frontend implementer.

## Re-review r2

VERDICT: APPROVE

Scope: `git diff feb2861..e1a2903` (commit e1a2903 "fix: data layer stream error mapping and session cleanup").
Verification in the worktree (HEAD e1a2903, clean): `flutter analyze` No issues found; `dart format` 0 changed on `lib/src/data` and `test/data`; `flutter test test/data test/contract` +81 All tests passed, 3 runs in a row; full `flutter test` +149 All tests passed.

Stream mapping checked against serverpod_client 4.0.4:
- `OpenMethodStreamException` is thrown only at `client_method_stream_manager.dart:166` after the one JWT refresh retry (line 116), so `authenticationFailed` -> `SessionExpiredError` is correct for the `requireLogin` ping endpoint.
- Every other error the stream manager puts on an inbound stream is a `MethodStreamException` transport subtype: `WebSocketConnectException` / `ConnectionAttemptTimedOutException` (616-638), `ConnectionClosedException` (413), `WebSocketClosedException` default for `closeStreamingMethodConnections` and the connectivity-loss close (`serverpod_client_shared.dart:142,201`), `WebSocketListenException` (574), `MethodStreamIdleTimeoutException` (688). The catch-all `MethodStreamException() => BackendUnreachableError` covers all of them; server-thrown serializable exceptions (509) still arrive as their own types (`AccessDeniedException`) and map by reason.
- The fixture's ping now throws the real types: `WebSocketConnectException` when unreachable and `OpenMethodStreamException(authenticationFailed)` with no stored session; unary calls keep `ServerpodClientNetworkException` / `ServerpodClientUnauthorized`, which is what the IO delegate throws.

Prior findings:
- [HIGH] error_mapping.dart stream mapping - fixed (mapping, fixture and tests for every subtype and both ping paths).
- [MEDIUM] cached_backend.dart sign-in leaves stored auth - fixed (post-login failure clears stored auth and rethrows the original error; test added).
- [LOW] reconnect refresh uncaught error - fixed (try/catch with `debugPrint` of error and stack; test with a throwing store).
- [LOW] signOut throws on clearStoredAuth failure - partial (no longer throws, see the new LOW below).
- [LOW] online-but-unreachable restore - fixed (falls back to the cached session as stale, otherwise returns the error; test added).
- [LOW] mapping test gaps - fixed (`HttpException`, the four refresh-token types, `ServerpodClientForbidden`, online sign-out with a failing server).

FINDINGS:
- [LOW] edubox_flutter/lib/src/data/cached_backend.dart:250 - when `api.clearStoredAuth()` throws, `signOut` returns the failure before `store.clearAll()`, so the cached session and role-home snapshots stay on the device; contract 3.2 says sign-out clears the local session, and the offline restore path would still render the cached role home. Run `store.clearAll()` regardless and then report the first failure - owner: frontend implementer.
- [LOW] edubox_flutter/lib/src/data/error_mapping.dart:47,59 - `OpenMethodStreamResponseType.authorizationDeclined` and `ServerpodClientForbidden` now map to `PermissionDeniedError`, but contract 2.4 says `PermissionDeniedError` is only the wrong-role case (`AccessDeniedException(wrongRole)`) and anything else is `UnexpectedBackendError`. Phase 1 uses no Serverpod scopes, so neither signal can occur today; either map them to `UnexpectedBackendError` or record the extension in the contract - owner: frontend implementer.
