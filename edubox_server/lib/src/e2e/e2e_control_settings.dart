import '../storage/object_store.dart';

/// Test-only overrides for the e2e control route.
///
/// Production reads `edubox.e2eControl` from `config/<runMode>.yaml`, the
/// `EDUBOX_E2E_CONTROL` environment variable, and `e2eControlToken` from
/// `config/passwords.yaml`. Server integration tests cannot set platform
/// environment variables, so they configure these fields instead and must
/// reset them in `tearDown`.
abstract final class E2eControlSettings {
  static bool? enabledOverride;
  static String? tokenOverride;
  static ObjectStore? storeOverride;

  static void configureForTest({
    required bool enabled,
    required String? token,
    ObjectStore? store,
  }) {
    enabledOverride = enabled;
    tokenOverride = token;
    storeOverride = store;
  }

  static void reset() {
    enabledOverride = null;
    tokenOverride = null;
    storeOverride = null;
  }
}
