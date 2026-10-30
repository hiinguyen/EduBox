import 'dart:ui' show SemanticsAction;

import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/features/library/content_row.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:edubox_flutter/src/screens/student_home/student_home_screen.dart';
import 'package:edubox_flutter/src/shell/role_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

void main() {
  testWidgets('loaded: greeting with given name, class, date, newest 4', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    expect(find.text(vi.studentHomeGreeting('An')), findsOneWidget);
    expect(
      find.text(vi.studentHomeDateLine('7A', 'Thứ Năm, 29/10/2026')),
      findsOneWidget,
    );
    expect(find.text(vi.studentHomeLibraryTitle), findsOneWidget);
    expect(find.text(vi.studentHomeLibraryCount(6)), findsOneWidget);
    // Newest four by createdAt: 25, 24, 23, 22 October.
    expect(find.text('Từ vựng Tiếng Anh 7 - Unit 1'), findsOneWidget);
    expect(find.text('Nội quy lớp học'), findsOneWidget);
    expect(find.text('Tế bào và mô'), findsOneWidget);
    expect(find.text('Luyện tập: Phép cộng phân số'), findsOneWidget);
    expect(find.text('Phân số và số thập phân'), findsNothing);
    expect(find.text('Bản nháp: Hình học chương 2'), findsNothing);
    expect(find.text('Chuyển động cơ học'), findsNothing);
    expect(find.byKey(StudentHomeKeys.openLibrary), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('loading: skeleton rows, header and enabled button', (
    tester,
  ) async {
    final app = await pumpEduApp(
      tester,
      signedInAs: FixtureKeys.studentAn,
      settle: false,
    );
    // The restore already ran inside pumpWidget; hold the library load.
    app.fake.holdCalls();
    await tester.pump();
    await tester.pump();
    expect(find.text(vi.studentHomeLibraryTitle), findsOneWidget);
    expect(find.byKey(StudentHomeKeys.openLibrary), findsOneWidget);
    expect(find.text(vi.studentHomeLibraryCount(6)), findsNothing);
    await expectAccessibilityGuidelines(tester);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(find.text(vi.studentHomeLibraryCount(6)), findsOneWidget);
  });

  testWidgets('empty: no class shows the no-class sentences and no button', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.studentNoClass);
    expect(find.text(vi.studentNoClass), findsOneWidget);
    expect(find.text(vi.studentNoClassHint), findsOneWidget);
    expect(find.byKey(StudentHomeKeys.openLibrary), findsNothing);
    expect(
      find.text(vi.studentHomeDateOnly('Thứ Năm, 29/10/2026')),
      findsOneWidget,
    );
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('empty: class without approved content keeps the button', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.studentEmpty);
    expect(find.text(vi.libraryEmpty), findsOneWidget);
    expect(find.text(vi.libraryEmptyHint), findsOneWidget);
    expect(find.byKey(StudentHomeKeys.openLibrary), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('offline with cache: data and the networkOffline strip', (
    tester,
  ) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    app.network.goOffline();
    await tester.pumpAndSettle();
    expect(find.text(vi.networkOffline), findsOneWidget);
    expect(find.text(vi.studentHomeLibraryCount(6)), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('offline without cache: offline sentence with retry', (
    tester,
  ) async {
    final app = await pumpEduApp(
      tester,
      signedInAs: FixtureKeys.studentAn,
      settle: false,
    );
    app.fake.clearCache();
    app.network.goOffline();
    await tester.pumpAndSettle();
    expect(find.text(vi.studentHomeLibraryOfflineNoCache), findsOneWidget);
    expect(find.text(vi.retry), findsOneWidget);
    expect(find.text(vi.libraryEmpty), findsNothing);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('error with retry: sentence, retry recovers the panel', (
    tester,
  ) async {
    final network = ManualNetworkControllerHolder.create();
    network.fake.libraryError = const UnexpectedBackendError();
    await pumpEduApp(
      tester,
      fake: network.fake,
      network: network.network,
      signedInAs: FixtureKeys.studentAn,
    );
    expect(find.text(vi.studentHomeLibraryError), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    network.fake.clearFailures();
    await tester.tap(find.text(vi.retry));
    await tester.pumpAndSettle();
    expect(find.text(vi.studentHomeLibraryCount(6)), findsOneWidget);
  });

  testWidgets('profile or role failure: profile error and greeting fallback', (
    tester,
  ) async {
    for (final error in <BackendError>[
      const NotSetUpError(),
      const PermissionDeniedError(),
    ]) {
      final holder = ManualNetworkControllerHolder.create();
      holder.fake.libraryError = error;
      await pumpEduApp(
        tester,
        fake: holder.fake,
        network: holder.network,
        signedInAs: FixtureKeys.studentAn,
      );
      final reason = error.runtimeType.toString();
      expect(
        find.text(vi.studentHomeProfileError),
        findsOneWidget,
        reason: reason,
      );
      expect(
        find.text(vi.studentHomeGreetingNoName),
        findsOneWidget,
        reason: reason,
      );
      expect(find.text(vi.studentHomeGreeting('An')), findsNothing);
      expect(find.byKey(StudentHomeKeys.openLibrary), findsOneWidget);
      await expectAccessibilityGuidelines(tester);
    }
  });

  testWidgets('reconnect: strip reads reconnecting, then new item appears', (
    tester,
  ) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    app.network.goOffline();
    await tester.pumpAndSettle();
    app.fake.applyReconnectDeltas();
    app.fake.holdCalls();
    app.network.goOnline();
    await tester.pump();
    expect(find.text(vi.networkReconnecting), findsOneWidget);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(find.text(vi.networkReconnecting), findsNothing);
    expect(find.text(vi.studentHomeLibraryCount(7)), findsOneWidget);
    expect(find.text('Ôn tập chương 1'), findsOneWidget);
  });

  testWidgets('error after data: lastUpdatedAt hint over kept rows, retry', (
    tester,
  ) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    app.fake.libraryError = const UnexpectedBackendError();
    app.network.goOffline();
    await tester.pumpAndSettle();
    app.network.goOnline();
    await tester.pumpAndSettle();
    expect(find.text(vi.studentHomeLibraryError), findsOneWidget);
    expect(find.text(vi.lastUpdatedAt('09:14')), findsOneWidget);
    expect(find.text('Từ vựng Tiếng Anh 7 - Unit 1'), findsOneWidget);
    expect(find.text(vi.retry), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    app.fake.clearFailures();
    await tester.tap(find.text(vi.retry));
    await tester.pumpAndSettle();
    expect(find.text(vi.studentHomeLibraryError), findsNothing);
    expect(find.text(vi.studentHomeLibraryCount(6)), findsOneWidget);
  });

  testWidgets('rows are not tappable; the nav holds only built destinations', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    final row = find.ancestor(
      of: find.text('Tế bào và mô'),
      matching: find.byType(ContentRow),
    );
    expect(row, findsOneWidget);
    expect(
      tester
          .getSemantics(row)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    expect(
      find.descendant(of: row, matching: find.byType(InkWell)),
      findsNothing,
    );
    expect(
      find.descendant(of: row, matching: find.byType(GestureDetector)),
      findsNothing,
    );

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    final labels = [
      for (final destination in rail.destinations)
        (destination.label as Text).data,
    ];
    final built = <String>[
      vi.navHome,
      if (find
          .byKey(const Key('screen.studentLibrary'), skipOffstage: false)
          .evaluate()
          .isNotEmpty)
        vi.navLibrary,
    ];
    expect(labels, built);
    semantics.dispose();
  });

  testWidgets('sign-out asks first; confirm returns to sign-in', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    await tester.tap(find.byKey(const Key('shell.railSignOut')));
    await tester.pumpAndSettle();
    expect(find.text(vi.signOutConfirmTitle), findsOneWidget);
    expect(find.text(vi.signOutConfirmBody), findsOneWidget);
    expect(find.text(vi.signOutOfflineWarning), findsNothing);
    await expectAccessibilityGuidelines(tester);
    await tester.tap(find.byKey(const Key('signOut.confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('sign-out offline adds the warning; failure stays inline', (
    tester,
  ) async {
    final app = await pumpEduApp(
      tester,
      size: TestSizes.phone,
      signedInAs: FixtureKeys.studentAn,
    );
    app.network.goOffline();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shell.accountMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shell.menuSignOut')));
    await tester.pumpAndSettle();
    expect(find.text(vi.signOutOfflineWarning), findsOneWidget);
    app.fake.signOutError = const UnexpectedBackendError();
    await tester.tap(find.byKey(const Key('signOut.confirm')));
    await tester.pumpAndSettle();
    expect(find.text(vi.signOutFailed), findsOneWidget);
    await tester.tap(find.byKey(const Key('signOut.cancel')));
    await tester.pumpAndSettle();
    expect(find.text(vi.signOutConfirmTitle), findsNothing);
  });

  testWidgets('session expired on a data call routes to sign-in', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.libraryError = const SessionExpiredError();
    await pumpEduApp(
      tester,
      fake: holder.fake,
      network: holder.network,
      signedInAs: FixtureKeys.studentAn,
    );
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('layout: phone has an app bar, medium and up a rail', (
    tester,
  ) async {
    await pumpEduApp(
      tester,
      size: TestSizes.phone,
      signedInAs: FixtureKeys.studentAn,
    );
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byKey(const Key('shell.accountMenu')), findsOneWidget);
    await pumpEduApp(
      tester,
      size: TestSizes.tabletPortrait,
      signedInAs: FixtureKeys.studentAn,
    );
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(find.byType(RoleShell), findsOneWidget);
    await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    final large = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(large.extended, isTrue);
  });

  testWidgets('200% text on a phone reflows without overflow', (tester) async {
    await pumpEduApp(
      tester,
      size: TestSizes.phone,
      textScale: 2,
      signedInAs: FixtureKeys.studentAn,
    );
    expect(tester.takeException(), isNull);
    await expectAccessibilityGuidelines(tester);
  });

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('tablet', TestSizes.tablet),
  ]) {
    testWidgets('golden: student-home on $name', (tester) async {
      final app = await pumpEduApp(
        tester,
        size: size,
        signedInAs: FixtureKeys.studentAn,
      );
      await expectScreenGolden(tester, 'student_home_$name');
      app.network.goOffline();
      await tester.pumpAndSettle();
      await expectScreenGolden(tester, 'student_home_offline_$name');
    });
  }
}
