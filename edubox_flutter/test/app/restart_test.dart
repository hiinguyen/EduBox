import 'dart:io';

import 'package:drift/native.dart';
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/app/app_scope.dart';
import 'package:edubox_flutter/src/app/edubox_app.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/data/cached_backend.dart';
import 'package:edubox_flutter/src/local/local_store.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/fixture_api.dart';
import '../support/app_harness.dart';

/// Host versions of exit criteria 5 and 6: the production data layer over
/// an on-disk drift file; the app root is re-created offline over the same
/// file (the E2E harness's in-process restart).
void main() {
  late Directory dir;
  late File file;
  late FixtureEduBoxApi api;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('edubox_restart_');
    file = File('${dir.path}/edubox.sqlite');
    api = FixtureEduBoxApi();
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<CachedBackend> pumpRoot(
    WidgetTester tester,
    ManualNetworkController network,
  ) async {
    final backend = CachedBackend(
      api: api,
      store: CachedDataStore(EduBoxDatabase(NativeDatabase(file))),
      network: network,
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: rootKey,
        child: EduBoxApp(
          key: UniqueKey(),
          services: AppServices(
            backend: backend,
            network: network,
            clock: fixedClock,
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    return backend;
  }

  Future<void> signIn(WidgetTester tester, String key) async {
    final account = FixtureSet.phase1().account(key);
    await tester.enterText(find.byKey(SignInKeys.email), account.email);
    await tester.enterText(find.byKey(SignInKeys.password), devPassword);
    await tester.tap(find.byKey(SignInKeys.submit));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

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

  for (final (role, key, probe) in [
    ('student', FixtureKeys.studentAn, 'Tế bào và mô'),
    ('teacher', FixtureKeys.teacherLan, '7A'),
    ('parent', FixtureKeys.parentBinh, 'Nguyễn Minh An'),
  ]) {
    testWidgets('$role: offline re-create renders the cached home', (
      tester,
    ) async {
      setWindow(tester, TestSizes.tablet);
      final network = ManualNetworkController();
      final first = await pumpRoot(tester, network);
      await signIn(tester, key);
      expect(find.text(probe), findsOneWidget);
      network.goOffline();
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(first.dispose);
      final callsBefore = api.calls;
      final second = await pumpRoot(tester, network);
      expect(find.text(probe), findsOneWidget);
      expect(find.text(vi.networkOffline), findsOneWidget);
      expect(api.calls, callsBefore, reason: 'no server call while offline');
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(second.dispose);
    });
  }

  for (final (role, key, message) in [
    ('student', FixtureKeys.studentAn, vi.studentHomeLibraryOfflineNoCache),
    ('teacher', FixtureKeys.teacherLan, vi.teacherClassesOfflineNoData),
    ('parent', FixtureKeys.parentBinh, vi.parentHomeOfflineNoData),
  ]) {
    testWidgets('$role: cleared cache offline re-create shows no data', (
      tester,
    ) async {
      setWindow(tester, TestSizes.tablet);
      final network = ManualNetworkController();
      final first = await pumpRoot(tester, network);
      await signIn(tester, key);
      // Clear only this role's home data, as the E2E criterion 6 test does.
      await tester.runAsync(() => clearRoleHome(first.store.db, role));
      network.goOffline();
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(first.dispose);
      final second = await pumpRoot(tester, network);
      expect(find.text(message), findsOneWidget);
      expect(find.text(vi.teacherClassesEmpty), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(second.dispose);
    });
  }
}
