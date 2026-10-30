import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/contract/repositories.dart';
import 'package:edubox_flutter/src/contract/session.dart';
import 'package:edubox_flutter/src/fake/fake_backend.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:edubox_flutter/src/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

/// Counts the auth calls a screen makes, so a double press or a claim-read
/// retry is observable.
final class CountingAuth implements AuthRepository {
  CountingAuth(this._inner);

  final AuthRepository _inner;
  int signInCalls = 0;
  int refreshProfileCalls = 0;

  @override
  Future<BackendResult<AuthSession>> signIn({
    required String email,
    required String password,
  }) {
    signInCalls++;
    return _inner.signIn(email: email, password: password);
  }

  @override
  Future<BackendResult<AuthSession?>> restoreSession() =>
      _inner.restoreSession();

  @override
  Future<BackendResult<AuthSession>> refreshProfile() {
    refreshProfileCalls++;
    return _inner.refreshProfile();
  }

  @override
  Future<BackendResult<void>> signOut() => _inner.signOut();
}

final class CountingBackend implements EduBoxBackend {
  CountingBackend(this.fake) : auth = CountingAuth(fake.auth);

  final FakeBackend fake;

  @override
  final CountingAuth auth;

  @override
  ProfileRepository get profile => fake.profile;

  @override
  ClassesRepository get classes => fake.classes;

  @override
  LibraryRepository get library => fake.library;

  @override
  ParentRepository get parent => fake.parent;

  @override
  DiagnosticsRepository get diagnostics => fake.diagnostics;

  @override
  Future<void> dispose() => fake.dispose();
}

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
    final errors = find.byIcon(Icons.error_outline);
    expect(errors, findsNWidgets(2));
    for (final icon in tester.widgetList<Icon>(errors)) {
      expect(icon.size, EduSize.statusGlyph);
    }
    expect(
      tester
          .widget<TextField>(find.byKey(SignInKeys.email))
          .focusNode!
          .hasFocus,
      isTrue,
    );
    expect(app.fake.currentSession, isNull);
    await expectAccessibilityGuidelines(tester);
    await tester.enterText(find.byKey(SignInKeys.email), 'khong-co-a-cong');
    await tester.pump();
    expect(find.text(vi.emailInvalid), findsOneWidget);
    await expectAccessibilityGuidelines(tester);

    await tester.enterText(find.byKey(SignInKeys.email), 'hs.an@edubox.test');
    await tester.tap(find.byKey(SignInKeys.submit));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(SignInKeys.password))
          .focusNode!
          .hasFocus,
      isTrue,
    );
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
    expect(password.focusNode!.hasFocus, isTrue);
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

  testWidgets('retry label starts at the message text column', (tester) async {
    final app = await pumpEduApp(tester);
    app.fake.signInError = const BackendUnreachableError();
    await fillAndSubmit(tester);
    final messageX = tester.getTopLeft(find.text(vi.backendUnreachable)).dx;
    final retryX = tester.getTopLeft(find.text(vi.retry)).dx;
    expect(retryX, messageX);
  });

  testWidgets('a double press submits once', (tester) async {
    final network = ManualNetworkController();
    final fake = newFake(network);
    final backend = CountingBackend(fake);
    await pumpEduApp(
      tester,
      network: network,
      fake: fake,
      backend: backend,
    );
    fake.holdCalls();
    await tester.enterText(find.byKey(SignInKeys.email), 'hs.an@edubox.test');
    await tester.enterText(find.byKey(SignInKeys.password), devPassword);
    await tester.tap(find.byKey(SignInKeys.submit));
    await tester.pump();
    await tester.tap(find.byKey(SignInKeys.submit), warnIfMissed: false);
    await tester.pump();
    expect(backend.auth.signInCalls, 1);
    fake.releaseCalls();
    await tester.pumpAndSettle();
  });

  testWidgets('a submit that outlives the 15s timeout is unreachable', (
    tester,
  ) async {
    final app = await pumpEduApp(tester);
    app.fake.holdCalls();
    await tester.enterText(find.byKey(SignInKeys.email), 'hs.an@edubox.test');
    await tester.enterText(find.byKey(SignInKeys.password), devPassword);
    await tester.tap(find.byKey(SignInKeys.submit));
    await tester.pump();
    expect(find.text(vi.signInSubmitting), findsOneWidget);

    await tester.pump(SignInScreen.submitTimeout);
    await tester.pump();

    expect(find.text(vi.backendUnreachable), findsOneWidget);
    expect(find.byKey(SignInKeys.retry), findsOneWidget);
    expect(find.text(vi.signInSubmitting), findsNothing);
    app.fake.releaseCalls();
    await tester.pump();
  });

  testWidgets('retry after a successful sign-in only re-reads the claim', (
    tester,
  ) async {
    final network = ManualNetworkController();
    final fake = newFake(network);
    final backend = CountingBackend(fake);
    await pumpEduApp(
      tester,
      network: network,
      fake: fake,
      backend: backend,
    );
    fake.signInError = const BackendUnreachableError();
    await fillAndSubmit(tester);
    expect(find.text(vi.backendUnreachable), findsOneWidget);

    // The auth module kept the session; only the claim read failed.
    fake.signInAs(FixtureKeys.studentAn);
    fake.clearFailures();
    await tester.tap(find.byKey(SignInKeys.retry));
    await tester.pumpAndSettle();

    expect(find.byKey(SignInKeys.screen), findsNothing);
    expect(backend.auth.signInCalls, 1);
    expect(backend.auth.refreshProfileCalls, 1);
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

  testWidgets('password visibility toggle un-obscures and swaps its tooltip', (
    tester,
  ) async {
    await pumpEduApp(tester);
    TextField password() =>
        tester.widget<TextField>(find.byKey(SignInKeys.password));
    expect(password().obscureText, isTrue);
    expect(find.byTooltip(vi.showPassword), findsOneWidget);
    await tester.tap(find.byKey(SignInKeys.togglePassword));
    await tester.pump();
    expect(password().obscureText, isFalse);
    expect(find.byTooltip(vi.hidePassword), findsOneWidget);
    await tester.tap(find.byKey(SignInKeys.togglePassword));
    await tester.pump();
    expect(password().obscureText, isTrue);
    expect(find.byTooltip(vi.showPassword), findsOneWidget);
  });

  testWidgets('password visibility resets when the app is backgrounded', (
    tester,
  ) async {
    await pumpEduApp(tester);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await tester.tap(find.byKey(SignInKeys.togglePassword));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byKey(SignInKeys.password)).obscureText,
      isFalse,
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byKey(SignInKeys.password)).obscureText,
      isTrue,
    );
    expect(find.byTooltip(vi.showPassword), findsOneWidget);
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
    await expectAccessibilityGuidelines(tester);
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

    testWidgets('golden: validating field errors on $name', (tester) async {
      await pumpEduApp(tester, size: size);
      await tester.tap(find.byKey(SignInKeys.submit));
      await tester.pumpAndSettle();
      await expectScreenGolden(tester, 'sign_in_validating_$name');
    });

    testWidgets('golden: wrong-credentials borders on $name', (tester) async {
      await pumpEduApp(tester, size: size);
      await fillAndSubmit(tester, password: 'sai-mat-khau');
      await expectScreenGolden(tester, 'sign_in_wrong_credentials_$name');
    });
  }
}
