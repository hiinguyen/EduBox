@Tags(['backend-pending'])
library;

import 'dart:typed_data';

import 'package:edubox_server/src/generated/protocol.dart';
import 'package:edubox_server/src/seed/seed_command.dart';
import 'package:edubox_server/src/storage/object_store.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../test_tools/serverpod_test_tools.dart';

/// BACKEND TRACK: implement `runSeedStep` and remove the `backend-pending`
/// tag. Until then server tests stay green because `dart_test.yaml` skips it.
void main() {
  withServerpod('seed reset', (sessionBuilder, endpoints) {
    test('writes the phase 1 accounts, classes and content', () async {
      final session = sessionBuilder.build();
      await runSeedStep(session, SeedStep.reset, e2eStore: _NoopStore());

      expect(await EduboxUser.db.count(session), greaterThanOrEqualTo(9));
      expect(await SchoolClass.db.count(session), 4);
      expect(await ContentRecord.db.count(session), greaterThan(0));
      expect(
        (await ContentRecord.db.find(
          session,
        )).where((row) => row.status == ContentStatus.draft),
        isNotEmpty,
      );
    });
  });
}

class _NoopStore implements ObjectStore {
  @override
  Future<void> put(
    Session session,
    String path,
    ByteData bytes, {
    String? contentType,
  }) async {}

  @override
  Future<ByteData> get(Session session, String path) async =>
      ByteData.sublistView(Uint8List(0));

  @override
  Future<Uri> signedGetUrl(
    Session session,
    String path, {
    Duration expiresIn = const Duration(minutes: 5),
  }) async => Uri.parse('http://localhost:9000/unused');

  @override
  Future<void> deletePrefix(Session session, String prefix) async {}
}
