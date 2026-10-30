import 'package:edubox_flutter/l10n/generated/app_localizations.dart';
import 'package:edubox_flutter/src/app/app_scope.dart';
import 'package:edubox_flutter/src/app/edubox_app.dart';
import 'package:edubox_flutter/src/contract/backend.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/fake/fake_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Vietnamese strings, looked up by key (never literal text).
final AppLocalizations vi = lookupAppLocalizations(const Locale('vi'));

/// Test window sizes in logical pixels.
abstract final class TestSizes {
  /// Compact: a phone (Pixel 7-class) in portrait.
  static const phone = Size(411, 891);

  /// Medium: a 10-11" tablet in portrait.
  static const tabletPortrait = Size(800, 1280);

  /// Expanded: an 8" tablet in landscape.
  static const smallLandscape = Size(960, 600);

  /// Large: the edubox_tablet AVD in landscape.
  static const tablet = Size(1280, 800);
}

/// Thursday 29/10/2026 09:14 local: the fixed clock for every widget test.
DateTime fixedClock() => DateTime(2026, 10, 29, 9, 14);

/// A fake whose refresh times follow [fixedClock], so "last updated"
/// times are stable ("09:14").
FakeBackend newFake(ManualNetworkController network) =>
    FakeBackend(network: network, clock: () => fixedClock().toUtc());

/// The root boundary that goldens capture.
const rootKey = Key('test.root');

/// A pumped app over the fake backend.
class TestApp {
  TestApp(this.fake, this.network);

  final FakeBackend fake;
  final ManualNetworkController network;
}

/// Sets the window to [size] at device pixel ratio 1 and [textScale].
void setWindow(WidgetTester tester, Size size, {double textScale = 1}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Pumps the whole app. With [signedInAs] the fake already holds that
/// session, so the app restores straight into its stage.
Future<TestApp> pumpEduApp(
  WidgetTester tester, {
  Size size = TestSizes.tablet,
  double textScale = 1,
  String? signedInAs,
  FakeBackend? fake,
  EduBoxBackend? backend,
  ManualNetworkController? network,
  bool settle = true,
}) async {
  setWindow(tester, size, textScale: textScale);
  final seam = network ?? ManualNetworkController();
  final resolvedFake = fake ?? newFake(seam);
  if (signedInAs != null) resolvedFake.signInAs(signedInAs);
  await tester.pumpWidget(
    RepaintBoundary(
      key: rootKey,
      child: EduBoxApp(
        // A new key per pump: pumping again re-creates the app root.
        key: UniqueKey(),
        services: AppServices(
          backend: backend ?? resolvedFake,
          network: seam,
          clock: fixedClock,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return TestApp(resolvedFake, seam);
}

/// The three Flutter accessibility guidelines of exit criterion 17.
Future<void> expectAccessibilityGuidelines(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  handle.dispose();
}

/// Captures the whole window as `test/widget/goldens/<name>.png`.
Future<void> expectScreenGolden(WidgetTester tester, String name) =>
    expectLater(find.byKey(rootKey), matchesGoldenFile('../goldens/$name.png'));

/// A fake and its seam, built before pumping so a test can set failure
/// switches (or hold calls) for the first load.
class ManualNetworkControllerHolder {
  ManualNetworkControllerHolder._(this.fake, this.network);

  factory ManualNetworkControllerHolder.create() {
    final network = ManualNetworkController();
    return ManualNetworkControllerHolder._(newFake(network), network);
  }

  final FakeBackend fake;
  final ManualNetworkController network;
}

/// Like [ManualNetworkControllerHolder], with every call held pending.
abstract final class FakeBackendWithHold {
  static ManualNetworkControllerHolder create() {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.holdCalls();
    return holder;
  }
}
