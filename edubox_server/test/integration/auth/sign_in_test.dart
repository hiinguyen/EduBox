@Tags(['integration'])
library;

import 'package:edubox_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../support/harness.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  // Sign-in runs its own transactions, which rollbacks do not support, so
  // this group seeds once into its ephemeral database and every test uses a
  // different account (failed attempts count towards the rate limit).
  withServerpod(
    'Sign-in (emailIdp.login)',
    rollbackDatabase: RollbackDatabase.disabled,
    (
      sessionBuilder,
      endpoints,
    ) {
      late SeededFixtures seeded;
      setUpAll(() async {
        initTestAuthServices();
        seeded = await seedPhase1(
          sessionBuilder,
          credentialsFor: {
            FixtureKeys.studentAn,
            FixtureKeys.studentHa,
            FixtureKeys.teacherLan,
            FixtureKeys.blockedStudent,
          },
        );
      });

      Future<AuthSuccess> login(String email, String password) => endpoints
          .emailIdp
          .login(anonymous(sessionBuilder), email: email, password: password);

      test('a seeded account signs in with the dev password', () async {
        final success = await login('hs.an@edubox.test', devPassword);
        expect(success.authUserId, seeded.authUserIds[FixtureKeys.studentAn]);
      });

      test('a wrong password and an unknown email give the same error', () async {
        final invalidCredentials = isA<EmailAccountLoginException>().having(
          (e) => e.reason,
          'reason',
          EmailAccountLoginExceptionReason.invalidCredentials,
        );
        // Sign-in records a rate-limit attempt in its own transaction, so these
        // calls must be sequential: concurrent calls would race the test
        // database's rollback gate.
        await expectLater(
          login('gv.lan@edubox.test', 'wrong-password'),
          throwsA(invalidCredentials),
        );
        await expectLater(
          login('nobody@edubox.test', devPassword),
          throwsA(invalidCredentials),
        );
      });

      test('repeated failures answer tooManyAttempts', () async {
        for (var i = 0; i < 5; i++) {
          await expectLater(
            login('hs.ha@edubox.test', 'wrong-$i'),
            throwsA(isA<EmailAccountLoginException>()),
          );
        }
        await expectLater(
          login('hs.ha@edubox.test', devPassword),
          throwsA(
            isA<EmailAccountLoginException>().having(
              (e) => e.reason,
              'reason',
              EmailAccountLoginExceptionReason.tooManyAttempts,
            ),
          ),
        );
      });

      test(
        'a blocked auth user is refused with AuthUserBlockedException',
        () async {
          await expectLater(
            login('hs.bi.khoa@edubox.test', devPassword),
            throwsA(isA<AuthUserBlockedException>()),
          );
        },
      );
    },
  );

  // Sign-in opens its own transaction, so this group commits instead of
  // rolling back and seeds once. None of the methods below write data.
  withServerpod(
    'No self-service accounts (exit criterion 12)',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      setUpAll(() async {
        initTestAuthServices();
        await seedPhase1(sessionBuilder);
      });

      test('emailIdp dispatches login only', () {
        final emailIdp = dispatchedMethods()
            .where((m) => m.startsWith('emailIdp.'))
            .toSet();
        expect(emailIdp, {'emailIdp.login'});
      });

      for (final method in [
        'startRegistration',
        'verifyRegistrationCode',
        'finishRegistration',
        'startPasswordReset',
        'verifyPasswordResetCode',
        'finishPasswordReset',
        'hasAccount',
      ]) {
        test('emailIdp.$method is not callable and creates nothing', () async {
          final session = sessionBuilder.build();
          final authUsersBefore = await AuthUser.db.count(session);
          final usersBefore = await EduboxUser.db.count(session);
          await expectLater(
            callThroughDispatch(anonymous(sessionBuilder), 'emailIdp', method, {
              'email': 'new.user@edubox.test',
            }),
            throwsA(isA<MethodNotFoundException>()),
          );
          expect(await AuthUser.db.count(session), authUsersBefore);
          expect(await EduboxUser.db.count(session), usersBefore);
          expect(await EmailAccountRequest.db.count(session), 0);
        });
      }

      test('sign-in with unknown credentials creates no auth user', () async {
        final session = sessionBuilder.build();
        final before = await AuthUser.db.count(session);
        final usersBefore = await EduboxUser.db.count(session);
        await expectLater(
          endpoints.emailIdp.login(
            anonymous(sessionBuilder),
            email: 'new.user@edubox.test',
            password: devPassword,
          ),
          throwsA(isA<EmailAccountLoginException>()),
        );
        expect(await AuthUser.db.count(session), before);
        expect(await EduboxUser.db.count(session), usersBefore);
      });
    },
  );

  withServerpod('Role is read per request (exit criterion 13)', (
    sessionBuilder,
    endpoints,
  ) {
    setUpAll(initTestAuthServices);

    test(
      'changing users.role changes the next call without a new sign-in',
      () async {
        final seeded = await seedPhase1(sessionBuilder);
        final teacher = signedInAs(
          sessionBuilder,
          seeded,
          FixtureKeys.teacherLan,
        );
        expect(await endpoints.classes.mine(teacher), isNotEmpty);

        final session = sessionBuilder.build();
        final row = await EduboxUser.db.findById(
          session,
          seeded.userIds[FixtureKeys.teacherLan]!,
        );
        await EduboxUser.db.updateRow(session, row!.copyWith(role: 'student'));

        await expectLater(
          endpoints.classes.mine(teacher),
          throwsA(
            isA<AccessDeniedException>().having(
              (e) => e.reason,
              'reason',
              AccessDeniedReason.wrongRole,
            ),
          ),
        );
        final library = await endpoints.content.library(teacher);
        expect(library.classes, isEmpty);
      },
    );
  });
}
