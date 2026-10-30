VERDICT: APPROVE

FINDINGS:
- [LOW] edubox_flutter/test/l10n/literal_string_scanner.dart:167 - carried scanner gaps are not recorded: `_literalOperands` still misses variable references (`const x = '...'; Text(x)`), `+` concatenation (`Text('Chào ' + name)`, a `BinaryExpression` whose operator is not `??`) and a literal method target (`Text('xin chào'.toUpperCase())`), while contract.md:653-656 lists only the covered forms, so a frontend executor may read the uncovered forms as allowed - code reading of the unwrap branches (parentheses, conditional, `??`, `as`, then `StringLiteral`/`AdjacentStrings` only); `prefer_interpolation_to_compose_strings` is not enabled in edubox_flutter/analysis_options.yaml - add one contract.md sentence naming the uncovered forms as a carried limit (and, cheaply, a `+` branch with a planted case) - owner: contract
- [LOW] tool/bootstrap.sh:14 - `test.yaml` now enables the route and `e2e_control_test.dart` needs the new `test.e2eControlToken`, but bootstrap leaves an existing `passwords.yaml` untouched, so a checkout bootstrapped before 756f698 fails the set-role test with `AccessDeniedException` - fresh CI and new worktrees are fine (the local file here already equals the example) - have bootstrap report example keys missing from `passwords.yaml`, or note the re-bootstrap in contract.md - owner: contract
- [LOW] edubox_server/lib/src/e2e/e2e_endpoint.dart:40 - the endpoint-side run-mode check exists "so a manually constructed EduboxConfig cannot bypass it", but no test calls `E2eEndpoint.authorize` with `runMode: 'production'` and a config whose `e2eControl` is true; the production cases at e2e_control_test.dart:115 build the config through `EduboxConfig.load`, which already forced it false, so deleting either gate alone still passes the unit group (the `withServerpod` production test catches only the case where both are removed) - add `authorize(runMode: 'production', config: EduboxConfig(storage: ..., e2eControl: true), ...)` expecting false - owner: contract
```

## Status of r2 findings

- H1 e2e route enableable in production - FIXED.
  `EduboxConfig.load` returns `e2eControl = e2eControlRunModes.contains(runMode) && configured`, and the endpoint checks the run mode again before the token (edubox_config.dart, e2e_endpoint.dart:29-43).
  The mutable `E2eControlSettings` override was deleted from lib/, so no test seam ships.
  A real `withServerpod(runMode: 'production')` test uses a committed test-only production config with `e2eControl: true` and the right token, and gets `AccessDeniedException`.
  Without the gate, that call would reach `_setRole` on an unseeded DB and throw `StateError`, so the test is meaningful.
  Unit tests cover production and staging with `EDUBOX_E2E_CONTROL=true`, development and test allowed, the disabled switch and a wrong token.
  Allowing `development` matches the updated 2026-10-30 Ruling and the compose e2e server, so it is not re-raised.
- H2 CI MinIO service cannot take a command - FIXED.
  MinIO now starts in a step (`docker run -d --network host ... server /data`) and the step waits on `/minio/health/ready`.
  The bucket step and storage env still point at localhost:9000.
  actionlint passes.
- H3 no frontend unit-test path for data/network - FIXED.
  The frontend owns `edubox_flutter/test/**` except `test/contract/**`, `test/local/**` and `test/l10n/**`, which the contract (app) row now owns.
  The two rows have no overlap and leave no gap.
- M literal scanner ternary gap and loose self-test - FIXED.
  Parentheses, conditional, `??` and `as` are unwrapped.
  The self-test asserts the exact 19-entry slot list and line:column positions.
  The remaining gaps are carried (LOW above).
- M fake offline served live fixture state - FIXED.
  Per-key snapshots are taken at online reads and sign-in, and the session snapshot drives offline role gating and `restoreSession`.
  Two new tests prove that `applyReconnectDeltas()` and `setRole()` made offline appear only after reconnect.
- M listener seam - FIXED by contract text: screens listen to `NetworkController` and re-read on `online`, and the frozen seam gets no second stream.
- M reset test too weak - FIXED.
  The reset test now applies the reconnect deltas and assign-role and adds a stray auth user and email account, then asserts all of them are gone and `null_role` is null again.
  It is still behind `backend-pending`, as designed, so it runs when the backend track un-skips it.
- M wrong-password case locks An - FIXED.
  An optional `resetState` hook runs in the suite's `setUpAll`, and contract.md says phase 5 passes `e2e.run(step: 'reset')`.
  Within one run, An gets one wrong attempt.
- M `.superpowers/` not ignored - FIXED (`/.superpowers/` in .gitignore).
- M roadmap scope drift - FIXED.
  The fix removed the added local-store sentence and the "E2E control seam" capability bullet.
  The other remaining non-Rulings edits (header commands, seed note, coverage-gate note, s3_compat package and risk) carry out r1 requests or existing 2026-10-30 Rulings.
- L Dockerfile smoke check - FIXED.
  CI builds the image, runs it in `development` mode against `postgres_test` and the test bucket, and waits for `/readyz`.
  I reproduced the step locally and it passed (see below).
- L token length timing leak - FIXED (SHA-256 digests compared in constant time).
- L guard test under a backend path - FIXED.
  The test moved to `test/integration/contract/`, and `contract/**` is in the frozen contract row.

## New-defect check

- Secrets: the new `test/integration/e2e/production/config/passwords.yaml` is force-tracked, and its values are labelled `test-only`/`dev-only` and equal the committed example values.
  No real secret was added.
- Tests not loosened: the `>= 12` count was replaced by exact lists.
  The removed `_NoopStore` and override-based tests were replaced by config-driven and real-run-mode tests.
  No `skip` or tag was added.
- Gate bypass: neither the env override nor the config file can enable the route outside development/test.
  The only enable path left is a deployment run in `development` mode with the override, which the Ruling accepts.
- CI on ubuntu-latest: `curl`, `docker` and host networking are available.
  The `migrations` symlink in the production fixture resolves on Linux.
  The smoke step mounts the bootstrapped config, which equals the example.

## Verification

- `docker compose up -d --wait` - PASS (postgres, postgres_test, minio healthy).
- Server `dart analyze --fatal-infos` - PASS (No issues found).
- Server `dart test` - PASS (74 passed, 2 skipped `backend-pending` suites).
- Server `dart test -r expanded` on e2e, seed and contract dirs - PASS, including "e2e control route in production production denies even with e2eControl true and the right token" and all four run-mode gate tests.
- Server and app `dart format --set-exit-if-changed` - PASS.
- App `flutter analyze` - PASS (No issues found).
- App `flutter test` - PASS (49 passed).
- `docker run --rm -v $PWD:/repo -w /repo rhysd/actionlint:latest` - PASS (exit 0, no output).
- CI smoke-check reproduction: built the image as a review-only tag and ran the exact CI `docker run` against local `postgres_test` and MinIO.
  It applied migration 20261029133845455 in `runMode: development`, and `/readyz` returned 200 - PASS.
  I removed my container and image tag afterwards.
- `docker compose down` (volumes `edubox_edubox_data`, `edubox_edubox_minio` kept) - done.
