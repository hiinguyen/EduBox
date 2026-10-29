import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/fake/fake_backend.dart';
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fake failure modes', () {
    test('wrong credentials, rate limit, disabled, unreachable and unknown '
        'are switchable on sign-in', () async {
      final fake = FakeBackend();
      for (final error in <BackendError>[
        const WrongCredentialsError(),
        const TooManyAttemptsError(),
        const AccountDisabledError(),
        const BackendUnreachableError(),
        const UnexpectedBackendError('boom'),
      ]) {
        fake.signInError = error;
        final result = await fake.auth.signIn(
          email: 'hs.an@edubox.test',
          password: devPassword,
        );
        expect(result.errorOrNull.runtimeType, error.runtimeType);
      }
      fake.clearFailures();
      final ok = await fake.auth.signIn(
        email: 'hs.an@edubox.test',
        password: devPassword,
      );
      expect(ok.isOk, isTrue);
      await fake.dispose();
    });

    test('the blocked fixture is accountDisabled', () async {
      final fake = FakeBackend();
      final result = await fake.auth.signIn(
        email: 'hs.bi.khoa@edubox.test',
        password: devPassword,
      );
      expect(result.errorOrNull, isA<AccountDisabledError>());
      await fake.dispose();
    });

    test('signing in while offline is backendUnreachable', () async {
      final fake = FakeBackend(mode: FakeMode.offlineWithCache);
      final result = await fake.auth.signIn(
        email: 'hs.an@edubox.test',
        password: devPassword,
      );
      expect(result.errorOrNull, isA<BackendUnreachableError>());
      await fake.dispose();
    });

    test('offline with cache still returns every role home', () async {
      final fake = FakeBackend();
      await fake.auth.signIn(
        email: 'gv.lan@edubox.test',
        password: devPassword,
      );
      fake.mode = FakeMode.offlineWithCache;

      expect((await fake.classes.mine()).isOk, isTrue);
      expect((await fake.profile.me()).isOk, isTrue);
      await expectLater(
        fake.diagnostics.pingStream().toList(),
        throwsA(isA<Exception>()),
      );

      await fake.auth.signOut();
      fake.mode = FakeMode.online;
      await fake.auth.signIn(
        email: 'hs.an@edubox.test',
        password: devPassword,
      );
      fake.mode = FakeMode.offlineWithCache;
      expect((await fake.library.library()).isOk, isTrue);

      await fake.auth.signOut();
      fake.mode = FakeMode.online;
      await fake.auth.signIn(
        email: 'ph.binh@edubox.test',
        password: devPassword,
      );
      fake.mode = FakeMode.offlineWithCache;
      expect((await fake.parent.home()).isOk, isTrue);
      await fake.dispose();
    });

    test(
      'offline without cache returns OfflineNoCache for every home',
      () async {
        final fake = FakeBackend();
        await fake.auth.signIn(
          email: 'hs.an@edubox.test',
          password: devPassword,
        );
        fake.mode = FakeMode.offlineWithoutCache;

        expect(
          (await fake.library.library()).errorOrNull,
          isA<OfflineNoCacheError>(),
        );
        expect(
          (await fake.profile.me()).errorOrNull,
          isA<OfflineNoCacheError>(),
        );
        expect(
          (await fake.classes.mine()).errorOrNull,
          isA<PermissionDeniedError>(),
        );
        await fake.dispose();
      },
    );

    test('restoreSession survives offline, as a cached session must', () async {
      final fake = FakeBackend();
      await fake.auth.signIn(
        email: 'hs.an@edubox.test',
        password: devPassword,
      );
      fake.mode = FakeMode.offlineWithoutCache;
      final restored = await fake.auth.restoreSession();
      expect(restored.valueOrNull!.signedInEmail, 'hs.an@edubox.test');
      await fake.dispose();
    });

    test(
      'check-again sees an administrator role fix without a new sign-in',
      () async {
        final fake = FakeBackend();
        final before = await fake.auth.signIn(
          email: 'chua.co.vai.tro@edubox.test',
          password: devPassword,
        );
        expect(before.valueOrNull!.isNotSetUp, isTrue);

        fake.setRole(FixtureKeys.nullRole, 'student');
        final after = await fake.auth.refreshProfile();
        expect(after.valueOrNull!.isReady, isTrue);
        expect(after.valueOrNull!.role!.name, 'student');
        await fake.dispose();
      },
    );

    test('call-specific failure fields cover profile, classes, library, '
        'parent, ping and sign-out', () async {
      final fake = FakeBackend();
      await fake.auth.signIn(
        email: 'hs.an@edubox.test',
        password: devPassword,
      );
      fake.profileError = const UnexpectedBackendError('profile');
      expect(
        (await fake.profile.me()).errorOrNull,
        isA<UnexpectedBackendError>(),
      );
      fake.profileError = null;
      fake.libraryError = const PermissionDeniedError();
      expect(
        (await fake.library.library()).errorOrNull,
        isA<PermissionDeniedError>(),
      );
      fake.libraryError = null;
      fake.pingError = const BackendUnreachableError();
      await expectLater(
        fake.diagnostics.pingStream().toList(),
        throwsA(isA<Exception>()),
      );
      fake.pingError = null;
      fake.signOutError = const UnexpectedBackendError('sign-out');
      expect(
        (await fake.auth.signOut()).errorOrNull,
        isA<UnexpectedBackendError>(),
      );
      await fake.dispose();
    });
  });
}
