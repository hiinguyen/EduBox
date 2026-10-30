import 'dart:io';

import 'package:yaml/yaml.dart';

/// EduBox settings that are not secrets, read from the `edubox:` section of
/// the run-mode file `config/<runMode>.yaml`, then overridden by environment
/// variables (the compose `server` and `seed` services use the overrides).
///
/// Secrets (MinIO keys, auth peppers, the optional OpenRouter key) live in
/// the git-ignored `config/passwords.yaml` instead.
class EduboxConfig {
  const EduboxConfig({required this.storage, required this.e2eControl});

  /// Object storage settings (MinIO locally).
  final StorageConfig storage;

  /// True only for the compose `e2e` server (the `development` run mode) and
  /// the `test` run mode: enables the e2e control route (see
  /// docs/build/phase-1/contract.md). Any other run mode, including
  /// `production` and `staging`, always resolves this to false even when the
  /// file or `EDUBOX_E2E_CONTROL` asks for true.
  final bool e2eControl;

  /// Run modes in which the e2e control route may be enabled. The compose
  /// `e2e` server runs the `development` mode; Serverpod test tools run
  /// `test`. Everything else is rejected.
  static const Set<String> e2eControlRunModes = {'development', 'test'};

  /// Loads the config for [runMode] from [serverDirectory]/config.
  static EduboxConfig load({
    required String runMode,
    String serverDirectory = '.',
    Map<String, String>? environment,
  }) {
    final env = environment ?? Platform.environment;
    final file = File('$serverDirectory/config/$runMode.yaml');
    final yaml = file.existsSync() ? loadYaml(file.readAsStringSync()) : null;
    final section = yaml is YamlMap ? yaml['edubox'] : null;
    final storage = section is YamlMap ? section['storage'] : null;

    String read(YamlMap? map, String key, String envName) {
      final override = env[envName];
      if (override != null && override.isNotEmpty) return override;
      final value = map?[key];
      if (value is String && value.isNotEmpty) return value;
      throw StateError(
        'Missing EduBox setting edubox.storage.$key in '
        'config/$runMode.yaml (or environment variable $envName).',
      );
    }

    final storageMap = storage is YamlMap ? storage : null;
    final e2eOverride = env['EDUBOX_E2E_CONTROL'];
    final e2eValue = section is YamlMap ? section['e2eControl'] : null;
    final e2eConfigured = e2eOverride != null
        ? e2eOverride == 'true'
        : e2eValue == true;
    return EduboxConfig(
      storage: StorageConfig(
        endpoint: Uri.parse(
          read(storageMap, 'endpoint', 'EDUBOX_STORAGE_ENDPOINT'),
        ),
        publicEndpoint: Uri.parse(
          read(storageMap, 'publicEndpoint', 'EDUBOX_STORAGE_PUBLIC_ENDPOINT'),
        ),
        bucket: read(storageMap, 'bucket', 'EDUBOX_STORAGE_BUCKET'),
        region: read(storageMap, 'region', 'EDUBOX_STORAGE_REGION'),
      ),
      // The run-mode gate comes first: an environment override can enable
      // the route in development/test, but never in production/staging.
      e2eControl: e2eControlRunModes.contains(runMode) && e2eConfigured,
    );
  }
}

/// S3-compatible storage settings. Credentials are the passwords
/// `storageAccessKey` and `storageSecretKey`.
class StorageConfig {
  const StorageConfig({
    required this.endpoint,
    required this.publicEndpoint,
    required this.bucket,
    required this.region,
  });

  /// Where the server reaches the store, e.g. `http://localhost:9000` for
  /// host-side tests and `http://minio:9000` inside compose.
  final Uri endpoint;

  /// The host that signed URLs are issued for, e.g. `http://10.0.2.2:9000`
  /// for the Android emulator. The signature covers this host.
  final Uri publicEndpoint;

  /// The private bucket for this run mode (created by `minio-init`).
  final String bucket;

  /// Signing region; MinIO accepts `us-east-1`.
  final String region;
}
