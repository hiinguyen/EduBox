import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

Future<void> fillAndSubmit(
  WidgetTester tester, {
  String email = 'hs.an@edubox.test',
  String password = devPassword,
}) async {
  await tester.enterText(find.byKey(SignInKeys.email), email);
  await tester.enterText(find.byKey(SignInKeys.password), password);
  await tester.tap(find.byKey(SignInKeys.submit));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('idle: heading, labelled fields, button and help line', (
    tester,
  ) async {
    await pumpEduApp(tester);
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
    expect(find.text(vi.signInTitle), findsWidgets);
    expect(find.bySemanticsLabel(vi.emailLabel), findsOneWidget);
    expect(find.bySemanticsLabel(vi.passwordLabel), findsOneWidget);
    expect(find.text(vi.signInHelp), findsOneWidget);
    expect(find.byKey(SignInKeys.status), findsNothing);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('validating: empty submit shows field errors and sends nothing', (
    tester,
  ) async {
    final app = await pumpEduApp(tester);
    await tester.tap(find.byKey(SignInKeys.submit));
    await tester.pumpAndSettle();
    expect(find.text(vi.emailRequired), findsOneWidget);
    expect(find.text(vi.passwordRequired), findsOneWidget);
    expect(app.fake.currentSession, isNull);
    await expectAccessibilityGuidelines(tester);
    await tester.enterText(find.byKey(SignInKeys.email), 'khong-co-a-cong');
    await tester.pump();
    expect(find.text(vi.emailInvalid), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('submitting: busy label, then the role home replaces sign-in', (
    tester,
  ) async {
    final app = await pumpEduApp(tester);
    app.fake.holdCalls();
    await tester.enterText(find.byKey(SignInKeys.email), 'hs.an@edubox.test');
    await tester.enterText(find.byKey(SignInKeys.password), devPassword);
    await tester.tap(find.byKey(SignInKeys.submit));
    await tester.pump();
    expect(find.text(vi.signInSubmitting), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsNothing);
  });

  testWidgets('wrong credentials: sentence, password cleared, email kept', (
    tester,
  ) async {
    await pumpEduApp(tester);
    await fillAndSubmit(tester, password: 'sai-mat-khau');
    expect(find.text(vi.signInWrongCredentials), findsOneWidget);
    final password = tester.widget<TextField>(find.byKey(SignInKeys.password));
    expect(password.controller!.text, isEmpty);
    final email = tester.widget<TextField>(find.byKey(SignInKeys.email));
    expect(email.controller!.text, 'hs.an@edubox.test');
    await expectAccessibilityGuidelines(tester);
    await tester.enterText(find.byKey(SignInKeys.password), 'x');
    await tester.pump();
    expect(find.text(vi.signInWrongCredentials), findsNothing);
  });

  testWidgets('backend unreachable: message, hint and retry that recovers', (
    tester,
  ) async {
    final app = await pumpEduApp(tester);
    app.fake.signInError = const BackendUnreachableError();
    await fillAndSubmit(tester);
    expect(find.text(vi.backendUnreachable), findsOneWidget);
    expect(find.text(vi.backendUnreachableHint), findsOneWidget);
    expect(find.byKey(SignInKeys.retry), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    app.fake.clearFailures();
    await tester.tap(find.byKey(SignInKeys.retry));
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsNothing);
  });

  testWidgets('too many attempts and account disabled: sentence, no retry', (
    tester,
  ) async {
    final app = await pumpEduApp(tester);
    app.fake.signInError = const TooManyAttemptsError();
    await fillAndSubmit(tester);
    expect(find.text(vi.signInTooManyAttempts), findsOneWidget);
    expect(find.byKey(SignInKeys.retry), findsNothing);
    await expectAccessibilityGuidelines(tester);
    app.fake.signInError = const AccountDisabledError();
    await tester.enterText(find.byKey(SignInKeys.password), devPassword);
    await tester.tap(find.byKey(SignInKeys.submit));
    await tester.pumpAndSettle();
    expect(find.text(vi.signInAccountDisabled), findsOneWidget);
    expect(find.byKey(SignInKeys.retry), findsNothing);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('unexpected failure: unknown-error sentence with retry', (
    tester,
  ) async {
    final app = await pumpEduApp(tester);
    app.fake.signInError = const UnexpectedBackendError();
    await fillAndSubmit(tester);
    expect(find.text(vi.signInUnknownError), findsOneWidget);
    expect(find.byKey(SignInKeys.retry), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('password visibility toggle swaps its tooltip', (tester) async {
    await pumpEduApp(tester);
    expect(find.byTooltip(vi.showPassword), findsOneWidget);
    await tester.tap(find.byKey(SignInKeys.togglePassword));
    await tester.pump();
    expect(find.byTooltip(vi.hidePassword), findsOneWidget);
  });

  testWidgets('200% text scale on a phone reflows without overflow', (
    tester,
  ) async {
    final app = await pumpEduApp(
      tester,
      size: TestSizes.phone,
      textScale: 2,
    );
    app.fake.signInError = const BackendUnreachableError();
    await fillAndSubmit(tester);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text(vi.signInHelp),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(vi.signInHelp), findsOneWidget);
  });

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('tablet', TestSizes.tablet),
  ]) {
    testWidgets('golden: sign-in idle and error on $name', (tester) async {
      final app = await pumpEduApp(tester, size: size);
      await expectScreenGolden(tester, 'sign_in_idle_$name');
      app.fake.signInError = const BackendUnreachableError();
      await fillAndSubmit(tester);
      await expectScreenGolden(tester, 'sign_in_unreachable_$name');
    });
  }
}
