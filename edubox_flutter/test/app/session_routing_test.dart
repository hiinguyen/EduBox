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
    late SessionController session;

    setUp(() {
      network = ManualNetworkController();
      fake = FakeBackend(network: network);
      session = SessionController(fake);
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
  });
}
