import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/local/local_store.dart';
import 'package:edubox_flutter/src/screens/account_not_set_up/account_not_set_up_screen.dart';
import 'package:edubox_flutter/src/screens/parent_home/parent_home_screen.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:edubox_flutter/src/screens/student_home/student_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/e2e_harness.dart';

/// Clears one role's home data from the drift cache (criterion 6).
Future<void> clearRoleHome(EduBoxDatabase db, String role) async {
  switch (role) {
    case 'student':
      await db.delete(db.cachedLibraryItems).go();
      await db.delete(db.cachedLibraryClasses).go();
      await (db.delete(
        db.cachedSnapshots,
      )..where((t) => t.kind.equals('studentLibrary'))).go();
      break;
    case 'teacher':
      await db.delete(db.cachedClasses).go();
      await (db.delete(
        db.cachedSnapshots,
      )..where((t) => t.kind.equals('teacherClasses'))).go();
      break;
    case 'parent':
      await db.delete(db.cachedParentHomes).go();
      await (db.delete(
        db.cachedSnapshots,
      )..where((t) => t.kind.equals('parentHome'))).go();
      break;
  }
}

/// Phase 1 E2E (roadmap exit criteria 1-7 and 9) on the AVD against the
/// compose stack. Run with the contract's e2e command (contract.md 5).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late E2eHarness harness;
  final fixtures = FixtureSet.phase1();

  setUp(() async {
    harness = E2eHarness();
    await harness.setUp();
    await harness.control('reset');
  });

  tearDown(() => harness.dispose());

  testWidgets('1: student sees exactly the approved fixtures', (tester) async {
    await harness.pumpRoot(tester);
    await harness.signIn(tester, FixtureKeys.studentAn);
    await tester.tap(find.byKey(StudentHomeKeys.openLibrary));
    await settle(tester);
    final expected = fixtures.libraryOfStudent(FixtureKeys.studentAn);
    expect(find.text(vi.libraryTotal(expected.length)), findsOneWidget);
    for (final item in expected) {
      await tester.scrollUntilVisible(
        find.text(item.title),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(item.title), findsWidgets);
    }
    expect(find.text('Bản nháp: Hình học chương 2'), findsNothing);
    expect(find.text('Chuyển động cơ học'), findsNothing);
  });

  testWidgets('2: teacher lands on teacher-home, parent on parent-home', (
    tester,
  ) async {
    await harness.pumpRoot(tester);
    await harness.signIn(tester, FixtureKeys.teacherLan);
    expect(find.byKey(const Key('screen.teacherHome')), findsOneWidget);
    for (final item in fixtures.classesOfTeacher(FixtureKeys.teacherLan)) {
      expect(find.text(item.name), findsOneWidget);
    }
    await harness.signOut(tester);
    await harness.signIn(tester, FixtureKeys.parentBinh);
    expect(find.byKey(ParentHomeKeys.screen), findsOneWidget);
    expect(find.text('Nguyễn Minh An'), findsOneWidget);
  });

  for (final key in [FixtureKeys.noProfile, FixtureKeys.nullRole]) {
    testWidgets('3: $key lands on account-not-set-up', (tester) async {
      await harness.pumpRoot(tester);
      await harness.signIn(tester, key);
      expect(find.text(vi.accountNotSetUp), findsOneWidget);
      expect(find.text(vi.accountCheckAgain), findsOneWidget);
      expect(find.text(vi.signOut), findsOneWidget);
      expect(find.byKey(const Key('screen.studentHome')), findsNothing);
    });
  }

  testWidgets('3: check again sees the admin role fix', (tester) async {
    await harness.pumpRoot(tester);
    await harness.signIn(tester, FixtureKeys.nullRole);
    await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
    await settle(tester);
    expect(find.text(vi.accountStillNotSetUp), findsOneWidget);
    await harness.control('assign-role');
    await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
    await settle(tester);
    expect(find.byKey(const Key('screen.studentHome')), findsOneWidget);
  });

  testWidgets('4: wrong credentials show signInWrongCredentials', (
    tester,
  ) async {
    await harness.pumpRoot(tester);
    await harness.signIn(
      tester,
      FixtureKeys.studentHa,
      password: 'not-the-password',
    );
    expect(find.text(vi.signInWrongCredentials), findsOneWidget);
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  for (final (key, probe) in [
    (FixtureKeys.studentAn, 'Tế bào và mô'),
    (FixtureKeys.teacherLan, '7A'),
    (FixtureKeys.parentBinh, 'Nguyễn Minh An'),
  ]) {
    testWidgets('5: $key home renders offline from the store after restart', (
      tester,
    ) async {
      await harness.pumpRoot(tester);
      await harness.signIn(tester, key);
      expect(find.text(probe), findsOneWidget);
      harness.network.goOffline();
      await harness.pumpRoot(tester);
      expect(find.text(probe), findsOneWidget);
      expect(find.text(vi.networkOffline), findsOneWidget);
      if (key == FixtureKeys.studentAn) {
        await tester.tap(find.byKey(StudentHomeKeys.openLibrary));
        await settle(tester);
        expect(
          find.text(
            vi.libraryTotal(
              fixtures.libraryOfStudent(FixtureKeys.studentAn).length,
            ),
          ),
          findsOneWidget,
        );
      }
    });
  }

  for (final (key, role, message) in [
    (FixtureKeys.studentAn, 'student', vi.studentHomeLibraryOfflineNoCache),
    (FixtureKeys.teacherLan, 'teacher', vi.teacherClassesOfflineNoData),
    (FixtureKeys.parentBinh, 'parent', vi.parentHomeOfflineNoData),
  ]) {
    testWidgets('6: $role home without cache shows its offline-no-data', (
      tester,
    ) async {
      await harness.pumpRoot(tester);
      await harness.signIn(tester, key);
      await clearRoleHome(harness.backend.store.db, role);
      harness.network.goOffline();
      await harness.pumpRoot(tester);
      expect(find.text(message), findsOneWidget);
      if (role == 'student') {
        await tester.tap(find.text(vi.navLibrary).last);
        await settle(tester);
        expect(find.text(vi.libraryOfflineNoData), findsOneWidget);
      }
    });
  }

  testWidgets('7: reconnect shows the strip, then the new data', (
    tester,
  ) async {
    await harness.pumpRoot(tester);
    await harness.signIn(tester, FixtureKeys.studentAn);
    harness.network.goOffline();
    await settle(tester);
    expect(find.text(vi.networkOffline), findsOneWidget);
    await harness.control('reconnect-library');
    harness.network.goOnline();
    // The strip is transient: pump in a bounded loop until it appears, so
    // the run proves the reconnecting half and cannot hang.
    var sawReconnecting = false;
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(vi.networkReconnecting).evaluate().isNotEmpty) {
        sawReconnecting = true;
        break;
      }
    }
    expect(
      sawReconnecting,
      isTrue,
      reason: 'the networkReconnecting strip was never shown',
    );
    await waitFor(tester, find.text(reconnectDeltaContent.title));
    await settle(tester);
    expect(find.text(vi.networkReconnecting), findsNothing);
    expect(find.text(vi.networkOffline), findsNothing);
  });

  testWidgets('7: reconnect shows the teacher the new class', (tester) async {
    await harness.pumpRoot(tester);
    await harness.signIn(tester, FixtureKeys.teacherLan);
    harness.network.goOffline();
    await settle(tester);
    await harness.control('reconnect-classes');
    harness.network.goOnline();
    await waitFor(tester, find.text(reconnectDeltaClass.name));
    await settle(tester);
    expect(find.text(vi.networkReconnecting), findsNothing);
    expect(find.text(vi.networkOffline), findsNothing);
  });

  testWidgets('9: pingStream reaches the app with the caller role', (
    tester,
  ) async {
    await harness.pumpRoot(tester);
    await harness.signIn(tester, FixtureKeys.teacherLan);
    final messages = await harness.backend.diagnostics
        .pingStream()
        .toList()
        .timeout(const Duration(seconds: 30));
    expect(messages.length, greaterThanOrEqualTo(2));
    expect(messages.every((m) => m.role.name == 'teacher'), isTrue);
  });
}
