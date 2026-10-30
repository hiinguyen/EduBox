import 'package:edubox_client/edubox_client.dart';
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/contract/session.dart';
import 'package:flutter_test/flutter_test.dart';

/// The contract every [EduBoxBackend] must satisfy.
///
/// Phase 1 runs it against `FakeBackend`; phase 5 imports the same function
/// and passes the generated-client binding (wrapped in the cache/network data
/// layer), so the screen code and the tests do not change when the real server
/// arrives.
typedef BackendFactory = Future<EduBoxBackend> Function();

/// A test hook for the account-not-set-up "check again" row: changes a
/// fixture's raw `users.role` on the server (or in the fake).
typedef SetRole = Future<void> Function(String accountKey, String? role);

void runBackendContractTests({
  required String name,
  required BackendFactory createBackend,
  BackendFactory? createUnreachableBackend,
  ManualNetworkController? network,
  SetRole? setRole,
  Future<void> Function()? clearCache,
  Future<void> Function()? resetState,
}) {
  group(name, () {
    late EduBoxBackend backend;

    // Real-server runs pass `resetState` (the e2e `reset` step) so a long-lived
    // server starts each suite run from the seeded fixtures; the wrong-password
    // and too-many-attempts cases would otherwise accumulate rate-limit hits.
    setUpAll(() async {
      final reset = resetState;
      if (reset != null) await reset();
    });

    setUp(() async => backend = await createBackend());
    tearDown(() => backend.dispose());

    Future<AuthSession> signInAs(String key) async {
      final account = FixtureSet.phase1().account(key);
      final result = await backend.auth.signIn(
        email: account.email,
        password: devPassword,
      );
      expect(result.isOk, isTrue, reason: 'sign-in failed for $key: $result');
      expect(result.cachedAt, isNotNull);
      return result.valueOrNull!;
    }

    test('student signs in, resolves the student role, and reads the library '
        'with exactly the approved fixture content', () async {
      final session = await signInAs(FixtureKeys.studentAn);
      expect(session.isReady, isTrue);
      expect(session.role, UserRole.student);
      expect(session.profile!.name, 'Nguyễn Minh An');
      expect(session.profile!.email, 'hs.an@edubox.test');

      final me = await backend.profile.me();
      expect(me.valueOrNull!.status, ProfileStatus.ready);
      expect(me.valueOrNull!.profile!.role, UserRole.student);

      final library = await backend.library.library();
      expect(library.isOk, isTrue);
      final expected = FixtureSet.phase1().libraryOfStudent(
        FixtureKeys.studentAn,
      );
      expect(
        library.valueOrNull!.items.map((item) => item.title).toList(),
        expected.map((item) => item.title).toList(),
      );
      expect(
        library.valueOrNull!.items.map((item) => item.title),
        isNot(contains('Bản nháp: Hình học chương 2')),
      );
      expect(
        library.valueOrNull!.items.map((item) => item.title),
        isNot(contains(defaultOtherClassTitle)),
      );
      expect(library.valueOrNull!.classes.single.name, '7A');
      expect(library.valueOrNull!.classes.single.subjects, [
        'Toán',
        'Ngữ văn',
        'Khoa học tự nhiên',
      ]);
    });

    test('the empty-library and empty-teacher fixtures are reachable without '
        'a hand-built FixtureSet', () async {
      await signInAs(FixtureKeys.studentEmpty);
      final library = await backend.library.library();
      expect(library.isOk, isTrue);
      expect(library.valueOrNull!.items, isEmpty);
      expect(library.valueOrNull!.classes.single.name, '6C');

      await backend.auth.signOut();
      await signInAs(FixtureKeys.teacherNoClass);
      final classes = await backend.classes.mine();
      expect(classes.isOk, isTrue);
      expect(classes.valueOrNull, isEmpty);
    });

    test('teacher signs in and sees only their own classes', () async {
      final session = await signInAs(FixtureKeys.teacherLan);
      expect(session.role, UserRole.teacher);

      final result = await backend.classes.mine();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.map((item) => item.name), ['7A', '7B', '8A']);
      expect(result.valueOrNull!.first.subjects, [
        'Toán',
        'Ngữ văn',
        'Khoa học tự nhiên',
      ]);
      expect(
        result.valueOrNull!.map((item) => item.name),
        isNot(contains('9A')),
      );
    });

    test('parent signs in and reads the linked child name', () async {
      final session = await signInAs(FixtureKeys.parentBinh);
      expect(session.role, UserRole.parent);
      expect(session.linkedStudentName, 'Nguyễn Minh An');

      final result = await backend.parent.home();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.linkedStudentName, 'Nguyễn Minh An');
      expect(result.valueOrNull!.hasLinkedChild, isTrue);
    });

    test('an auth user without a profile resolves to notSetUp', () async {
      final session = await signInAs(FixtureKeys.noProfile);
      expect(session.isReady, isFalse);
      expect(session.status, ProfileStatus.notSetUp);
      expect(session.signedInEmail, 'chua.thiet.lap@edubox.test');

      final me = await backend.profile.me();
      expect(me.isOk, isTrue);
      expect(me.valueOrNull!.status, ProfileStatus.notSetUp);
      expect(me.valueOrNull!.profile, isNull);
    });

    test('a user with a null role resolves to notSetUp', () async {
      final session = await signInAs(FixtureKeys.nullRole);
      expect(session.isReady, isFalse);
      expect(session.status, ProfileStatus.notSetUp);
    });

    test(
      'wrong credentials are typed and reveal no account existence',
      () async {
        final wrongPassword = await backend.auth.signIn(
          email: 'hs.an@edubox.test',
          password: 'not-the-password',
        );
        final unknownEmail = await backend.auth.signIn(
          email: 'nobody@edubox.test',
          password: devPassword,
        );
        expect(wrongPassword.errorOrNull, isA<WrongCredentialsError>());
        expect(unknownEmail.errorOrNull, isA<WrongCredentialsError>());
      },
    );

    test('a blocked auth user is accountDisabled', () async {
      final account = FixtureSet.phase1().account(FixtureKeys.blockedStudent);
      final result = await backend.auth.signIn(
        email: account.email,
        password: devPassword,
      );
      expect(result.errorOrNull, isA<AccountDisabledError>());
    });

    test(
      'repeated failures on the dedicated account answer tooManyAttempts',
      () async {
        final account = FixtureSet.phase1().account(
          FixtureKeys.rateLimitStudent,
        );
        for (var attempt = 0; attempt < 5; attempt++) {
          await backend.auth.signIn(
            email: account.email,
            password: 'wrong-$attempt',
          );
        }
        final result = await backend.auth.signIn(
          email: account.email,
          password: devPassword,
        );
        expect(result.errorOrNull, isA<TooManyAttemptsError>());
      },
    );

    test(
      'not-set-up callers are denied with NotSetUp on every role method',
      () async {
        for (final key in [FixtureKeys.noProfile, FixtureKeys.nullRole]) {
          await backend.auth.signOut();
          await signInAs(key);
          expect(
            (await backend.classes.mine()).errorOrNull,
            isA<NotSetUpError>(),
            reason: key,
          );
          expect(
            (await backend.library.library()).errorOrNull,
            isA<NotSetUpError>(),
            reason: key,
          );
          await expectLater(
            backend.diagnostics.pingStream().toList(),
            throwsA(
              isA<BackendException>().having(
                (error) => error.error,
                'error',
                isA<NotSetUpError>(),
              ),
            ),
            reason: key,
          );
        }
      },
    );

    test('every role method denies a wrong role', () async {
      await signInAs(FixtureKeys.studentAn);
      expect(
        (await backend.classes.mine()).errorOrNull,
        isA<PermissionDeniedError>(),
      );
      expect(
        (await backend.parent.home()).errorOrNull,
        isA<PermissionDeniedError>(),
      );

      await backend.auth.signOut();
      await signInAs(FixtureKeys.teacherLan);
      expect(
        (await backend.library.library()).errorOrNull,
        isA<PermissionDeniedError>(),
      );
      expect(
        (await backend.parent.home()).errorOrNull,
        isA<PermissionDeniedError>(),
      );
    });

    test('unauthenticated calls are sessionExpired', () async {
      expect(
        (await backend.profile.me()).errorOrNull,
        isA<SessionExpiredError>(),
      );
      expect(
        (await backend.classes.mine()).errorOrNull,
        isA<SessionExpiredError>(),
      );
      expect(
        (await backend.library.library()).errorOrNull,
        isA<SessionExpiredError>(),
      );
      expect(
        (await backend.parent.home()).errorOrNull,
        isA<SessionExpiredError>(),
      );
      await expectLater(
        backend.diagnostics.pingStream().toList(),
        throwsA(
          isA<BackendException>().having(
            (error) => error.error,
            'error',
            isA<SessionExpiredError>(),
          ),
        ),
      );
    });

    test('restoreSession returns null when nothing is stored', () async {
      final result = await backend.auth.restoreSession();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('signOut clears the session', () async {
      await signInAs(FixtureKeys.studentAn);
      final result = await backend.auth.signOut();
      expect(result.isOk, isTrue);
      expect(
        (await backend.library.library()).errorOrNull,
        isA<SessionExpiredError>(),
      );
    });

    test('pingStream emits three messages with the caller role', () async {
      final session = await signInAs(FixtureKeys.studentAn);
      final messages = await backend.diagnostics.pingStream().toList();
      expect(messages, hasLength(3));
      expect(messages.map((message) => message.sequence), [1, 2, 3]);
      expect(
        messages.every((message) => message.role == session.role),
        isTrue,
      );
      expect(messages.every((message) => message.total == 3), isTrue);
    });

    if (setRole != null) {
      test(
        'refreshProfile sees the admin role fix without signing in again',
        () async {
          final before = await signInAs(FixtureKeys.nullRole);
          expect(before.isNotSetUp, isTrue);

          await setRole(FixtureKeys.nullRole, 'student');
          final after = await backend.auth.refreshProfile();
          expect(after.isOk, isTrue);
          expect(after.valueOrNull!.isReady, isTrue);
          expect(after.valueOrNull!.role, UserRole.student);

          // Keep the suite rerunnable against a long-lived server.
          await setRole(FixtureKeys.nullRole, null);
        },
      );
    }

    if (createUnreachableBackend != null) {
      test('an unreachable server is backendUnreachable', () async {
        final unreachable = await createUnreachableBackend();
        addTearDown(unreachable.dispose);
        final signIn = await unreachable.auth.signIn(
          email: 'hs.an@edubox.test',
          password: devPassword,
        );
        expect(signIn.errorOrNull, isA<BackendUnreachableError>());
        final me = await unreachable.profile.me();
        expect(me.errorOrNull, isA<BackendUnreachableError>());
      });
    }

    if (network != null) {
      test(
        'offline reads are stale cache results carrying their refresh time',
        () async {
          await signInAs(FixtureKeys.teacherLan);
          final fresh = await backend.classes.mine();
          expect(fresh.isOk, isTrue);
          expect(fresh.isStale, isFalse);
          final refreshedAt = fresh.cachedAt;
          expect(refreshedAt, isNotNull);

          network.goOffline();
          final cached = await backend.classes.mine();
          expect(cached.isOk, isTrue);
          expect(cached.isStale, isTrue);
          expect(cached.cachedAt, refreshedAt);

          network.goReconnecting();
          expect((await backend.classes.mine()).isStale, isTrue);

          network.goOnline();
          final refreshed = await backend.classes.mine();
          expect(refreshed.isOk, isTrue);
          expect(refreshed.isStale, isFalse);
          expect(refreshed.cachedAt, isNotNull);
        },
      );

      test('restoreSession survives offline from the cache', () async {
        await signInAs(FixtureKeys.studentAn);
        network.goOffline();
        final restored = await backend.auth.restoreSession();
        expect(restored.isOk, isTrue);
        expect(restored.valueOrNull!.signedInEmail, 'hs.an@edubox.test');
        expect(restored.isStale, isTrue);
        network.goOnline();
      });

      if (clearCache != null) {
        test(
          'offline without cache is OfflineNoCache for every role home',
          () async {
            await signInAs(FixtureKeys.studentAn);
            await clearCache();
            network.goOffline();
            expect(
              (await backend.library.library()).errorOrNull,
              isA<OfflineNoCacheError>(),
            );
            expect(
              (await backend.profile.me()).errorOrNull,
              isA<OfflineNoCacheError>(),
            );

            network.goOnline();
            await backend.auth.signOut();
            await signInAs(FixtureKeys.teacherLan);
            await clearCache();
            network.goOffline();
            expect(
              (await backend.classes.mine()).errorOrNull,
              isA<OfflineNoCacheError>(),
            );

            network.goOnline();
            await backend.auth.signOut();
            await signInAs(FixtureKeys.parentBinh);
            await clearCache();
            network.goOffline();
            expect(
              (await backend.parent.home()).errorOrNull,
              isA<OfflineNoCacheError>(),
            );
            network.goOnline();
          },
        );
      }
    }
  });
}

/// The title of the fixture approved for another teacher's class.
const defaultOtherClassTitle = 'Chuyển động cơ học';
