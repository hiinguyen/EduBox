import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:serverpod/serverpod.dart';

import '../config/edubox_config.dart';
import '../generated/protocol.dart';
import '../seed/seed_command.dart';
import '../storage/object_store.dart';

/// The token-guarded route the on-device E2E harness uses to change
/// server-side state mid-run (exit criterion 7 and the account-not-set-up
/// check-again case).
///
/// It exists only in the run modes the contract allows (the compose e2e
/// server's `development` mode and Serverpod's `test` mode), only when that
/// mode sets `edubox.e2eControl: true` or `EDUBOX_E2E_CONTROL=true`, and it
/// always requires the `e2eControlToken` password. `production`, `staging` and
/// every other run mode reject it even with the environment override and the
/// correct token. The contract is in docs/build/phase-1/contract.md section
/// 2.8.
class E2eEndpoint extends Endpoint {
  /// True only when [runMode] is allowed and [config] enables the route.
  ///
  /// [EduboxConfig.load] already applies this run-mode gate, but the endpoint
  /// checks it again so a manually constructed [EduboxConfig] cannot bypass
  /// it.
  static bool enabledForRunMode(String runMode, EduboxConfig config) =>
      EduboxConfig.e2eControlRunModes.contains(runMode) && config.e2eControl;

  /// Whether this call may run: the run mode and config must enable the route,
  /// a token must be configured, and [providedToken] must match it.
  static bool authorize({
    required String runMode,
    required EduboxConfig config,
    required String? expectedToken,
    required String providedToken,
  }) {
    if (!enabledForRunMode(runMode, config)) return false;
    if (expectedToken == null || expectedToken.isEmpty) return false;
    return _tokensMatch(providedToken, expectedToken);
  }

  /// Runs one control operation and returns `ok:<step>`.
  Future<String> run(
    Session session, {
    required String token,
    required String step,
    String? accountKey,
    String? role,
  }) async {
    final runMode = session.serverpod.runMode;
    final config = EduboxConfig.load(
      runMode: runMode,
      serverDirectory: session.serverpod.serverDirectory.path,
    );
    final expected = session.passwords['e2eControlToken'];
    if (!authorize(
      runMode: runMode,
      config: config,
      expectedToken: expected,
      providedToken: token,
    )) {
      throw AccessDeniedException(reason: AccessDeniedReason.wrongRole);
    }

    final seedStep = SeedStep.tryParse(step);
    if (seedStep != null) {
      await runSeedStep(
        session,
        seedStep,
        e2eStore: _storeFromConfig(session, config),
      );
      return 'ok:${seedStep.cliName}';
    }

    switch (step) {
      case 'set-role':
        await _setRole(session, accountKey: accountKey, role: role);
        return 'ok:set-role';
      case 'clear-role':
        await _setRole(session, accountKey: accountKey, role: null);
        return 'ok:clear-role';
      default:
        throw ArgumentError.value(step, 'step', 'Unknown e2e control step');
    }
  }

  ObjectStore _storeFromConfig(Session session, EduboxConfig config) =>
      S3ObjectStore(
        config: config.storage,
        accessKey: session.passwords['storageAccessKey'] ?? '',
        secretKey: session.passwords['storageSecretKey'] ?? '',
      );

  Future<void> _setRole(
    Session session, {
    required String? accountKey,
    required String? role,
  }) async {
    if (accountKey == null || accountKey.isEmpty) {
      throw ArgumentError.value(accountKey, 'accountKey', 'Required');
    }
    final fixture = FixtureSet.phase1().account(accountKey);
    final user = await EduboxUser.db.findFirstRow(
      session,
      where: (table) => table.email.equals(fixture.email),
    );
    if (user == null) {
      throw StateError('Fixture $accountKey has no users row');
    }
    await EduboxUser.db.updateRow(session, user.copyWith(role: role));
  }

  /// Compares fixed-length digests so a length mismatch does not leak the
  /// expected token's length through timing.
  static bool _tokensMatch(String provided, String expected) {
    final providedDigest = sha256.convert(utf8.encode(provided)).bytes;
    final expectedDigest = sha256.convert(utf8.encode(expected)).bytes;
    var difference = 0;
    for (var index = 0; index < providedDigest.length; index++) {
      difference |= providedDigest[index] ^ expectedDigest[index];
    }
    return difference == 0;
  }
}
