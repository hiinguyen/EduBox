@Tags(['backend-pending'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:edubox_server/src/config/edubox_config.dart';
import 'package:edubox_server/src/storage/object_store.dart';
import 'package:test/test.dart';

import '../test_tools/serverpod_test_tools.dart';

/// Exit criterion 10: store, read back, sign a URL for the configured public
/// host, and prove unsigned and expired access are denied.
///
/// BACKEND TRACK: implement `S3ObjectStore`, run `docker compose up -d minio`
/// and `docker compose run --rm minio-init`, then remove the
/// `backend-pending` tag. The test bucket name is `edubox-test`.
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
  });
}
