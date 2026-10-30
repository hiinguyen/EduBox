import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/screens/parent_home/parent_home_screen.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

void main() {
  testWidgets('loaded: the label and the linked child name as the h1', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpEduApp(tester, signedInAs: FixtureKeys.parentBinh);
    expect(find.byKey(ParentHomeKeys.screen), findsOneWidget);
    expect(find.text(vi.parentHomeStudentLabel), findsOneWidget);
    expect(find.text('Nguyễn Minh An'), findsOneWidget);
    expect(
      find.bySemanticsLabel(vi.parentHomeStudentSemantics('Nguyễn Minh An')),
      findsOneWidget,
    );
    expect(find.byType(NavigationRail), findsNothing);
    semantics.dispose();
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('loading: label at once, a bar where the name goes', (
    tester,
  ) async {
    final app = await pumpEduApp(
      tester,
      signedInAs: FixtureKeys.parentBinh,
      settle: false,
    );
    app.fake.holdCalls();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(vi.parentHomeStudentLabel), findsOneWidget);
    expect(find.text('Nguyễn Minh An'), findsNothing);
    await expectAccessibilityGuidelines(tester);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Minh An'), findsOneWidget);
  });

  testWidgets('no linked child: neutral sentence with retry', (tester) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.parentNoChild);
    expect(find.text(vi.parentHomeNoChild), findsOneWidget);
    expect(find.text(vi.retry), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('offline with cache: the name and the strip', (tester) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.parentBinh);
    app.network.goOffline();
    await tester.pumpAndSettle();
    expect(find.text(vi.networkOffline), findsOneWidget);
    expect(find.text('Nguyễn Minh An'), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('offline without cache: neutral offline sentence and retry', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.parentError = const OfflineNoCacheError();
    await pumpEduApp(
      tester,
      fake: holder.fake,
      network: holder.network,
      signedInAs: FixtureKeys.parentBinh,
    );
    expect(find.text(vi.parentHomeOfflineNoData), findsOneWidget);
    expect(find.text(vi.retry), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('error: negative sentence; retry recovers', (tester) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.parentError = const UnexpectedBackendError();
    await pumpEduApp(
      tester,
      fake: holder.fake,
      network: holder.network,
      signedInAs: FixtureKeys.parentBinh,
    );
    expect(find.text(vi.parentHomeLoadError), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    holder.fake.clearFailures();
    await tester.tap(find.text(vi.retry));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Minh An'), findsOneWidget);
  });

  testWidgets('sign-out from the overflow is immediate', (tester) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.parentBinh);
    await tester.tap(find.byTooltip(vi.parentMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(vi.signOut));
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('sign-out failure shows a snackbar with retry', (tester) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.parentBinh);
    app.fake.signOutError = const UnexpectedBackendError();
    await tester.tap(find.byTooltip(vi.parentMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(vi.signOut));
    await tester.pumpAndSettle();
    expect(find.text(vi.signOutFailed), findsOneWidget);
    expect(find.byKey(ParentHomeKeys.screen), findsOneWidget);
  });

  testWidgets('200% text on a phone wraps the name, no overflow', (
    tester,
  ) async {
    await pumpEduApp(
      tester,
      size: TestSizes.phone,
      textScale: 2,
      signedInAs: FixtureKeys.parentBinh,
    );
    expect(tester.takeException(), isNull);
  });

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('tablet', TestSizes.tablet),
  ]) {
    testWidgets('golden: parent-home on $name', (tester) async {
      await pumpEduApp(tester, size: size, signedInAs: FixtureKeys.parentBinh);
      await expectScreenGolden(tester, 'parent_home_$name');
    });
  }
}
