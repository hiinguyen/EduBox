import 'dart:async';

import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/app/app_scope.dart';
import 'package:edubox_flutter/src/app/connectivity_state.dart';
import 'package:edubox_flutter/src/app/loadable.dart';
import 'package:edubox_flutter/src/app/session_controller.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
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
