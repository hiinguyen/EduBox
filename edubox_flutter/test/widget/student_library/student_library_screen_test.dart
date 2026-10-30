import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/features/library/content_row.dart';
import 'package:edubox_flutter/src/screens/student_home/student_home_screen.dart';
import 'package:edubox_flutter/src/screens/student_library/student_library_screen.dart';
import 'package:edubox_flutter/src/shell/block_states.dart';
import 'package:edubox_flutter/src/shell/role_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

Future<TestApp> openLibrary(
  WidgetTester tester, {
  String student = FixtureKeys.studentAn,
  Size size = TestSizes.tablet,
  double textScale = 1,
  ManualNetworkControllerHolder? holder,
}) async {
  final app = await pumpEduApp(
    tester,
    size: size,
    textScale: textScale,
    signedInAs: student,
    fake: holder?.fake,
    network: holder?.network,
  );
  await tester.tap(find.text(vi.navLibrary).last);
  await tester.pumpAndSettle();
  return app;
}

void main() {
  testWidgets('full: exactly the approved fixtures, grouped by subject', (
    tester,
  ) async {
    await openLibrary(tester);
    expect(find.text(vi.libraryTitle), findsWidgets);
    expect(find.text(vi.libraryTotal(6)), findsOneWidget);
    final expected = FixtureSet.phase1().libraryOfStudent(
      FixtureKeys.studentAn,
    );
    for (final item in expected) {
      expect(find.text(item.title), findsWidgets, reason: item.title);
    }
    expect(find.text('Bản nháp: Hình học chương 2'), findsNothing);
    expect(find.text('Chuyển động cơ học'), findsNothing);
    for (final subject in ['Toán', 'Ngữ văn', 'Khoa học tự nhiên']) {
      expect(find.text(subject), findsOneWidget, reason: subject);
    }
    expect(find.text(vi.librarySubjectOther), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('group order: class subjects, then others, then Môn khác', (
    tester,
  ) async {
    await openLibrary(tester, size: TestSizes.tabletPortrait);
    double top(String text) => tester.getTopLeft(find.text(text).first).dy;
    expect(top('Toán'), lessThan(top('Ngữ văn')));
    expect(top('Ngữ văn'), lessThan(top('Khoa học tự nhiên')));
    expect(top('Khoa học tự nhiên'), lessThan(top('Tiếng Anh')));
    await tester.scrollUntilVisible(
      find.text(vi.librarySubjectOther),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text(vi.librarySubjectOther), findsOneWidget);
  });

  testWidgets('loading: h1 at once, skeleton announced as one label', (
    tester,
  ) async {
    final app = await pumpEduApp(
      tester,
      signedInAs: FixtureKeys.studentAn,
      settle: false,
    );
    app.fake.holdCalls();
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text(vi.navLibrary).last);
    await tester.pump();
    expect(find.text(vi.libraryTotal(6)), findsNothing);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(vi.libraryLoading), findsOneWidget);
    semantics.dispose();
    await expectAccessibilityGuidelines(tester);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(find.text(vi.libraryTotal(6)), findsOneWidget);
  });

  testWidgets('empty: one sentence, total reads 0', (tester) async {
    await openLibrary(tester, student: FixtureKeys.studentEmpty);
    expect(find.text(vi.libraryEmpty), findsOneWidget);
    expect(find.text(vi.libraryTotal(0)), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('offline with cache: rows and the networkOffline strip', (
    tester,
  ) async {
    final app = await openLibrary(tester);
    app.network.goOffline();
    await tester.pumpAndSettle();
    expect(find.text(vi.networkOffline), findsOneWidget);
    expect(find.text('Phân số và số thập phân'), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('cold offline start without cache shows libraryOfflineNoData', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.signInAs(FixtureKeys.studentAn);
    holder.fake.clearCache();
    holder.fake.hasCache = true;
    holder.fake.libraryError = const OfflineNoCacheError();
    await openLibrary(tester, holder: holder);
    expect(find.text(vi.libraryOfflineNoData), findsOneWidget);
    expect(find.text(vi.libraryEmpty), findsNothing);
    expect(find.byKey(const Key('block.retry')), findsNothing);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('error with retry, and error after data keeps the rows', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.libraryError = const UnexpectedBackendError();
    final app = await openLibrary(tester, holder: holder);
    expect(find.text(vi.libraryLoadError), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    app.fake.clearFailures();
    await tester.tap(find.text(vi.retry));
    await tester.pumpAndSettle();
    expect(find.text(vi.libraryTotal(6)), findsOneWidget);

    app.fake.libraryError = const UnexpectedBackendError();
    app.network.goOffline();
    await tester.pumpAndSettle();
    app.network.goOnline();
    await tester.pumpAndSettle();
    expect(find.text(vi.libraryLoadErrorWithTime('09:14')), findsOneWidget);
    expect(find.text('Phân số và số thập phân'), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    app.fake.clearFailures();
    await tester.tap(find.text(vi.retry));
    await tester.pumpAndSettle();
    expect(find.text(vi.libraryLoadErrorWithTime('09:14')), findsNothing);
    expect(find.text(vi.libraryTotal(6)), findsOneWidget);
  });

  testWidgets('Mở thư viện on the home selects this destination', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    await tester.tap(find.byKey(StudentHomeKeys.openLibrary));
    await tester.pumpAndSettle();
    expect(find.byKey(StudentLibraryKeys.header), findsOneWidget);
    final shell = tester.widget<RoleShell>(find.byType(RoleShell));
    expect(shell.selectedIndex, 1);
  });

  testWidgets('phone: bottom bar with both destinations', (tester) async {
    await openLibrary(tester, size: TestSizes.phone);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(StudentLibraryKeys.header), findsOneWidget);
  });

  testWidgets('tablet: two columns split column-major at ceil(n/2)', (
    tester,
  ) async {
    final app = await openLibrary(tester);
    app.fake.applyReconnectDeltas();
    app.network.goOffline();
    await tester.pumpAndSettle();
    app.network.goOnline();
    await tester.pumpAndSettle();
    expect(find.text(vi.libraryTotal(7)), findsOneWidget);

    Offset at(String title) => tester.getTopLeft(find.text(title).first);
    final luyenTap = at('Luyện tập: Phép cộng phân số');
    final onTap = at('Ôn tập chương 1');
    final phanSo = at('Phân số và số thập phân');
    // Split at ceil(3 / 2) = 2: two rows down the first column, then the
    // third at the top of the second column.
    expect(luyenTap.dx, onTap.dx);
    expect(onTap.dy, greaterThan(luyenTap.dy));
    expect(phanSo.dx, greaterThan(luyenTap.dx));
    expect(phanSo.dy, luyenTap.dy);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('panel padding: 16 on compact, 24 on tablet', (tester) async {
    Future<double> rowInset(Size size) async {
      await openLibrary(tester, size: size);
      final row = find.ancestor(
        of: find.text('Luyện tập: Phép cộng phân số'),
        matching: find.byType(ContentRow),
      );
      final panel = find.ancestor(
        of: row,
        matching: find.byType(EduPanel),
      );
      expect(row, findsOneWidget);
      expect(panel, findsOneWidget);
      return tester.getTopLeft(row).dx - tester.getTopLeft(panel).dx;
    }

    expect(await rowInset(TestSizes.phone), 16);
    expect(await rowInset(TestSizes.tablet), 24);
  });

  testWidgets('200% text: one column, no overflow', (tester) async {
    await openLibrary(tester, size: TestSizes.tablet, textScale: 2);
    expect(tester.takeException(), isNull);
    final first = tester.getTopLeft(
      find.text('Luyện tập: Phép cộng phân số').first,
    );
    final second = tester.getTopLeft(
      find.text('Phân số và số thập phân').first,
    );
    expect(first.dx, second.dx);
    expect(second.dy, greaterThan(first.dy));
    await expectAccessibilityGuidelines(tester);
  });

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('tablet', TestSizes.tablet),
  ]) {
    testWidgets('golden: student-library on $name', (tester) async {
      await openLibrary(tester, size: size);
      await expectScreenGolden(tester, 'student_library_$name');
    });
  }
}
