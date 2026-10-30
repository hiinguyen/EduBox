import 'dart:io';

import 'package:edubox_server/src/config/edubox_config.dart';
import 'package:edubox_server/src/e2e/e2e_endpoint.dart';
import 'package:edubox_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/harness.dart';
import '../test_tools/serverpod_test_tools.dart';

/// The token in `config/passwords.example.yaml` / `config/passwords.yaml`.
const _testToken = 'test-only-e2e-control-token';

/// Storage settings for run modes that have no committed config file.
const _storageEnvironment = {
  'EDUBOX_STORAGE_ENDPOINT': 'http://localhost:9000',
  'EDUBOX_STORAGE_PUBLIC_ENDPOINT': 'http://localhost:9000',
  'EDUBOX_STORAGE_BUCKET': 'edubox-test',
  'EDUBOX_STORAGE_REGION': 'us-east-1',
};

/// Contract section 2.8: the e2e control route exists only in the compose e2e
/// (`development`) and `test` run modes, and always requires its token.
void main() {
  withServerpod('e2e control route', (sessionBuilder, endpoints) {
    setUpAll(initTestAuthServices);

    late SeededFixtures seeded;
    setUp(() async {
      seeded = await seedPhase1(sessionBuilder);
    });

    test('set-role and clear-role change the fixture users row', () async {
      final session = sessionBuilder.build();
      final before = await EduboxUser.db.findById(
        session,
        seeded.userIds[FixtureKeys.nullRole]!,
      );
      expect(before!.role, isNull);

      await endpoints.e2e.run(
        sessionBuilder,
        token: _testToken,
        step: 'set-role',
        accountKey: FixtureKeys.nullRole,
        role: 'student',
      );
      expect(
        (await EduboxUser.db.findById(session, before.id!))!.role,
        'student',
      );

      await endpoints.e2e.run(
        sessionBuilder,
        token: _testToken,
        step: 'clear-role',
        accountKey: FixtureKeys.nullRole,
      );
      expect((await EduboxUser.db.findById(session, before.id!))!.role, isNull);
    });

    test('a wrong token is denied even when the route is enabled', () async {
      await expectLater(
        endpoints.e2e.run(
          sessionBuilder,
          token: 'wrong-token',
          step: 'set-role',
          accountKey: FixtureKeys.nullRole,
          role: 'student',
        ),
        throwsA(
          isA<AccessDeniedException>().having(
            (error) => error.reason,
            'reason',
            AccessDeniedReason.wrongRole,
          ),
        ),
      );
    });
  });

  withServerpod(
    'e2e control route in production',
    runMode: 'production',
    serverDirectory: Directory('test/integration/e2e/production'),
    (sessionBuilder, endpoints) {
      setUpAll(initTestAuthServices);

      test(
        'production denies even with e2eControl true and the right token',
        () async {
          await expectLater(
            endpoints.e2e.run(
              sessionBuilder,
              token: _testToken,
              step: 'set-role',
              accountKey: FixtureKeys.nullRole,
              role: 'student',
            ),
            throwsA(
              isA<AccessDeniedException>().having(
                (error) => error.reason,
                'reason',
                AccessDeniedReason.wrongRole,
              ),
            ),
          );
        },
      );
    },
  );

  group('e2e control run-mode gate', () {
    test(
      'production and staging reject the env override and the right token',
      () {
        for (final mode in ['production', 'staging']) {
          final config = EduboxConfig.load(
            runMode: mode,
            environment: {
              ..._storageEnvironment,
              'EDUBOX_E2E_CONTROL': 'true',
            },
          );
          expect(config.e2eControl, isFalse, reason: mode);
          expect(
            E2eEndpoint.authorize(
              runMode: mode,
              config: config,
              expectedToken: _testToken,
              providedToken: _testToken,
            ),
            isFalse,
            reason: mode,
          );
        }
      },
    );

    test('the compose e2e and test run modes allow an enabled route', () {
      final development = EduboxConfig.load(
        runMode: 'development',
        environment: {
          ..._storageEnvironment,
          'EDUBOX_E2E_CONTROL': 'true',
        },
      );
      expect(
        E2eEndpoint.authorize(
          runMode: 'development',
          config: development,
          expectedToken: _testToken,
          providedToken: _testToken,
        ),
        isTrue,
      );

      final testMode = EduboxConfig.load(runMode: 'test', environment: {});
      expect(testMode.e2eControl, isTrue);
      expect(
        E2eEndpoint.authorize(
          runMode: 'test',
          config: testMode,
          expectedToken: _testToken,
          providedToken: _testToken,
        ),
        isTrue,
      );
    });

    test('a disabled switch or a wrong token still denies', () {
      final config = EduboxConfig.load(runMode: 'test', environment: {});
      expect(
        E2eEndpoint.authorize(
          runMode: 'test',
          config: config,
          expectedToken: _testToken,
          providedToken: 'wrong-token',
        ),
        isFalse,
      );
      final disabled = EduboxConfig.load(
        runMode: 'development',
        environment: {
          ..._storageEnvironment,
          'EDUBOX_E2E_CONTROL': 'false',
        },
      );
      expect(
        E2eEndpoint.authorize(
          runMode: 'development',
          config: disabled,
          expectedToken: _testToken,
          providedToken: _testToken,
        ),
        isFalse,
      );
    });

    test('authorize rejects other run modes even for a hand-built config '
        'whose e2eControl is true', () {
      // Built directly, so EduboxConfig.load's run-mode gate never ran: only
      // the endpoint's own run-mode check stands between this config and the
      // route.
      final config = EduboxConfig(
        storage: StorageConfig(
          endpoint: Uri.parse('http://localhost:9000'),
          publicEndpoint: Uri.parse('http://localhost:9000'),
          bucket: 'edubox-test',
          region: 'us-east-1',
        ),
        e2eControl: true,
      );
      for (final mode in ['production', 'staging', 'preview', '']) {
        expect(
          E2eEndpoint.enabledForRunMode(mode, config),
          isFalse,
          reason: mode,
        );
        expect(
          E2eEndpoint.authorize(
            runMode: mode,
            config: config,
            expectedToken: _testToken,
            providedToken: _testToken,
          ),
          isFalse,
          reason: mode,
        );
      }
      // The same config is accepted in an allowed mode, so the denial above
      // comes from the run mode alone.
      expect(
        E2eEndpoint.authorize(
          runMode: 'test',
          config: config,
          expectedToken: _testToken,
          providedToken: _testToken,
        ),
        isTrue,
      );
    });

    test('the committed development mode leaves the route off', () {
      final config = EduboxConfig.load(
        runMode: 'development',
        environment: _storageEnvironment,
      );
      expect(config.e2eControl, isFalse);
    });
  });
}
