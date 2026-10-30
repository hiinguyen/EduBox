import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_cloud_storage_s3_compat/serverpod_cloud_storage_s3_compat.dart'
    show
        CustomEndpointConfig,
        PresignedPutUploadStrategy,
        S3Client,
        S3CompatCloudStorage;
import 'package:xml/xml.dart'
    show XmlDocument, XmlFindExtension, XmlStringExtension;

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
/// Reads, writes, deletes and listing go to [StorageConfig.endpoint] with
/// path-style addressing (`<endpoint>/<bucket>/<key>`). Presigned URLs are
/// signed for [StorageConfig.publicEndpoint] by a second [S3Client] that never
/// sends a request, so the server never needs to reach the public host.
/// Credentials are the passwords `storageAccessKey` and `storageSecretKey`.
class S3ObjectStore implements ObjectStore {
  S3ObjectStore({
    required this.config,
    required this.accessKey,
    required this.secretKey,
  });

  final StorageConfig config;
  final String accessKey;
  final String secretKey;

  /// The longest presigned URL lifetime S3 allows.
  static const Duration maxSignedUrlLifetime = Duration(days: 7);

  /// Signed requests to the internal endpoint.
  late final S3Client _client = _clientFor(config.endpoint);

  /// Signs presigned GET URLs for the public endpoint only.
  late final S3Client _publicSigner = _clientFor(config.publicEndpoint);

  late final S3CompatCloudStorage _storage = S3CompatCloudStorage(
    storageId: 'edubox-${config.bucket}',
    accessKey: accessKey,
    secretKey: secretKey,
    bucket: config.bucket,
    region: config.region,
    public: false,
    endpoints: CustomEndpointConfig(
      baseUri: config.endpoint,
      serviceName: 'MinIO',
    ),
    uploadStrategy: PresignedPutUploadStrategy(),
    client: _client,
  );

  /// Sends the ListObjectsV2 requests, which [S3Client] has no method for.
  late final http.Client _http = http.Client();

  S3Client _clientFor(Uri baseUri) => S3Client(
    accessKey: accessKey,
    secretKey: secretKey,
    bucket: config.bucket,
    region: config.region,
    endpoints: CustomEndpointConfig(baseUri: baseUri, serviceName: 'MinIO'),
  );

  @override
  Future<void> put(
    Session session,
    String path,
    ByteData bytes, {
    String? contentType,
  }) async {
    _checkPath(path);
    await _storage.storeFile(
      session: session,
      path: path,
      byteData: bytes,
      options: StoreFileOptions(
        metadata: FileMetadata(contentType: contentType),
      ),
    );
  }

  @override
  Future<ByteData> get(Session session, String path) async {
    _checkPath(path);
    try {
      return await _storage.retrieveFile(session: session, path: path);
    } on CloudStorageFileNotFoundException {
      throw ObjectNotFoundException(path);
    }
  }

  @override
  Future<Uri> signedGetUrl(
    Session session,
    String path, {
    Duration expiresIn = const Duration(minutes: 5),
  }) async {
    _checkPath(path);
    if (expiresIn < const Duration(seconds: 1) ||
        expiresIn > maxSignedUrlLifetime) {
      throw ArgumentError.value(
        expiresIn,
        'expiresIn',
        'Must be between 1 second and 7 days',
      );
    }
    return _publicSigner.buildPresignedUri(
      key: path,
      method: 'GET',
      expiration: expiresIn,
    );
  }

  @override
  Future<void> deletePrefix(Session session, String prefix) async {
    if (prefix.startsWith('/')) {
      throw ArgumentError.value(prefix, 'prefix', 'Must not start with "/"');
    }
    // Every listed key is deleted before the next listing, so the first page
    // is always the next batch; no continuation token is needed. A listing
    // that returns a key deleted in an earlier round made no progress (for
    // example an eventually consistent backend), so fail instead of looping
    // forever or reporting success.
    final deletedKeys = <String>{};
    while (true) {
      final page = await _listFirstPage(prefix);
      if (page.keys.any(deletedKeys.contains)) {
        throw StateError(
          'deletePrefix("$prefix") made no progress: the listing still '
          'returns an object that was already deleted',
        );
      }
      for (final key in page.keys) {
        final response = await _client.deleteObject(key);
        deletedKeys.add(key);
        if (response.statusCode == 404) continue;
        _client.checkResponseError(response);
      }
      if (!page.isTruncated || page.keys.isEmpty) return;
    }
  }

  Future<({List<String> keys, bool isTruncated})> _listFirstPage(
    String prefix,
  ) async {
    final params = _client.buildSignedParams(
      key: '',
      queryParams: {'list-type': '2', 'max-keys': '1000', 'prefix': prefix},
    );
    final response = await _http.get(params.uri, headers: params.headers);
    _client.checkResponseError(response);
    final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
    return (
      keys: [
        for (final element in document.findAllElements(
          'Key',
          namespaceUri: '*',
        ))
          element.innerText,
      ],
      isTruncated: document
          .findAllElements('IsTruncated', namespaceUri: '*')
          .any((element) => element.innerText.trim() == 'true'),
    );
  }

  /// Rejects keys that could escape the bucket or address it ambiguously.
  static void _checkPath(String path) {
    final segments = path.split('/');
    if (path.isEmpty ||
        segments.any(
          (segment) => segment.isEmpty || segment == '.' || segment == '..',
        )) {
      throw ArgumentError.value(
        path,
        'path',
        'Must be a relative object key without empty, "." or ".." segments',
      );
    }
  }
}
