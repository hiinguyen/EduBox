import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend_config.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/e2e_harness.dart';

/// Exit criterion 4 (unreachable half): this file builds its own backend
/// config pointing at a closed port on the host alias, overriding the
/// EDUBOX_SERVER_URL default, and expects backendUnreachable with retry.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a closed port shows backendUnreachable and retry', (
    tester,
  ) async {
    final harness = E2eHarness(
      config: const BackendConfig(serverUrl: 'http://10.0.2.2:8099'),
    );
    addTearDown(harness.dispose);
    await harness.setUp();
    await harness.pumpRoot(tester);
    await harness.signIn(tester, FixtureKeys.studentAn);
    await waitFor(tester, find.text(vi.backendUnreachable));
    expect(find.text(vi.backendUnreachable), findsOneWidget);
    expect(find.byKey(SignInKeys.retry), findsOneWidget);
    expect(find.text(vi.retry), findsOneWidget);
  });
}
