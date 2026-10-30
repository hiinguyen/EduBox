import 'dart:async';

import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/app/app_scope.dart';
import 'package:edubox_flutter/src/app/connectivity_state.dart';
import 'package:edubox_flutter/src/app/loadable.dart';
import 'package:edubox_flutter/src/app/session_controller.dart';
import 'package:edubox_flutter/src/contract/backend.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/contract/repositories.dart';
import 'package:edubox_flutter/src/contract/session.dart';
import 'package:edubox_flutter/src/fake/fake_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

AppStage stageOf(WidgetTester tester) => AppScope.of(
  tester.element(find.byType(Scaffold).first),
).session.stage;

void main() {
  group('SessionController', () {
    late ManualNetworkController network;
    late FakeBackend fake;
    late ConnectivityState connectivity;
    late SessionController session;

    setUp(() {
      network = ManualNetworkController();
      fake = FakeBackend(network: network);
      connectivity = ConnectivityState(network);
      session = SessionController(fake, connectivity: connectivity);
    });

    tearDown(() {
      session.dispose();
      connectivity.dispose();
    });

    test('starts in opening, then signedOut with nothing stored', () async {
      expect(session.stage, AppStage.opening);
      await session.start();
      expect(session.stage, AppStage.signedOut);
      expect(session.session, isNull);
    });

    test('a stored role session restores to home', () async {
      fake.signInAs(FixtureKeys.teacherLan);
      await session.start();
      expect(session.stage, AppStage.home);
      expect(session.session!.role!.name, 'teacher');
      expect(session.sessionRefreshedAt, isNotNull);
    });

    test('a stored not-set-up session restores to notSetUp', () async {
      fake.signInAs(FixtureKeys.noProfile);
      await session.start();
      expect(session.stage, AppStage.notSetUp);
    });

    test('an unreachable restore is startFailed; retry recovers', () async {
      fake.signInAs(FixtureKeys.studentAn);
      fake.restoreError = const BackendUnreachableError();
      await session.start();
      expect(session.stage, AppStage.startFailed);
      fake.clearFailures();
      await session.start();
      expect(session.stage, AppStage.home);
    });

    test('offline restore uses the cached session', () async {
      fake.signInAs(FixtureKeys.parentBinh);
      network.goOffline();
      await session.start();
      expect(session.stage, AppStage.home);
    });

    test(
      'an offline-restored session is re-resolved when online returns',
      () async {
        fake.signInAs(FixtureKeys.studentAn);
        network.goOffline();
        await session.start();
        expect(session.stage, AppStage.home);
        expect(session.session!.role!.name, 'student');

        fake.setRole(FixtureKeys.studentAn, 'teacher');
        network.goOnline();
        await pumpEventQueue();

        expect(session.stage, AppStage.home);
        expect(session.session!.role!.name, 'teacher');
      },
    );

    test(
      'a role removed while offline routes to notSetUp on reconnect',
      () async {
        fake.signInAs(FixtureKeys.studentAn);
        network.goOffline();
        await session.start();
        expect(session.stage, AppStage.home);

        // The admin removed the role: the server now answers notSetUp.
        fake.setRole(FixtureKeys.studentAn, 'removed');
        network.goOnline();
        await pumpEventQueue();

        expect(session.stage, AppStage.notSetUp);
      },
    );

    test('disposing during start does not notify after dispose', () async {
      final localNetwork = ManualNetworkController();
      final localFake = FakeBackend(network: localNetwork);
      final localConnectivity = ConnectivityState(localNetwork);
      final controller = SessionController(
        localFake,
        connectivity: localConnectivity,
      );
      localFake.holdCalls();
      final pending = controller.start();
      controller.dispose();
      localFake.releaseCalls();
      await pending;
      localConnectivity.dispose();
    });

    test('disposing during signOut does not notify after dispose', () async {
      final localNetwork = ManualNetworkController();
      final localFake = FakeBackend(network: localNetwork);
      final localConnectivity = ConnectivityState(localNetwork);
      final controller = SessionController(
        localFake,
        connectivity: localConnectivity,
      );
      localFake.signInAs(FixtureKeys.studentAn);
      await controller.start();
      localFake.holdCalls();
      final pending = controller.signOut();
      controller.dispose();
      localFake.releaseCalls();
      await pending;
      localConnectivity.dispose();
    });

    test('disposing during expire does not notify after dispose', () async {
      final localNetwork = ManualNetworkController();
      final localFake = FakeBackend(network: localNetwork);
      final localConnectivity = ConnectivityState(localNetwork);
      final controller = SessionController(
        localFake,
        connectivity: localConnectivity,
      );
      localFake.signInAs(FixtureKeys.studentAn);
      await controller.start();
      localFake.holdCalls();
      final pending = controller.expire();
      controller.dispose();
      localFake.releaseCalls();
      await pending;
      localConnectivity.dispose();
    });

    test('signOut goes to signedOut; a failure keeps the stage', () async {
      fake.signInAs(FixtureKeys.studentAn);
      await session.start();
      fake.signOutError = const UnexpectedBackendError();
      expect(await session.signOut(), isA<UnexpectedBackendError>());
      expect(session.stage, AppStage.home);
      fake.clearFailures();
      expect(await session.signOut(), isNull);
      expect(session.stage, AppStage.signedOut);
    });

    test('expire clears the session and goes to signedOut', () async {
      fake.signInAs(FixtureKeys.studentAn);
      await session.start();
      await session.expire();
      expect(session.stage, AppStage.signedOut);
      expect(fake.currentSession, isNull);
    });

    test(
      'a signOut during a reconnect refresh is not overwritten by it',
      () async {
        final localNetwork = ManualNetworkController();
        final gated = _GatedRefreshBackend(
          FakeBackend(network: localNetwork),
        );
        final localConnectivity = ConnectivityState(localNetwork);
        final controller = SessionController(
          gated,
          connectivity: localConnectivity,
        );
        addTearDown(() {
          controller.dispose();
          localConnectivity.dispose();
          localNetwork.dispose();
        });

        gated.fake.signInAs(FixtureKeys.studentAn);
        localNetwork.goOffline();
        await controller.start();
        expect(controller.stage, AppStage.home);

        gated.holdRefresh();
        localNetwork.goOnline();
        await gated.refreshStarted.future;

        expect(await controller.signOut(), isNull);
        expect(controller.stage, AppStage.signedOut);

        gated.releaseRefresh();
        await pumpEventQueue();
        expect(controller.stage, AppStage.signedOut);
        expect(controller.session, isNull);
      },
    );
  });

  group('ConnectivityState', () {
    test(
      'strip follows the seam and shows reconnecting while reloads run',
      () async {
        final network = ManualNetworkController();
        final state = ConnectivityState(network);
        expect(state.strip, StripState.hidden);
        network.goOffline();
        expect(state.strip, StripState.offline);
        network.goReconnecting();
        expect(state.strip, StripState.reconnecting);
        final gate = Completer<void>();
        var reloads = 0;
        Future<void> reload() async {
          reloads++;
          await gate.future;
        }

        state.register(reload);
        network.goOnline();
        expect(reloads, 1);
        expect(state.strip, StripState.reconnecting);
        gate.complete();
        await pumpEventQueue();
        expect(state.strip, StripState.hidden);
        state.unregister(reload);
        network.goOffline();
        network.goOnline();
        expect(reloads, 1);
        state.dispose();
      },
    );
  });

  group('Loadable', () {
    test('keeps the last good value when a reload fails', () async {
      var fail = false;
      final loadable = Loadable<int>(
        () async => fail
            ? const BackendFailure<int>(UnexpectedBackendError())
            : BackendOk(42, cachedAt: DateTime.utc(2026, 10, 29)),
      );
      expect(loadable.hasValue, isFalse);
      await loadable.load();
      expect(loadable.value, 42);
      expect(loadable.cachedAt, DateTime.utc(2026, 10, 29));
      fail = true;
      await loadable.load();
      expect(loadable.value, 42);
      expect(loadable.error, isA<UnexpectedBackendError>());
      fail = false;
      await loadable.load();
      expect(loadable.error, isNull);
      loadable.dispose();
    });

    test('an older load cannot overwrite a newer result', () async {
      final gates = <int, Completer<BackendResult<int>>>{};
      var calls = 0;
      final loadable = Loadable<int>(() {
        final call = ++calls;
        return (gates[call] = Completer<BackendResult<int>>()).future;
      });
      final first = loadable.load();
      final second = loadable.load();
      gates[2]!.complete(
        BackendOk(2, cachedAt: DateTime.utc(2026, 10, 29, 9, 15)),
      );
      await second;
      gates[1]!.complete(
        BackendOk(1, cachedAt: DateTime.utc(2026, 10, 29, 9, 14)),
      );
      await first;
      expect(loadable.value, 2);
      expect(loadable.cachedAt, DateTime.utc(2026, 10, 29, 9, 15));
      expect(loadable.isLoading, isFalse);
      loadable.dispose();
    });

    test('an older load does not clear isLoading for a newer one', () async {
      final gates = <int, Completer<BackendResult<int>>>{};
      var calls = 0;
      final loadable = Loadable<int>(() {
        final call = ++calls;
        return (gates[call] = Completer<BackendResult<int>>()).future;
      });
      final first = loadable.load();
      final second = loadable.load();
      gates[1]!.complete(const BackendOk(1));
      await first;
      expect(loadable.isLoading, isTrue);
      expect(loadable.value, isNull);
      gates[2]!.complete(const BackendOk(2));
      await second;
      expect(loadable.isLoading, isFalse);
      expect(loadable.value, 2);
      loadable.dispose();
    });
  });

  group('app root', () {
    testWidgets('the root is MaterialApp, Vietnamese only, light only', (
      tester,
    ) async {
      await pumpEduApp(tester);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('vi'));
      expect(app.themeMode, ThemeMode.light);
      expect(app.theme!.colorScheme.primary, const Color(0xFF1F4C8F));
    });

    testWidgets('a stage change pops an open dialog', (tester) async {
      await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
      final context = tester.element(find.byType(Scaffold).first);
      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(title: Text(vi.signOut)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await AppScope.of(context).session.expire();
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byKey(const Key('screen.signIn')), findsOneWidget);
    });
  });
}

/// A backend whose reconnect `refreshProfile` computes its result at once
/// but stays pending until [releaseRefresh], so a test can complete a
/// sign-out while the refresh is in flight.
class _GatedRefreshBackend implements EduBoxBackend {
  _GatedRefreshBackend(this.fake);

  final FakeBackend fake;
  final refreshStarted = Completer<void>();
  Completer<void>? _gate;

  void holdRefresh() => _gate = Completer<void>();

  void releaseRefresh() {
    final gate = _gate;
    _gate = null;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  @override
  AuthRepository get auth => _GatedRefreshAuth(this);

  @override
  ProfileRepository get profile => fake.profile;

  @override
  ClassesRepository get classes => fake.classes;

  @override
  LibraryRepository get library => fake.library;

  @override
  ParentRepository get parent => fake.parent;

  @override
  DiagnosticsRepository get diagnostics => fake.diagnostics;

  @override
  Future<void> dispose() => fake.dispose();
}

class _GatedRefreshAuth implements AuthRepository {
  _GatedRefreshAuth(this.backend);

  final _GatedRefreshBackend backend;

  @override
  Future<BackendResult<AuthSession>> refreshProfile() async {
    final result = await backend.fake.auth.refreshProfile();
    if (!backend.refreshStarted.isCompleted) {
      backend.refreshStarted.complete();
    }
    final gate = backend._gate;
    if (gate != null) await gate.future;
    return result;
  }

  @override
  Future<BackendResult<AuthSession>> signIn({
    required String email,
    required String password,
  }) => backend.fake.auth.signIn(email: email, password: password);

  @override
  Future<BackendResult<AuthSession?>> restoreSession() =>
      backend.fake.auth.restoreSession();

  @override
  Future<BackendResult<void>> signOut() => backend.fake.auth.signOut();
}
