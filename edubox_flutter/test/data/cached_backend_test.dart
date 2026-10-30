import 'package:edubox_client/edubox_client.dart';
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/data/cached_backend.dart';
import 'package:edubox_flutter/src/local/local_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixture_api.dart';

void main() {
  late ManualNetworkController network;
  late FixtureEduBoxApi api;
  late CachedDataStore store;
  late CachedBackend backend;

  setUp(() {
    network = ManualNetworkController();
    api = FixtureEduBoxApi();
    store = CachedDataStore(EduBoxDatabase.inMemory());
    backend = CachedBackend(api: api, store: store, network: network);
  });

  tearDown(() async {
    await backend.dispose();
    network.dispose();
  });

  Future<void> signIn(String key) async {
    final account = FixtureSet.phase1().account(key);
    final result = await backend.auth.signIn(
      email: account.email,
      password: devPassword,
    );
    expect(result.isOk, isTrue, reason: '$result');
  }

  test('offline sign-in and check-again fail fast without dialing', () async {
    network.goOffline();
    final signIn = await backend.auth.signIn(
      email: 'hs.an@edubox.test',
      password: devPassword,
    );
    expect(signIn.errorOrNull, isA<BackendUnreachableError>());
    final refresh = await backend.auth.refreshProfile();
    expect(refresh.errorOrNull, isA<BackendUnreachableError>());
    expect(api.calls, 0);
  });

  test('offline data reads never dial the server', () async {
    await signIn(FixtureKeys.studentAn);
    await backend.library.library();
    final before = api.calls;
    network.goOffline();
    final cached = await backend.library.library();
    expect(cached.isStale, isTrue);
    await backend.profile.me();
    network.goReconnecting();
    await backend.library.library();
    expect(api.calls, before);
  });

  test(
    'sign-in trims and lower-cases the email and caches the session',
    () async {
      final result = await backend.auth.signIn(
        email: '  HS.An@EduBox.test ',
        password: devPassword,
      );
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.signedInEmail, 'hs.an@edubox.test');
      final cached = await store.readSession();
      expect(cached!.value.role, UserRole.student);
    },
  );

  test(
    'the reconnect transition refreshes the profile and the role home',
    () async {
      await signIn(FixtureKeys.teacherLan);
      expect((await backend.classes.mine()).valueOrNull, hasLength(3));
      network.goOffline();
      api.fixtures = api.fixtures.withReconnectDeltas();
      expect((await store.readTeacherClasses())!.value, hasLength(3));
      network.goOnline();
      await Future<void>.delayed(Duration.zero);
      await backend.reconnectRefresh;
      final cached = await store.readTeacherClasses();
      expect(cached!.value.map((c) => c.name), contains('8B'));
    },
  );

  test(
    'restore with no stored auth clears the cache and returns null',
    () async {
      await signIn(FixtureKeys.studentAn);
      await api.clearStoredAuth();
      final restored = await backend.auth.restoreSession();
      expect(restored.isOk, isTrue);
      expect(restored.valueOrNull, isNull);
      expect(await store.readSession(), isNull);
    },
  );

  test('restore online re-reads the role from the server', () async {
    await signIn(FixtureKeys.nullRole);
    api.setRole(FixtureKeys.nullRole, 'teacher');
    final restored = await backend.auth.restoreSession();
    expect(restored.valueOrNull!.role, UserRole.teacher);
    expect(restored.isStale, isFalse);
  });

  test('restore offline returns the cached session as stale', () async {
    await signIn(FixtureKeys.parentBinh);
    network.goOffline();
    final restored = await backend.auth.restoreSession();
    expect(restored.isStale, isTrue);
    expect(restored.valueOrNull!.role, UserRole.parent);
    expect(restored.valueOrNull!.linkedStudentName, 'Nguyễn Minh An');
  });

  test('sign-out offline clears the stored auth and the cache', () async {
    await signIn(FixtureKeys.studentAn);
    await backend.library.library();
    network.goOffline();
    final result = await backend.auth.signOut();
    expect(result.isOk, isTrue);
    expect(await store.readSession(), isNull);
    expect(await store.readStudentLibrary(), isNull);
    expect(await api.restoreStoredAuth(), isFalse);
  });

  test('offline role gate uses the cached session', () async {
    await signIn(FixtureKeys.studentAn);
    await backend.library.library();
    network.goOffline();
    expect(
      (await backend.classes.mine()).errorOrNull,
      isA<PermissionDeniedError>(),
    );
  });

  test(
    'ping offline throws BackendUnreachable inside BackendException',
    () async {
      await signIn(FixtureKeys.studentAn);
      network.goOffline();
      await expectLater(
        backend.diagnostics.pingStream().toList(),
        throwsA(
          isA<BackendException>().having(
            (e) => e.error,
            'error',
            isA<BackendUnreachableError>(),
          ),
        ),
      );
    },
  );
}
