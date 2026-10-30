import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/app/app_scope.dart';
import 'package:edubox_flutter/src/app/session_controller.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

AppStage stageOf(WidgetTester tester) => AppScope.of(
  tester.element(find.byType(Scaffold).first),
).session.stage;

void main() {
  testWidgets('opening shows the mark and appOpening, never a spinner', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.holdCalls();
    await pumpEduApp(
      tester,
      fake: holder.fake,
      network: holder.network,
      settle: false,
    );
    await tester.pump();
    expect(find.byKey(const Key('screen.appOpening')), findsOneWidget);
    expect(find.text(vi.appOpening), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await expectAccessibilityGuidelines(tester);
    holder.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(stageOf(tester), AppStage.signedOut);
  });

  testWidgets('app-start failure: panel, hint and a retry that recovers', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.restoreError = const BackendUnreachableError();
    await pumpEduApp(
      tester,
      fake: holder.fake,
      network: holder.network,
      signedInAs: FixtureKeys.studentAn,
    );
    expect(find.byKey(const Key('screen.appStartFailed')), findsOneWidget);
    expect(find.text(vi.backendUnreachable), findsOneWidget);
    expect(find.text(vi.backendUnreachableHint), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    holder.fake.clearFailures();
    await tester.tap(find.text(vi.retry));
    await tester.pumpAndSettle();
    expect(stageOf(tester), AppStage.home);
  });

  testWidgets('retry label starts at the message text column', (tester) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.restoreError = const BackendUnreachableError();
    await pumpEduApp(
      tester,
      fake: holder.fake,
      network: holder.network,
      signedInAs: FixtureKeys.studentAn,
    );
    final messageX = tester.getTopLeft(find.text(vi.backendUnreachable)).dx;
    final retryX = tester.getTopLeft(find.text(vi.retry)).dx;
    expect(retryX, messageX);
  });

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('tablet', TestSizes.tablet),
  ]) {
    testWidgets('golden: app start failed on $name', (tester) async {
      final holder = ManualNetworkControllerHolder.create();
      holder.fake.restoreError = const BackendUnreachableError();
      await pumpEduApp(
        tester,
        size: size,
        fake: holder.fake,
        network: holder.network,
        signedInAs: FixtureKeys.studentAn,
      );
      await expectScreenGolden(tester, 'app_start_failed_$name');
    });
  }
}
