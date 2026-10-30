import 'dart:async';

import 'package:edubox_flutter/src/app/app_scope.dart';
import 'package:edubox_flutter/src/app/edubox_app.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('the first frame paints appOpening before services resolve', (
    tester,
  ) async {
    setWindow(tester, TestSizes.tablet);
    final gate = Completer<AppServices>();
    await tester.pumpWidget(
      EduBoxBootstrap(createServices: () => gate.future),
    );

    expect(find.text(vi.appOpening), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    final network = ManualNetworkControllerHolder.create();
    gate.complete(
      AppServices(
        backend: network.fake,
        network: network.network,
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('a startup exception shows the start-failed panel; retry works', (
    tester,
  ) async {
    setWindow(tester, TestSizes.tablet);
    var attempts = 0;
    await tester.pumpWidget(
      EduBoxBootstrap(
        createServices: () async {
          attempts++;
          if (attempts == 1) throw StateError('database unavailable');
          final network = ManualNetworkControllerHolder.create();
          return AppServices(
            backend: network.fake,
            network: network.network,
            clock: fixedClock,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen.appStartFailed')), findsOneWidget);
    expect(find.text(vi.backendUnreachable), findsOneWidget);
    expect(find.text(vi.backendUnreachableHint), findsOneWidget);

    await tester.tap(find.byKey(const Key('block.retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });
}
