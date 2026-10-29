@Tags(['integration'])
library;

import 'package:edubox_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/harness.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('content.library', (sessionBuilder, endpoints) {
    setUpAll(initTestAuthServices);

    late SeededFixtures seeded;
    setUp(() async => seeded = await seedPhase1(sessionBuilder));

    Future<StudentLibrary> libraryOf(String key) =>
        endpoints.content.library(signedInAs(sessionBuilder, seeded, key));

    test('returns exactly the approved content of the student\'s classes, '
        'newest first (exit criteria 1 and 11)', () async {
      final library = await libraryOf(FixtureKeys.studentAn);
      final expected = seeded.fixtures.libraryOfStudent(FixtureKeys.studentAn);
      expect(
        library.items.map((i) => i.id).toList(),
        expected.map((c) => seeded.contentIds[c.key]).toList(),
      );
      final ids = library.items.map((i) => i.id).toSet();
      expect(
        ids,
        isNot(contains(seeded.contentIds[FixtureKeys.draftGeometry])),
      );
      expect(
        ids,
        isNot(contains(seeded.contentIds[FixtureKeys.approvedOtherClass])),
      );
      expect(
        ids,
        isNot(contains(seeded.contentIds[FixtureKeys.approved7BGrammar])),
      );
    });

    test('items carry the stored metadata', () async {
      final library = await libraryOf(FixtureKeys.studentAn);
      final rules = library.items.singleWhere(
        (i) => i.id == seeded.contentIds[FixtureKeys.ebookClassRules],
      );
      expect(rules.title, 'Nội quy lớp học');
      expect(rules.type, ContentType.ebook);
      expect(rules.subject, '');
      expect(rules.gradeLevel, 7);
    });

    test('returns the student\'s classes with ordered subjects', () async {
      final library = await libraryOf(FixtureKeys.studentAn);
      expect(library.classes, hasLength(1));
      expect(library.classes.single.name, '7A');
      expect(library.classes.single.subjects, [
        'Toán',
        'Ngữ văn',
        'Khoa học tự nhiên',
      ]);
    });

    test('content shared by two classes reaches both classes once', () async {
      final shared = seeded.contentIds[FixtureKeys.ebookEnglishShared];
      for (final key in [FixtureKeys.studentAn, FixtureKeys.studentHa]) {
        final ids = (await libraryOf(key)).items.map((i) => i.id).toList();
        expect(ids.where((id) => id == shared), hasLength(1), reason: key);
      }
    });

    test('a student with no class gets no classes and no items', () async {
      final library = await libraryOf(FixtureKeys.studentNoClass);
      expect(library.classes, isEmpty);
      expect(library.items, isEmpty);
    });
  });
}
