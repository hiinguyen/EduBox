import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
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
      final network = ManualNetworkController(NetworkStatus.offline);
      final fake = FakeBackend(network: network);
      final result = await fake.auth.signIn(
        email: 'hs.an@edubox.test',
        password: devPassword,
      );
      expect(result.errorOrNull, isA<BackendUnreachableError>());
      await fake.dispose();
      network.dispose();
    });

    test(
      'offline with cache still returns every role home as stale data',
      () async {
        final network = ManualNetworkController();
        final fake = FakeBackend(network: network);
        await fake.auth.signIn(
          email: 'gv.lan@edubox.test',
          password: devPassword,
        );
        final fresh = await fake.classes.mine();
        expect(fresh.isStale, isFalse);
        final refreshedAt = fresh.cachedAt;
        network.goOffline();

        final cached = await fake.classes.mine();
        expect(cached.isOk, isTrue);
        expect(cached.isStale, isTrue);
        expect(cached.cachedAt, refreshedAt);
        expect((await fake.profile.me()).isOk, isTrue);
        await expectLater(
          fake.diagnostics.pingStream().toList(),
          throwsA(isA<Exception>()),
        );

        network.goOnline();
        await fake.auth.signOut();
        await fake.auth.signIn(
          email: 'hs.an@edubox.test',
          password: devPassword,
        );
        network.goOffline();
        expect((await fake.library.library()).isOk, isTrue);

        network.goOnline();
        await fake.auth.signOut();
        await fake.auth.signIn(
          email: 'ph.binh@edubox.test',
          password: devPassword,
        );
        network.goOffline();
        expect((await fake.parent.home()).isOk, isTrue);
        await fake.dispose();
        network.dispose();
      },
    );

    test(
      'offline without cache returns OfflineNoCache for every role home',
      () async {
        final network = ManualNetworkController();
        final fake = FakeBackend(network: network);

        await fake.auth.signIn(
          email: 'hs.an@edubox.test',
          password: devPassword,
        );
        fake.clearCache();
        network.goOffline();
        expect(
          (await fake.library.library()).errorOrNull,
          isA<OfflineNoCacheError>(),
        );
        expect(
          (await fake.profile.me()).errorOrNull,
          isA<OfflineNoCacheError>(),
        );

        network.goOnline();
        await fake.auth.signOut();
        await fake.auth.signIn(
          email: 'gv.lan@edubox.test',
          password: devPassword,
        );
        fake.clearCache();
        network.goOffline();
        expect(
          (await fake.classes.mine()).errorOrNull,
          isA<OfflineNoCacheError>(),
        );

        network.goOnline();
        await fake.auth.signOut();
        await fake.auth.signIn(
          email: 'ph.binh@edubox.test',
          password: devPassword,
        );
        fake.clearCache();
        network.goOffline();
        expect(
          (await fake.parent.home()).errorOrNull,
          isA<OfflineNoCacheError>(),
        );
        await fake.dispose();
        network.dispose();
      },
    );

    test('unauthenticated calls are sessionExpired', () async {
      final fake = FakeBackend();
      expect(
        (await fake.library.library()).errorOrNull,
        isA<SessionExpiredError>(),
      );
      await expectLater(
        fake.diagnostics.pingStream().toList(),
        throwsA(
          isA<BackendException>().having(
            (error) => error.error,
            'error',
            isA<SessionExpiredError>(),
          ),
        ),
      );
      await fake.dispose();
    });

    test('restoreSession survives offline, as a cached session must', () async {
      final network = ManualNetworkController();
      final fake = FakeBackend(network: network);
      await fake.auth.signIn(
        email: 'hs.an@edubox.test',
        password: devPassword,
      );
      network.goOffline();
      final restored = await fake.auth.restoreSession();
      expect(restored.valueOrNull!.signedInEmail, 'hs.an@edubox.test');
      expect(restored.isStale, isTrue);
      await fake.dispose();
      network.dispose();
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

    test('reconnect deltas can be applied mid-session', () async {
      final fake = FakeBackend();
      await fake.auth.signIn(
        email: 'hs.an@edubox.test',
        password: devPassword,
      );
      final before = await fake.library.library();
      fake.applyReconnectDeltas();
      final after = await fake.library.library();
      expect(
        after.valueOrNull!.items.length,
        before.valueOrNull!.items.length + 1,
      );
      expect(
        after.valueOrNull!.items.map((item) => item.title),
        contains('Ôn tập chương 1'),
      );
      await fake.dispose();
    });

    test('a held call stays pending until released', () async {
      final fake = FakeBackend();
      await fake.auth.signIn(
        email: 'hs.an@edubox.test',
        password: devPassword,
      );
      final gate = fake.holdCalls();
      var completed = false;
      final pending = fake.library.library().whenComplete(() {
        completed = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(completed, isFalse);
      fake.releaseCalls();
      await gate.future;
      expect((await pending).isOk, isTrue);
      await fake.dispose();
    });
  });
}
