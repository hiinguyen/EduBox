import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../config/edubox_config.dart';

/// Private object storage (MinIO locally), used by phase 2 content files.
///
/// CONTRACT: this interface is frozen. BACKEND TRACK: implement
/// [S3ObjectStore] (exit criterion 10) and make the pending tests in
/// `test/integration/storage/object_store_test.dart` pass.
abstract interface class ObjectStore {
  /// Stores [bytes] at [path], replacing any existing object.
  Future<void> put(
    Session session,
    String path,
    ByteData bytes, {
    String? contentType,
  });

  /// Reads the object at [path]. Throws [ObjectNotFoundException] when it
  /// does not exist.
  Future<ByteData> get(Session session, String path);

  /// A short-lived presigned GET URL for [path], signed for the configured
  /// public endpoint (not the internal one). [expiresIn] is 1 second to
  /// 7 days.
  Future<Uri> signedGetUrl(
    Session session,
    String path, {
    Duration expiresIn = const Duration(minutes: 5),
  });

  /// Deletes every object whose path starts with [prefix] (an empty prefix
  /// empties the bucket; used by the seed `reset` step on the e2e bucket).
  Future<void> deletePrefix(Session session, String prefix);
}

/// Thrown by [ObjectStore.get] for a missing object.
class ObjectNotFoundException implements Exception {
  const ObjectNotFoundException(this.path);
  final String path;

  @override
  String toString() => 'ObjectNotFoundException: $path';
}

/// The MinIO / S3-compatible implementation.
///
/// BACKEND TRACK: implement with `serverpod_cloud_storage_s3_compat`
/// (`S3CompatCloudStorage` + `CustomEndpointConfig(baseUri:
/// config.endpoint)` for reads and writes, path-style addressing; a second
/// `S3Client` with `CustomEndpointConfig(baseUri: config.publicEndpoint)`
/// only for `buildPresignedUri`, which signs offline, so the server never
/// needs to reach the public host). Credentials come from the passwords
/// `storageAccessKey` and `storageSecretKey`.
class S3ObjectStore implements ObjectStore {
  S3ObjectStore({
    required this.config,
    required this.accessKey,
    required this.secretKey,
  });

  final StorageConfig config;
  final String accessKey;
  final String secretKey;

  @override
  Future<void> put(
    Session session,
    String path,
    ByteData bytes, {
    String? contentType,
  }) => throw UnimplementedError('BACKEND TRACK: S3ObjectStore.put');

  @override
  Future<ByteData> get(Session session, String path) =>
      throw UnimplementedError('BACKEND TRACK: S3ObjectStore.get');

  @override
  Future<Uri> signedGetUrl(
    Session session,
    String path, {
    Duration expiresIn = const Duration(minutes: 5),
  }) => throw UnimplementedError('BACKEND TRACK: S3ObjectStore.signedGetUrl');

  @override
  Future<void> deletePrefix(Session session, String prefix) =>
      throw UnimplementedError('BACKEND TRACK: S3ObjectStore.deletePrefix');
}
