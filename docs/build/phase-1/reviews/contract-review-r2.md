# Phase 1 contract review - r2

Scoped re-review of `git diff dcb51cb..068c370` (`fix: phase 1 contract review r1`) against `contract-review-r1.md`.
Scope: the disposition of every r1 finding, regressions introduced by the fix diff, roadmap edits, `.superpowers/` ignore, and a full verification run.

```text
VERDICT: FIX
FINDINGS:
- [HIGH] edubox_server/lib/src/e2e/e2e_endpoint.dart:28 - the e2e control route can be enabled in production: `enabled = E2eControlSettings.enabledOverride ?? config.e2eControl`, and `EduboxConfig.load` (edubox_config.dart:56-60) turns `EDUBOX_E2E_CONTROL=true` into `e2eControl: true` in any run mode, including `production`; nothing checks `session.serverpod.runMode` - the route is unauthenticated apart from the token and its `reset` step truncates every EduBox and Serverpod auth table, while roadmap.md:59 and contract.md:110-111 promise "enabled only in the compose e2e run mode" / "disabled everywhere except the compose e2e server"; the test at e2e_control_test.dart:102-107 checks only development and test, and `E2eControlSettings` (e2e_control_settings.dart:10-23) is a mutable global enable/token override that ships in lib/ - fix: reject unconditionally when `runMode == 'production'` (and ideally allow only `development`), ignore the env override in production, add a test that production mode with `EDUBOX_E2E_CONTROL=true` and a token still denies, and move the test seam behind a check that cannot run in production - owner: contract
- [HIGH] .github/workflows/ci.yml:38 - regression: the new `minio` service container cannot start; GitHub Actions `services` cannot set a command, and `pgsty/minio` has `ENTRYPOINT docker-entrypoint.sh`, `CMD ["minio"]`, which prints help and exits 0 (reproduced: `docker run` of the same image with the same env exits immediately, "NAME: minio - High Performance Object Storage"); compose.yaml:50 needs `command: ["server", "/data", ...]` for exactly this reason - the `mc ready local` health check never passes, so the whole server job fails at container initialization, before any test runs - fix: start MinIO in a step (`docker run -d --network host ... server /data`) and wait for `mc ready`, or use an image whose default command starts the server - owner: contract
- [HIGH] docs/build/phase-1/contract.md:776 - r1 path-ownership finding is only partly fixed: the frontend owns `lib/src/data/**` and `lib/src/network/**` (repository binding, cache/network data layer, reachability probe) but its only test paths are `test/widget/**` and `integration_test/**`; unit tests for the data layer and the probe (`test/data/**`, `test/network/**`, `test/app/**`) belong to no one, so a TDD frontend executor stops on its first test - fix: give the frontend `edubox_flutter/test/**` except the contract-owned `test/contract/**`, `test/local/**`, `test/l10n/**` - owner: contract
- [MEDIUM] edubox_flutter/test/l10n/literal_string_scanner.dart:160 - the scanner only flags an argument that is itself a string literal, so `Text(isOn ? 'Bật' : 'Tắt')` (and `??`, parenthesized, or `const x = '...'; Text(x)`) passes; verified by planting a file in lib/: lines with `Text('...')`, `Text('Chào $name')`, `TextSpan(text:)` and `IconButton(tooltip:)` failed the test, the ternary line did not; the self-test asserts `violations.length >= 12` (literal_strings_test.dart:74) while the source plants 15, so dropping interpolation or nested-literal detection would still pass - fix: recurse into ConditionalExpression/BinaryExpression(`??`)/ParenthesizedExpression operands, plant a ternary, and assert the exact violation list - owner: contract
- [MEDIUM] edubox_flutter/lib/src/fake/fake_backend.dart:180 - an offline "cached" read returns the fake's live fixture state, not a snapshot from the last online refresh: `applyReconnectDeltas()` or `setRole()` while offline immediately shows the new class/item/role as stale data, the opposite of exit criterion 7 (new data appears only after reconnect) - fix: snapshot each role-home value at its last online read and serve that while offline - owner: contract
- [MEDIUM] docs/build/phase-1/contract.md:441 - the data layer "notifies its listeners; screens re-read then", but `EduBoxBackend` (edubox_flutter/lib/src/contract/backend.dart:7-16) and the repositories expose no listener or change stream, and the interface is frozen - either add a `Listenable`/`Stream<void> refreshed` to the frozen seam now or state that screens listen to `NetworkController` and re-read on `-> online` - owner: contract
- [MEDIUM] edubox_server/test/integration/seed/seed_command_test.dart:210 - the reset test runs reset twice on an already-seeded database and compares six EduBox counts, so an implementation that skips when data exists, or never truncates the auth tables, passes; nothing proves a reset removes rows created after seeding (the r1 ask was "reset truncates") - fix: run `reconnectLibrary`/`reconnectClasses`/`assignRole` and add a stray auth user, then reset and assert the deltas are gone, `null_role` is null again, and auth-user/email-account counts equal the fixture count - owner: contract
- [MEDIUM] edubox_flutter/test/contract/contract_suite.dart:148 - the wrong-password case still signs in as `hs.an@edubox.test`, so against a long-lived real server five runs inside five minutes lock An and later `signInAs(studentAn)` fails; contract.md:503-504 says the AVD suite runs "after e2e.run(step: 'reset')" but not that the reset precedes every run - use the dedicated `rate_limit_student` (or a second dedicated account) for wrong-password, or make the per-run reset explicit in the suite's setUpAll - owner: contract
- [MEDIUM] .gitignore:1 - `.superpowers/` is not ignored (`git check-ignore .superpowers/x` reports nothing), while the pipeline artifact table says the SDD ledgers under `.superpowers/sdd/<plan-name>/` are git-ignored; the build tracks will write there next - add `/.superpowers/` to the contract-owned root .gitignore - owner: contract
- [MEDIUM] docs/build/roadmap.md:6 - the fix edited the roadmap beyond adding Rulings lines: the Commands header (:6, requested by r1), the seed note (:20), the coverage-gate note (:24), the phase 1 storage-spike package (:55), a new sentence in the local-store capability (:57), a new "E2E control seam" capability bullet (:59) and the storage risk (:83); the phase-scope edits (:55, :57, :59, :83) change phase 1 scope text outside the Rulings section - the orchestrator should accept or revert them explicitly - owner: contract
- [LOW] edubox_server/Dockerfile:63 - the exec-form entrypoint is correct (verified below), but the r1 ask for an image smoke check was not added, so a future entrypoint regression is caught only by the AVD E2E - add a CI step that builds the image and waits for `/readyz` - owner: contract
- [LOW] edubox_server/lib/src/e2e/e2e_endpoint.dart:90 - `_tokensMatch` returns early on a length mismatch, leaking the token length by timing - compare fixed-length digests instead - owner: contract
- [LOW] edubox_server/test/integration/seed/seed_step_test.dart:58 - the contract guard test for `seedResetTables` lives under `test/integration/seed/**`, which contract.md:775 gives to the backend track, so the track that edits the list also owns its guard - move it to a contract-owned path - owner: contract
```

## Disposition of r1 findings

| # | r1 finding | Status | Evidence |
| --- | --- | --- | --- |
| H1 | Literal-string test vacuous | RESOLVED | literal_string_scanner.dart:116-137 visits `InstanceCreationExpression` and target-less `MethodInvocation`; `StringInterpolation` is a `StringLiteral`; self-test at literal_strings_test.dart:36-76. Planting a file in lib/ made the test fail (exit 1) on `Text`, interpolated `Text`, `TextSpan.text` and `IconButton.tooltip`. Residual ternary gap is the new MEDIUM. |
| H2 | Shell-form ENTRYPOINT drops compose `command:` | RESOLVED | Dockerfile:63-64 exec form. Built and started `docker compose --profile e2e up -d --build --wait`: container `Args` = `--mode development --apply-migrations`, logs `runMode: development`, `applyMigrations: true`, `/readyz` 200. Smoke check not added (LOW). |
| H3 | E2E control route undefined | RESOLVED (new HIGH on production guard) | contract.md:304-330, e2e_endpoint.dart, matrix list authorization_matrix.dart:84-91, e2e_control_test.dart. Live: wrong token -> 400 `AccessDeniedException(wrongRole)`; correct dev token passes the gate. |
| H4 | Cache-first/freshness contract missing | RESOLVED (new MEDIUM on notification seam) | backend_result.dart:88-124 `cachedAt`/`isStale`; local_store.dart:125-130 `CachedValue`; contract.md:408-411, 434-456 read path, reconnect refresh, fail-fast; fake follows `NetworkController` (fake_backend.dart:73-92). |
| H5 | Shared suite misses error-mapping rows | RESOLVED | contract_suite.dart:161-271 blocked, too-many-attempts, not-set-up on every role method incl. ping, wrong role, `SessionExpiredError`; :301-332 refreshProfile after role fix and unreachable factory; :334-411 offline rows. |
| H6 | Seed/storage acceptance tests too loose | RESOLVED (new MEDIUM on reset proof) | seed_command_test.dart exact identities, roles, links, credentials sign-in, classes, content scope, each delta step; object_store_test.dart:23-27 distinct `localhost` vs `127.0.0.1`, :94-111 expiry, :113-135 `deletePrefix`. Both suites still `backend-pending` (skipped), as designed. |
| H7 | Path ownership gaps | PARTIAL | contract.md:767-784 assigns server.dart, bin/main.dart, android, assets, pubspec per track, lockfile rule; CI has MinIO. Frontend unit-test paths still unowned (HIGH above), and the CI MinIO service does not start (HIGH above). |
| M1 | No `SessionExpiredError` | RESOLVED | backend_result.dart:42; contract.md:159, 171-174. |
| M2 | Offline-no-cache test name overclaims | RESOLVED | fake_backend_test.dart:103-152 covers library, profile, classes, parent home. |
| M3 | Fake cannot hold calls / apply deltas | RESOLVED | fake_backend.dart:56, 115-132; tests fake_backend_test.dart:239, 259. Snapshot fidelity is the new MEDIUM. |
| M4 | Coverage gate skips on missing lcov records | RESOLVED | coverage_gate.dart:50-64. Ran: real lcov -> authorization 95.5% PASS exit 0; lcov with authz records stripped -> "authorization FAIL (lib/src/authz/ exists but lcov has no records)" exit 1. |
| M5 | No `.dockerignore` | RESOLVED | .dockerignore:2; the built image's `config/` has no `passwords.yaml`. |
| M6 | Unauthenticated list widening needs a ruling | RESOLVED | roadmap.md Rulings 2026-10-30 (module/framework routes). |
| M7 | Stale roadmap header commands | RESOLVED | roadmap.md:6; contract.md:755-765. |
| M8 | Contract suite rate-limits An | PARTIAL | Too-many-attempts moved to `rate_limit_student` (contract_suite.dart:170-188); runner and reset specified (contract.md:499-505); wrong-password still on An (MEDIUM above). |
| M9 | Offline session restore risk not retired | RESOLVED | Fallback specified, contract.md:373-379 and roadmap Ruling 2026-10-30; suite test contract_suite.dart:362-370. |
| M10 | Promised `seedResetTables` guard test missing | RESOLVED | seed_step_test.dart:58-101 compares both directions against the latest migration; ran and passed. |
| L1 | Streams skip HTTP-dispatch anonymous test | RESOLVED | authorization_matrix_test.dart:80-86; "diagnostics.pingStream denies anonymous through the HTTP dispatch path" passed. |
| L2 | CI misses fixtures tests and drift freshness | RESOLVED | ci.yml fixture `dart test` step and `build_runner build` plus diff check; build_runner 2.16.1 fixes stale outputs by default, so no `--delete-conflicting-outputs` prompt. |
| L3 | No empty-library / no-class teacher fixtures | RESOLVED | contract.md:270-274; contract_suite.dart:83-96. |
| L4 | Strip keys unmapped | RESOLVED | contract.md:621-626. |
| L5 | Storage package switch unruled | RESOLVED | roadmap.md Ruling 2026-10-30 (s3_compat). |
| L6 | Sign-out test checks only auth users | RESOLVED | module_endpoints_test.dart now also compares `ServerSideSession` and `RefreshToken` counts. |
| L7 | Docker networking override undocumented | RESOLVED | contract.md:750-753. |

Totals: 22 RESOLVED, 2 PARTIAL (H7, M8), 0 OPEN.

## Regression check of the fix diff

- E2E control route: token-guarded (verified in tests and live), but not run-mode guarded (HIGH above).
- Secrets: no real secret added; every new value is a labelled `dev-only`/`test-only` value; `config/passwords.yaml` has never been committed (`git log --all` empty).
- Tests not weakened: removed assertions in local_store_test.dart and fixture_set_test.dart were re-expressed through `CachedValue.value` with added `cachedAt` checks; the matrix test gained the stream dispatch case; no `skip` or tag was added to a previously running test.
- Literal scanner: really fails on planted literals (see H1), with the ternary gap noted.
- CI: the new MinIO service breaks the server job (HIGH above).

## Roadmap edits

Rulings section: four new 2026-10-30 Rulings lines (e2e control route, unauthenticated list, s3_compat, offline session restore).
Other edits: roadmap.md:6, :20, :24, :55, :57, :59, :83, listed in the MEDIUM finding above.

## Verification run

- App: `flutter analyze` - No issues found; `flutter test` - 47 passed. PASS.
- Server: `dart analyze --fatal-infos` - No issues found. PASS.
- Server: `bash tool/bootstrap.sh && docker compose up -d --wait` (bridge networking), `minio-init`, then `dart test` - 71 passed, 2 skipped (the `backend-pending` seed and storage suites). PASS.
- Coverage pipeline plus gate: authorization 95.5% (21/22) PASS; negative lcov case fails as intended.
- E2E image: `docker compose --profile e2e up -d --build --wait` - server healthy, `/readyz` 200, migrations applied in development mode.
- CI MinIO service reproduction: the image without `server /data` exits immediately (FAIL, HIGH above).
- `docker compose --profile e2e down` afterwards; volumes `edubox_edubox_data` and `edubox_edubox_minio` kept.
