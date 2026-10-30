import 'dart:typed_data';

import 'package:edubox_server/src/config/edubox_config.dart';
import 'package:edubox_server/src/e2e/e2e_control_settings.dart';
import 'package:edubox_server/src/generated/protocol.dart';
import 'package:edubox_server/src/storage/object_store.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/harness.dart';
import '../test_tools/serverpod_test_tools.dart';

/// Contract section 2.8: the e2e control route exists only in e2e/test
/// configuration and always requires its token.
void main() {
  withServerpod('e2e control route', (sessionBuilder, endpoints) {
    setUpAll(initTestAuthServices);

    late SeededFixtures seeded;
    setUp(() async {
      seeded = await seedPhase1(sessionBuilder);
      E2eControlSettings.configureForTest(
        enabled: true,
        token: 'test-e2e-token',
        store: _NoopStore(),
      );
    });
    tearDown(E2eControlSettings.reset);

    test('set-role and clear-role change the fixture users row', () async {
      final session = sessionBuilder.build();
      final before = await EduboxUser.db.findById(
        session,
        seeded.userIds[FixtureKeys.nullRole]!,
      );
      expect(before!.role, isNull);

      await endpoints.e2e.run(
        sessionBuilder,
        token: 'test-e2e-token',
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
        token: 'test-e2e-token',
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

    test('the route is rejected when e2e control is disabled', () async {
      E2eControlSettings.configureForTest(
        enabled: false,
        token: 'test-e2e-token',
        store: _NoopStore(),
      );
      await expectLater(
        endpoints.e2e.run(
          sessionBuilder,
          token: 'test-e2e-token',
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

    test('the committed run modes leave e2e control off', () {
      for (final mode in ['development', 'test']) {
        final config = EduboxConfig.load(runMode: mode);
        expect(config.e2eControl, isFalse, reason: mode);
      }
    });
  });
}

class _NoopStore implements ObjectStore {
  @override
  Future<void> put(
    Session session,
    String path,
    ByteData bytes, {
    String? contentType,
  }) async {}

  @override
  Future<ByteData> get(Session session, String path) async =>
      ByteData.sublistView(Uint8List(0));

  @override
  Future<Uri> signedGetUrl(
    Session session,
    String path, {
    Duration expiresIn = const Duration(minutes: 5),
  }) async => Uri.parse('http://localhost:9000/unused');

  @override
  Future<void> deletePrefix(Session session, String prefix) async {}
}
