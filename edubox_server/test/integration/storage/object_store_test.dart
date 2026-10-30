import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:edubox_server/src/config/edubox_config.dart';
import 'package:edubox_server/src/storage/object_store.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod_cloud_storage_s3_compat/serverpod_cloud_storage_s3_compat.dart'
    show CustomEndpointConfig, S3Client;
import 'package:test/test.dart';
import 'package:xml/xml.dart';

import '../test_tools/serverpod_test_tools.dart';

/// Exit criterion 10: store, read back, sign a URL for the configured public
/// host, and prove unsigned and expired access are denied.
///
/// Needs MinIO and the `edubox-test` bucket:
/// `docker compose up -d --wait minio && docker compose run --rm minio-init`.
void main() {
  withServerpod('Object storage spike (MinIO)', (sessionBuilder, endpoints) {
    // Deliberately distinct hosts: signing must use the public endpoint, not
    // the internal one the server talks to.
    final config = StorageConfig(
      endpoint: Uri.parse('http://localhost:9000'),
      publicEndpoint: Uri.parse('http://127.0.0.1:9000'),
      bucket: 'edubox-test',
      region: 'us-east-1',
    );
    final store = S3ObjectStore(
      config: config,
      accessKey: 'edubox-dev',
      secretKey: 'dev-only-minio-password',
    );

    Future<ByteData> fetch(Uri uri) async {
      final client = HttpClient();
      try {
        final response = await (await client.getUrl(uri)).close();
        if (response.statusCode != 200) {
          throw HttpException('HTTP ${response.statusCode}', uri: uri);
        }
        final bytes = await response.fold<List<int>>(
          <int>[],
          (all, chunk) => all..addAll(chunk),
        );
        return ByteData.sublistView(Uint8List.fromList(bytes));
      } finally {
        client.close(force: true);
      }
    }

    Future<int> status(Uri uri) async {
      final client = HttpClient();
      try {
        final response = await (await client.getUrl(uri)).close();
        await response.drain<void>();
        return response.statusCode;
      } finally {
        client.close(force: true);
      }
    }

    /// Every key in the test bucket matching [prefix], following the
    /// ListObjectsV2 continuation token.
    Future<List<String>> listKeys(String prefix) async {
      final client = S3Client(
        accessKey: 'edubox-dev',
        secretKey: 'dev-only-minio-password',
        bucket: config.bucket,
        region: config.region,
        endpoints: CustomEndpointConfig(
          baseUri: config.endpoint,
          serviceName: 'MinIO',
        ),
      );
      try {
        final keys = <String>[];
        String? continuationToken;
        do {
          final params = client.buildSignedParams(
            key: '',
            queryParams: {
              'list-type': '2',
              'prefix': prefix,
              'continuation-token': ?continuationToken,
            },
          );
          final response = await http.get(params.uri, headers: params.headers);
          client.checkResponseError(response);
          final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
          keys.addAll([
            for (final element in document.findAllElements(
              'Key',
              namespaceUri: '*',
            ))
              element.innerText,
          ]);
          continuationToken = document
              .findAllElements('NextContinuationToken', namespaceUri: '*')
              .map((element) => element.innerText)
              .firstOrNull;
        } while (continuationToken != null);
        return keys;
      } finally {
        client.close();
      }
    }

    test('puts, reads back byte-identical, signs for the public host, and '
        'denies unsigned reads', () async {
      final session = sessionBuilder.build();
      final bytes = ByteData.sublistView(
        Uint8List.fromList([1, 2, 3, 4, 5]),
      );
      const path = 'spike/hello.bin';

      await store.put(
        session,
        path,
        bytes,
        contentType: 'application/octet-stream',
      );
      final read = await store.get(session, path);
      expect(read.buffer.asUint8List(), bytes.buffer.asUint8List());

      final signed = await store.signedGetUrl(session, path);
      expect(signed.host, config.publicEndpoint.host);
      expect(signed.port, config.publicEndpoint.port);
      final signedBytes = await fetch(signed);
      expect(signedBytes.buffer.asUint8List(), bytes.buffer.asUint8List());

      expect(
        await status(
          Uri.parse('http://localhost:9000/${config.bucket}/$path'),
        ),
        anyOf(401, 403, 404),
      );
    });

    test('a short signed URL expires', () async {
      final session = sessionBuilder.build();
      const path = 'spike/expiring.bin';
      await store.put(
        session,
        path,
        ByteData.sublistView(Uint8List.fromList([9])),
      );

      final signed = await store.signedGetUrl(
        session,
        path,
        expiresIn: const Duration(seconds: 1),
      );
      expect(signed.queryParameters['X-Amz-Expires'], '1');
      await Future<void>.delayed(const Duration(seconds: 2));
      expect(await status(signed), anyOf(401, 403));
    });

    test('deletePrefix removes only the matching objects', () async {
      final session = sessionBuilder.build();
      final bytes = ByteData.sublistView(Uint8List.fromList([7]));
      await store.put(session, 'prefix/a.bin', bytes);
      await store.put(session, 'prefix/b.bin', bytes);
      await store.put(session, 'keep/c.bin', bytes);

      await store.deletePrefix(session, 'prefix/');

      await expectLater(
        store.get(session, 'prefix/a.bin'),
        throwsA(isA<ObjectNotFoundException>()),
      );
      await expectLater(
        store.get(session, 'prefix/b.bin'),
        throwsA(isA<ObjectNotFoundException>()),
      );
      expect(
        (await store.get(session, 'keep/c.bin')).buffer.asUint8List(),
        bytes.buffer.asUint8List(),
      );
      await store.deletePrefix(session, 'keep/');
    });

    test('get of a missing object throws ObjectNotFoundException', () async {
      final session = sessionBuilder.build();
      await expectLater(
        store.get(session, 'spike/does-not-exist.bin'),
        throwsA(
          isA<ObjectNotFoundException>().having(
            (error) => error.path,
            'path',
            'spike/does-not-exist.bin',
          ),
        ),
      );
    });

    test('keys with spaces and Vietnamese letters round-trip and are '
        'removed by deletePrefix', () async {
      final session = sessionBuilder.build();
      final bytes = ByteData.sublistView(Uint8List.fromList([4, 2]));
      const path = 'unicode/bài tập ữ.bin';
      await store.put(session, path, bytes);

      expect(
        (await store.get(session, path)).buffer.asUint8List(),
        bytes.buffer.asUint8List(),
      );
      final signedBytes = await fetch(await store.signedGetUrl(session, path));
      expect(signedBytes.buffer.asUint8List(), bytes.buffer.asUint8List());

      await store.deletePrefix(session, 'unicode/');
      await expectLater(
        store.get(session, path),
        throwsA(isA<ObjectNotFoundException>()),
      );
    });

    test('deletePrefix on a prefix with no objects is a no-op', () async {
      final session = sessionBuilder.build();
      await store.deletePrefix(session, 'nothing-here-${_runId()}/');
    });

    test('rejects keys that could escape the bucket', () async {
      final session = sessionBuilder.build();
      final bytes = ByteData.sublistView(Uint8List.fromList([1]));
      for (final path in [
        '',
        '/leading.bin',
        'trailing/',
        'a//b.bin',
        '../escape.bin',
        'a/./b.bin',
        'a/../b.bin',
      ]) {
        await expectLater(
          store.put(session, path, bytes),
          throwsArgumentError,
          reason: path,
        );
        await expectLater(
          store.get(session, path),
          throwsArgumentError,
          reason: path,
        );
        await expectLater(
          store.signedGetUrl(session, path),
          throwsArgumentError,
          reason: path,
        );
      }
      await expectLater(
        store.deletePrefix(session, '/leading/'),
        throwsArgumentError,
      );
    });

    test('signed URL lifetime must be 1 second to 7 days', () async {
      final session = sessionBuilder.build();
      for (final expiresIn in [
        Duration.zero,
        const Duration(milliseconds: 999),
        const Duration(days: 7, seconds: 1),
      ]) {
        expect(
          () =>
              store.signedGetUrl(session, 'spike/x.bin', expiresIn: expiresIn),
          throwsArgumentError,
          reason: '$expiresIn',
        );
      }
      final longest = await store.signedGetUrl(
        session,
        'spike/x.bin',
        expiresIn: const Duration(days: 7),
      );
      expect(longest.queryParameters['X-Amz-Expires'], '604800');
    });

    test('deletePrefix deletes more objects than one listing page', () async {
      final session = sessionBuilder.build();
      final bytes = ByteData.sublistView(Uint8List.fromList([3]));
      final runId = _runId();
      final prefix = 'bulk/$runId/';
      // One more than ListObjectsV2's 1000-key page, so a single-page
      // implementation would leave at least one object behind.
      const objectCount = 1001;
      for (var start = 0; start < objectCount; start += 50) {
        final end = start + 50 > objectCount ? objectCount : start + 50;
        await Future.wait([
          for (var index = start; index < end; index++)
            store.put(
              session,
              '${prefix}object-${index.toString().padLeft(4, '0')}.bin',
              bytes,
            ),
        ]);
      }
      final sentinel = 'bulk-keep/$runId/sentinel.bin';
      await store.put(session, sentinel, bytes);
      expect(await listKeys(prefix), hasLength(objectCount));

      await store.deletePrefix(session, prefix);

      expect(await listKeys(prefix), isEmpty);
      expect(
        (await store.get(session, sentinel)).buffer.asUint8List(),
        bytes.buffer.asUint8List(),
      );
      await store.deletePrefix(session, 'bulk-keep/$runId/');
    });

    test(
      'deletePrefix with an empty prefix empties the whole bucket',
      () async {
        final session = sessionBuilder.build();
        final bytes = ByteData.sublistView(Uint8List.fromList([6]));
        final runId = _runId();
        for (final prefix in ['empty/$runId/', 'spike/', 'prefix/', 'keep/']) {
          await store.put(session, '${prefix}a-$runId.bin', bytes);
          await store.put(session, '${prefix}b-$runId.bin', bytes);
        }
        expect(await listKeys(''), isNotEmpty);

        await store.deletePrefix(session, '');

        expect(await listKeys(''), isEmpty);
      },
    );
  });
}

/// A per-run suffix so repeated runs never share object keys.
String _runId() => DateTime.now().microsecondsSinceEpoch.toString();
