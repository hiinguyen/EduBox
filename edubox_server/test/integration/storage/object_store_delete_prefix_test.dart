import 'dart:io';

import 'package:edubox_server/src/config/edubox_config.dart';
import 'package:edubox_server/src/storage/object_store.dart';
import 'package:test/test.dart';

import '../test_tools/serverpod_test_tools.dart';

/// The no-progress guard in `deletePrefix`: a listing that keeps returning a
/// key that was already deleted must fail instead of looping forever or
/// reporting success. Uses a local fake S3 endpoint, so no MinIO is needed.
void main() {
  withServerpod('deletePrefix progress guard', (sessionBuilder, endpoints) {
    late HttpServer server;
    late Uri endpoint;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      endpoint = Uri.parse('http://${server.address.host}:${server.port}');
      server.listen((request) async {
        if (request.method == 'GET') {
          request.response
            ..headers.contentType = ContentType('application', 'xml')
            ..write(
              '<?xml version="1.0" encoding="UTF-8"?>'
              '<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">'
              '<Name>edubox-test</Name>'
              '<Prefix>stuck/</Prefix>'
              '<KeyCount>1</KeyCount>'
              '<MaxKeys>1000</MaxKeys>'
              '<IsTruncated>true</IsTruncated>'
              '<Contents><Key>stuck/a.bin</Key><Size>1</Size></Contents>'
              '</ListBucketResult>',
            );
        } else {
          request.response.statusCode = HttpStatus.noContent;
        }
        await request.response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('throws StateError naming the prefix when a listing round repeats '
        'a deleted key', () async {
      final store = S3ObjectStore(
        config: StorageConfig(
          endpoint: endpoint,
          publicEndpoint: endpoint,
          bucket: 'edubox-test',
          region: 'us-east-1',
        ),
        accessKey: 'test-only-key',
        secretKey: 'test-only-secret',
      );

      await expectLater(
        store
            .deletePrefix(sessionBuilder.build(), 'stuck/')
            .timeout(const Duration(seconds: 2)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('stuck/'),
          ),
        ),
      );
    });
  });
}
