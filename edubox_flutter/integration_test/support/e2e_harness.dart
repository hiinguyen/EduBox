import 'dart:io';

import 'package:edubox_client/edubox_client.dart' show Client;
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/l10n/generated/app_localizations.dart';
import 'package:edubox_flutter/src/app/app_scope.dart';
import 'package:edubox_flutter/src/app/edubox_app.dart';
import 'package:edubox_flutter/src/app/production_services.dart';
import 'package:edubox_flutter/src/contract/backend_config.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/data/cached_backend.dart';
import 'package:edubox_flutter/src/network/platform_sources.dart'
    show serverRootUrl;
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart'
    show FlutterSecureStorage;

/// Every E2E assertion looks copy up by key, never as literal text.
final AppLocalizations vi = lookupAppLocalizations(const Locale('vi'));

/// The e2e-control token. The compose e2e server's dev-only value is the
/// default; override with `--dart-define=EDUBOX_E2E_TOKEN=...`.
const e2eToken = String.fromEnvironment(
  'EDUBOX_E2E_TOKEN',
  defaultValue: 'dev-only-e2e-control-token',
);

/// Drives the real app on the AVD against the compose stack: the
/// production data layer over the generated client, an on-disk drift file,
/// and a directly switchable network seam (roadmap E2E harness ruling).
class E2eHarness {
  E2eHarness({BackendConfig? config})
    : config = config ?? BackendConfig.fromEnvironment(),
      network = ManualNetworkController();

  final BackendConfig config;
  final ManualNetworkController network;
  late final File databaseFile;
  AppServices? _services;

  /// The current app's data layer (for cache surgery in criterion 6).
  CachedBackend get backend => _services!.backend as CachedBackend;

  /// Starts every test signed out with an empty store: the auth module's
  /// secure storage and the drift file from an earlier test are removed.
  Future<void> setUp() async {
    await const FlutterSecureStorage().deleteAll();
    final dir = await getTemporaryDirectory();
    databaseFile = File('${dir.path}/edubox_e2e.sqlite');
    if (databaseFile.existsSync()) databaseFile.deleteSync();
  }

  /// Calls the token-guarded `e2e.run` control route (contract 2.8).
  Future<void> control(String step, {String? accountKey, String? role}) async {
    final client = Client('${serverRootUrl(config)}/');
    try {
      final result = await client.e2e.run(
        token: e2eToken,
        step: step,
        accountKey: accountKey,
        role: role,
      );
      expect(result, 'ok:$step');
    } finally {
      client.close();
    }
  }

  /// Pumps a fresh app root over the same drift file. Calling it again is
  /// the in-process restart: the old store is closed first.
  Future<void> pumpRoot(WidgetTester tester) async {
    final old = _services;
    if (old != null) {
      await tester.pumpWidget(const SizedBox());
      await old.backend.dispose();
    }
    final services = await createProductionServices(
      config,
      network: network,
      databaseFile: databaseFile,
    );
    _services = services;
    await tester.pumpWidget(EduBoxApp(key: UniqueKey(), services: services));
    await settle(tester);
  }

  /// Signs in through the sign-in screen with the dev password.
  Future<void> signIn(
    WidgetTester tester,
    String accountKey, {
    String password = devPassword,
  }) async {
    final account = FixtureSet.phase1().account(accountKey);
    await waitFor(tester, find.byKey(SignInKeys.email));
    await tester.enterText(find.byKey(SignInKeys.email), account.email);
    await tester.enterText(find.byKey(SignInKeys.password), password);
    await tester.tap(find.byKey(SignInKeys.submit));
    await settle(tester);
  }

  /// Signs out from whichever shell control the window class exposes: the
  /// extended rail's button, or the account menu below the large class.
  /// Teacher, parent and not-set-up only: a student's sign-out needs the
  /// confirmation dialog, which this helper does not tap.
  Future<void> signOut(WidgetTester tester) async {
    final railSignOut = find.byKey(const Key('shell.railSignOut'));
    if (railSignOut.evaluate().isNotEmpty) {
      await tester.tap(railSignOut);
    } else {
      await tester.tap(find.byKey(const Key('shell.accountMenu')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('shell.menuSignOut')));
    }
    await settle(tester);
  }

  Future<void> dispose() async {
    await _services?.backend.dispose();
    network.dispose();
  }
}

/// Pumps until no frame is scheduled, tolerating real network latency.
Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 30),
  );
}

/// Pumps until [finder] matches or [timeout] passes.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets, reason: 'timed out waiting');
}
