import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/screens/account_not_set_up/account_not_set_up_screen.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

void main() {
  testWidgets('no-profile user lands here, never on a role home', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpEduApp(tester, signedInAs: FixtureKeys.noProfile);
    expect(find.byKey(AccountNotSetUpKeys.screen), findsOneWidget);
    expect(find.text(vi.accountNotSetUp), findsOneWidget);
    expect(find.text(vi.accountNotSetUpBody), findsOneWidget);
    expect(find.text('chua.thiet.lap@edubox.test'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        vi.accountSignedInAsSemantics('chua.thiet.lap@edubox.test'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
    expect(find.text(vi.accountCheckAgain), findsOneWidget);
    expect(find.text(vi.signOut), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('null-role user lands here too', (tester) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.nullRole);
    expect(find.text(vi.accountNotSetUp), findsOneWidget);
  });

  testWidgets('checking: busy label, sign-out disabled', (tester) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.nullRole);
    app.fake.holdCalls();
    await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
    await tester.pump();
    expect(find.text(vi.accountChecking), findsOneWidget);
    final signOut = tester.widget<FilledButton>(
      find.byKey(AccountNotSetUpKeys.signOut),
    );
    expect(signOut.onPressed, isNull);
    await expectAccessibilityGuidelines(tester);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
  });

  testWidgets('still not set up: muted sentence and the checked-at time', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.nullRole);
    await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
    await tester.pumpAndSettle();
    expect(find.text(vi.accountStillNotSetUp), findsOneWidget);
    expect(find.text(vi.accountCheckedAt('09:14')), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('offline check: the network sentence, no extra retry button', (
    tester,
  ) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.nullRole);
    app.network.goOffline();
    await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
    await tester.pumpAndSettle();
    expect(find.text(vi.accountCheckFailedOffline), findsOneWidget);
    expect(find.text(vi.retry), findsNothing);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('check failure: the account-info sentence', (tester) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.nullRole);
    app.fake.profileError = const UnexpectedBackendError();
    await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
    await tester.pumpAndSettle();
    expect(find.text(vi.studentHomeProfileError), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('role fixed by the admin: check again routes to the home', (
    tester,
  ) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.nullRole);
    app.fake.setRole(FixtureKeys.nullRole, 'student');
    await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
    await tester.pumpAndSettle();
    expect(find.byKey(AccountNotSetUpKeys.screen), findsNothing);
    expect(find.byKey(const Key('screen.studentHome')), findsOneWidget);
    expect(find.byKey(SignInKeys.screen), findsNothing);
  });

  testWidgets('expired session on check again routes to sign-in', (
    tester,
  ) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.nullRole);
    app.fake.profileError = const SessionExpiredError();
    await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('sign-out is immediate and returns to sign-in', (tester) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.noProfile);
    await tester.tap(find.byKey(AccountNotSetUpKeys.signOut));
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('signing out: busy label, check-again disabled', (tester) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.noProfile);
    app.fake.holdCalls();
    await tester.tap(find.byKey(AccountNotSetUpKeys.signOut));
    await tester.pump();
    expect(find.text(vi.signOutBusy), findsOneWidget);
    final checkAgain = tester.widget<OutlinedButton>(
      find.byKey(AccountNotSetUpKeys.checkAgain),
    );
    expect(checkAgain.onPressed, isNull);
    await expectAccessibilityGuidelines(tester);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('sign-out failure: snackbar with retry, screen stays', (
    tester,
  ) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.noProfile);
    app.fake.signOutError = const UnexpectedBackendError();
    await tester.tap(find.byKey(AccountNotSetUpKeys.signOut));
    await tester.pumpAndSettle();
    expect(find.text(vi.signOutFailed), findsOneWidget);
    expect(find.byKey(AccountNotSetUpKeys.screen), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    app.fake.signOutError = null;
    await tester.tap(find.text(vi.retry));
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('200% text on a phone scrolls without overflow', (tester) async {
    await pumpEduApp(
      tester,
      size: TestSizes.phone,
      textScale: 2,
      signedInAs: FixtureKeys.nullRole,
    );
    expect(tester.takeException(), isNull);
    for (final key in [
      AccountNotSetUpKeys.checkAgain,
      AccountNotSetUpKeys.signOut,
    ]) {
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      expect(find.byKey(key).hitTestable(), findsOneWidget);
    }
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('contact line keeps the button name on one line', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.nullRole);
    final name = vi.accountCheckAgain.replaceAll(' ', '\u00A0');
    final contact = vi.accountNotSetUpContact.replaceFirst(
      vi.accountCheckAgain,
      name,
    );
    expect(find.text(contact), findsOneWidget);
  });

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('tablet', TestSizes.tablet),
  ]) {
    testWidgets('golden: account-not-set-up on $name', (tester) async {
      await pumpEduApp(tester, size: size, signedInAs: FixtureKeys.nullRole);
      await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
      await tester.pumpAndSettle();
      await expectScreenGolden(tester, 'account_not_set_up_$name');
    });
  }
}
