@Tags(['integration'])
library;

import 'package:edubox_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/harness.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('profile.me', (sessionBuilder, endpoints) {
    setUpAll(initTestAuthServices);

    late SeededFixtures seeded;
    setUp(
      () async => seeded = await seedPhase1(
        sessionBuilder,
        credentialsFor: {FixtureKeys.noProfile},
      ),
    );

    Future<ProfileResult> me(String key) =>
        endpoints.profile.me(signedInAs(sessionBuilder, seeded, key));

    test('ready for each role, with only the caller\'s own profile', () async {
      for (final (key, role) in [
        (FixtureKeys.studentAn, UserRole.student),
        (FixtureKeys.teacherLan, UserRole.teacher),
        (FixtureKeys.parentBinh, UserRole.parent),
      ]) {
        final result = await me(key);
        final account = seeded.fixtures.account(key);
        expect(result.status, ProfileStatus.ready);
        expect(result.profile!.userId, seeded.userIds[key]);
        expect(result.profile!.role, role);
        expect(result.profile!.name, account.name);
        expect(result.profile!.email, account.email);
        expect(result.signedInEmail, account.email);
      }
    });

    test('a parent gets the linked child\'s name; others get none', () async {
      expect(
        (await me(FixtureKeys.parentBinh)).profile!.linkedStudentName,
        'Nguyễn Minh An',
      );
      expect(
        (await me(FixtureKeys.parentNoChild)).profile!.linkedStudentName,
        isNull,
      );
      expect(
        (await me(FixtureKeys.studentAn)).profile!.linkedStudentName,
        isNull,
      );
    });

    test('notSetUp for an auth user with no users row', () async {
      final result = await me(FixtureKeys.noProfile);
      expect(result.status, ProfileStatus.notSetUp);
      expect(result.profile, isNull);
      expect(result.signedInEmail, 'chua.thiet.lap@edubox.test');
    });

    test('notSetUp for a null role', () async {
      final result = await me(FixtureKeys.nullRole);
      expect(result.status, ProfileStatus.notSetUp);
      expect(result.profile, isNull);
      expect(result.signedInEmail, 'chua.co.vai.tro@edubox.test');
    });

    test('notSetUp, not an error, for an unknown role written with raw SQL '
        '(exit criterion 3)', () async {
      final session = sessionBuilder.build();
      final userId = seeded.userIds[FixtureKeys.studentAn]!;
      for (final raw in ['principal', 'Student', '', ' student']) {
        await session.db.unsafeExecute(
          'UPDATE "users" SET "role" = \$1 WHERE "id" = \$2',
          parameters: QueryParameters.positional([raw, userId]),
        );
        final result = await me(FixtureKeys.studentAn);
        expect(result.status, ProfileStatus.notSetUp, reason: raw);
        expect(result.profile, isNull);
      }
    });
  });
}
