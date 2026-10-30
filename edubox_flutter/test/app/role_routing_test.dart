import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/app/app_scope.dart';
import 'package:edubox_flutter/src/screens/account_not_set_up/account_not_set_up_screen.dart';
import 'package:edubox_flutter/src/screens/parent_home/parent_home_screen.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('no stored session routes to sign-in', (tester) async {
    await pumpEduApp(tester);
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('each role restores straight into its own home', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    expect(find.byKey(const Key('screen.studentHome')), findsOneWidget);
    await pumpEduApp(tester, signedInAs: FixtureKeys.teacherLan);
    expect(find.byKey(const Key('screen.teacherHome')), findsOneWidget);
    await pumpEduApp(tester, signedInAs: FixtureKeys.parentBinh);
    expect(find.byKey(ParentHomeKeys.screen), findsOneWidget);
    await pumpEduApp(tester, signedInAs: FixtureKeys.nullRole);
    expect(find.byKey(AccountNotSetUpKeys.screen), findsOneWidget);
    await pumpEduApp(tester, signedInAs: FixtureKeys.noProfile);
    expect(find.byKey(AccountNotSetUpKeys.screen), findsOneWidget);
  });

  testWidgets('sign-in routes every role to its home', (tester) async {
    for (final (key, screen) in [
      (FixtureKeys.studentAn, const Key('screen.studentHome')),
      (FixtureKeys.teacherLan, const Key('screen.teacherHome')),
      (FixtureKeys.parentBinh, ParentHomeKeys.screen),
      (FixtureKeys.nullRole, AccountNotSetUpKeys.screen),
    ]) {
      await pumpEduApp(tester);
      final account = FixtureSet.phase1().account(key);
      await tester.enterText(find.byKey(SignInKeys.email), account.email);
      await tester.enterText(find.byKey(SignInKeys.password), devPassword);
      await tester.tap(find.byKey(SignInKeys.submit));
      await tester.pumpAndSettle();
      expect(find.byKey(screen), findsOneWidget, reason: key);
    }
  });

  testWidgets('offline start restores the cached session to its home', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.signInAs(FixtureKeys.teacherLan);
    holder.network.goOffline();
    await pumpEduApp(tester, fake: holder.fake, network: holder.network);
    expect(find.byKey(const Key('screen.teacherHome')), findsOneWidget);
    expect(find.text(vi.networkOffline), findsOneWidget);
    expect(find.text('7A'), findsOneWidget);
  });

  testWidgets('a stage change closes any open dialog', (tester) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    await tester.tap(find.byKey(const Key('shell.railSignOut')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    final context = tester.element(find.byType(AlertDialog));
    await AppScope.of(context).session.expire();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
    expect(app.fake.currentSession, isNull);
  });
}
