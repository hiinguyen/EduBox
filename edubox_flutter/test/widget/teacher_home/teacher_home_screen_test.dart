import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:edubox_flutter/src/screens/teacher_home/teacher_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

void main() {
  testWidgets('loaded: own classes as a ledger, sorted, with - and 0', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.teacherLan);
    expect(find.text(vi.navTeacherOverview), findsWidgets);
    expect(find.text(vi.teacherClassesTitle), findsOneWidget);
    expect(find.text(vi.teacherClassesCount(3)), findsOneWidget);
    expect(find.byKey(TeacherHomeKeys.table), findsOneWidget);
    for (final header in [
      vi.classColumnName,
      vi.classColumnGrade,
      vi.classColumnSubjects,
      vi.classColumnStudents,
    ]) {
      expect(find.text(header), findsOneWidget, reason: header);
    }
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('7A'), lessThan(top('7B')));
    expect(top('7B'), lessThan(top('8A')));
    expect(find.text('Toán, Ngữ văn, Khoa học tự nhiên'), findsOneWidget);
    expect(find.text(vi.valueMissing), findsOneWidget); // 8A: no subjects.
    expect(find.text('0'), findsOneWidget); // 8A: no students.
    expect(find.text('9A'), findsNothing); // Another teacher's class.
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('loading: header, column heads and skeleton rows', (
    tester,
  ) async {
    final app = await pumpEduApp(
      tester,
      signedInAs: FixtureKeys.teacherLan,
      settle: false,
    );
    app.fake.holdCalls();
    await tester.pump();
    await tester.pump();
    expect(find.text(vi.teacherClassesTitle), findsOneWidget);
    expect(find.text(vi.classColumnName), findsOneWidget);
    expect(find.text(vi.teacherClassesCount(3)), findsNothing);
    await expectAccessibilityGuidelines(tester);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(find.text(vi.teacherClassesCount(3)), findsOneWidget);
  });

  testWidgets('empty: 0 classes, the sentence, no header row', (tester) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.teacherNoClass);
    expect(find.text(vi.teacherClassesCount(0)), findsOneWidget);
    expect(find.text(vi.teacherClassesEmpty), findsOneWidget);
    expect(find.text(vi.classColumnName), findsNothing);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('offline with cache: rows and the offline strip', (
    tester,
  ) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.teacherLan);
    app.network.goOffline();
    await tester.pumpAndSettle();
    expect(find.text(vi.networkOffline), findsOneWidget);
    expect(find.text('7A'), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('offline without cache: neutral sentence, never empty', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.classesError = const OfflineNoCacheError();
    await pumpEduApp(
      tester,
      fake: holder.fake,
      network: holder.network,
      signedInAs: FixtureKeys.teacherLan,
    );
    expect(find.text(vi.teacherClassesOfflineNoData), findsOneWidget);
    expect(find.text(vi.teacherClassesEmpty), findsNothing);
    expect(find.text(vi.retry), findsNothing);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('error: sentence and retry; error after data keeps rows', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.classesError = const UnexpectedBackendError();
    final app = await pumpEduApp(
      tester,
      fake: holder.fake,
      network: holder.network,
      signedInAs: FixtureKeys.teacherLan,
    );
    expect(find.text(vi.teacherClassesError), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    app.fake.clearFailures();
    await tester.tap(find.text(vi.retry));
    await tester.pumpAndSettle();
    expect(find.text('7A'), findsOneWidget);
    app.fake.classesError = const UnexpectedBackendError();
    app.network.goOffline();
    await tester.pumpAndSettle();
    app.network.goOnline();
    await tester.pumpAndSettle();
    expect(find.text(vi.teacherClassesStaleError('09:14')), findsOneWidget);
    expect(find.text('7A'), findsOneWidget);
  });

  testWidgets('reconnect: the new class appears without user action', (
    tester,
  ) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.teacherLan);
    app.network.goOffline();
    await tester.pumpAndSettle();
    app.fake.applyReconnectDeltas();
    app.fake.holdCalls();
    app.network.goOnline();
    await tester.pump();
    expect(find.text(vi.networkReconnecting), findsOneWidget);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(find.text('8B'), findsOneWidget);
    expect(find.text(vi.networkReconnecting), findsNothing);
  });

  testWidgets('sign-out is immediate from the large rail', (tester) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.teacherLan);
    await tester.tap(find.byKey(const Key('shell.railSignOut')));
    await tester.pumpAndSettle();
    expect(find.text(vi.signOutConfirmTitle), findsNothing);
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('sign-out failure shows a snackbar with retry', (tester) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.teacherLan);
    app.fake.signOutError = const UnexpectedBackendError();
    await tester.tap(find.byKey(const Key('shell.railSignOut')));
    await tester.pumpAndSettle();
    expect(find.text(vi.signOutFailed), findsOneWidget);
    expect(find.byKey(TeacherHomeKeys.panel), findsOneWidget);
    app.fake.clearFailures();
    await tester.tap(find.text(vi.retry));
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('phone: stacked rows, account menu signs out', (tester) async {
    await pumpEduApp(
      tester,
      size: TestSizes.phone,
      signedInAs: FixtureKeys.teacherLan,
    );
    expect(find.byKey(TeacherHomeKeys.stacked), findsOneWidget);
    expect(find.text(vi.classStudentCount(1)), findsWidgets);
    expect(find.text(vi.classGradeValue(7)), findsWidgets);
    expect(find.byType(NavigationBar), findsNothing);
    await expectAccessibilityGuidelines(tester);
    await tester.tap(find.byKey(const Key('shell.accountMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shell.menuSignOut')));
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('200% text at tablet width switches to stacked rows', (
    tester,
  ) async {
    await pumpEduApp(
      tester,
      size: TestSizes.tabletPortrait,
      textScale: 2,
      signedInAs: FixtureKeys.teacherLan,
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(TeacherHomeKeys.stacked), findsOneWidget);
  });

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('tablet', TestSizes.tablet),
  ]) {
    testWidgets('golden: teacher-home on $name', (tester) async {
      await pumpEduApp(tester, size: size, signedInAs: FixtureKeys.teacherLan);
      await expectScreenGolden(tester, 'teacher_home_$name');
    });
  }
}
