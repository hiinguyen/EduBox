@Tags(['backend-pending'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:edubox_server/src/config/edubox_config.dart';
import 'package:edubox_server/src/storage/object_store.dart';
import 'package:test/test.dart';

import '../test_tools/serverpod_test_tools.dart';

/// Exit criterion 10: store, read back and sign a URL against MinIO.
///
/// BACKEND TRACK: implement `S3ObjectStore`, run `docker compose up -d minio`
/// and `docker compose run --rm minio-init`, then remove the
/// `backend-pending` tag. The test bucket name is `edubox-test`.
void main() {
  withServerpod('Object storage spike (MinIO)', (sessionBuilder, endpoints) {
    final config = StorageConfig(
      endpoint: StorageEndpoint.local,
      publicEndpoint: StorageEndpoint.local,
      bucket: 'edubox-test',
      region: 'us-east-1',
    );
    final store = S3ObjectStore(
      config: config,
      accessKey: 'edubox-dev',
      secretKey: 'dev-only-minio-password',
    );

    test('puts, reads back byte-identical, signs a URL and denies unsigned '
        'reads', () async {
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
      final client = HttpClient();
      try {
        final response = await (await client.getUrl(signed)).close();
        expect(response.statusCode, 200);
        final body = await response.fold<List<int>>(
          <int>[],
          (all, chunk) => all..addAll(chunk),
        );
        expect(body, [1, 2, 3, 4, 5]);

        final unsigned = await (await client.getUrl(
          Uri.parse('http://localhost:9000/edubox-test/$path'),
        )).close();
        expect(unsigned.statusCode, anyOf(401, 403, 404));
        await unsigned.drain<void>();
      } finally {
        client.close(force: true);
      }
    });
  });
}

/// The local MinIO endpoint used by host-side tests.
abstract final class StorageEndpoint {
  static final local = Uri.parse('http://localhost:9000');
}
