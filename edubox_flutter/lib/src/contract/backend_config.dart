/// Where the app finds the EduBox server.
///
/// The default is the Android emulator's alias for the host machine. Tests
/// and integration-test files construct their own instance instead of
/// reading the compile-time define, which is the single override seam.
class BackendConfig {
  const BackendConfig({this.serverUrl = defaultServerUrl});

  /// The Android emulator reaches the local compose stack at 10.0.2.2.
  static const defaultServerUrl = 'http://10.0.2.2:8080';

  /// Compile-time override used by `flutter run` and `flutter test`.
  static const serverUrlDefine = 'EDUBOX_SERVER_URL';

  /// Base URL, without a trailing slash.
  final String serverUrl;

  /// Builds a config from `--dart-define=EDUBOX_SERVER_URL=...`.
  ///
  /// [override] lets a test or integration-test file bypass the define; it
  /// wins when present and non-empty.
  factory BackendConfig.fromEnvironment({String? override}) {
    final defined = const String.fromEnvironment(serverUrlDefine);
    final value = (override != null && override.isNotEmpty)
        ? override
        : (defined.isNotEmpty ? defined : defaultServerUrl);
    return BackendConfig(serverUrl: value);
  }

  Uri get serverUri => Uri.parse(serverUrl);

  @override
  bool operator ==(Object other) =>
      other is BackendConfig && other.serverUrl == serverUrl;

  @override
  int get hashCode => serverUrl.hashCode;

  @override
  String toString() => 'BackendConfig($serverUrl)';
}
