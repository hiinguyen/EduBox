import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:serverpod/serverpod.dart';

import '../config/edubox_config.dart';
import '../generated/protocol.dart';
import '../seed/seed_command.dart';
import '../storage/object_store.dart';
import 'e2e_control_settings.dart';

/// The token-guarded route the on-device E2E harness uses to change
/// server-side state mid-run (exit criterion 7 and the account-not-set-up
/// check-again case).
///
/// It is disabled unless the run-mode config has `edubox.e2eControl: true` or
/// `EDUBOX_E2E_CONTROL=true`, and it always requires the
/// `e2eControlToken` password. The contract is in
/// docs/build/phase-1/contract.md section 2.8.
class E2eEndpoint extends Endpoint {
  /// Runs one control operation and returns `ok:<step>`.
  Future<String> run(
    Session session, {
    required String token,
    required String step,
    String? accountKey,
    String? role,
  }) async {
    final config = EduboxConfig.load(runMode: session.serverpod.runMode);
    final enabled = E2eControlSettings.enabledOverride ?? config.e2eControl;
    final expected =
        E2eControlSettings.tokenOverride ??
        session.passwords['e2eControlToken'];
    if (!enabled || expected == null || expected.isEmpty) {
      throw AccessDeniedException(reason: AccessDeniedReason.wrongRole);
    }
    if (!_tokensMatch(token, expected)) {
      throw AccessDeniedException(reason: AccessDeniedReason.wrongRole);
    }

    final seedStep = SeedStep.tryParse(step);
    if (seedStep != null) {
      await runSeedStep(
        session,
        seedStep,
        e2eStore:
            E2eControlSettings.storeOverride ??
            _storeFromConfig(session, config),
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

  bool _tokensMatch(String provided, String expected) {
    if (provided.length != expected.length) return false;
    var difference = 0;
    for (var index = 0; index < provided.length; index++) {
      difference |= provided.codeUnitAt(index) ^ expected.codeUnitAt(index);
    }
    return difference == 0;
  }
}
