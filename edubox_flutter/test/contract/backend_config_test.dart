import 'package:edubox_flutter/src/contract/backend_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default is the Android emulator host alias on port 8080', () {
    const config = BackendConfig();
    expect(config.serverUrl, 'http://10.0.2.2:8080');
    expect(config.serverUri.host, '10.0.2.2');
    expect(config.serverUri.port, 8080);
  });

  test('a test or integration test can construct its own override', () {
    const config = BackendConfig(serverUrl: 'http://127.0.0.1:6553');
    expect(config.serverUrl, 'http://127.0.0.1:6553');
  });

  test('fromEnvironment honours an explicit override', () {
    final config = BackendConfig.fromEnvironment(
      override: 'http://10.0.2.2:9999',
    );
    expect(config.serverUrl, 'http://10.0.2.2:9999');
  });

  test('fromEnvironment falls back to the default without a define', () {
    final config = BackendConfig.fromEnvironment();
    expect(config.serverUrl, BackendConfig.defaultServerUrl);
  });
}
