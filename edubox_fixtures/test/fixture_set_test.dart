import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:test/test.dart';

void main() {
  final fixtures = FixtureSet.phase1();

  test('keys and emails are unique', () {
    final keys = fixtures.accounts.map((a) => a.key).toSet();
    final emails = fixtures.accounts.map((a) => a.email).toSet();
    expect(keys, hasLength(fixtures.accounts.length));
    expect(emails, hasLength(fixtures.accounts.length));
  });

  test('every reference points at an existing fixture', () {
    for (final c in fixtures.classes) {
      expect(fixtures.account(c.teacherKey).role, 'teacher');
      for (final s in c.studentKeys) {
        expect(fixtures.account(s).role, 'student');
      }
    }
    for (final item in fixtures.content) {
      expect(fixtures.account(item.ownerKey).role, 'teacher');
      item.classKeys.forEach(fixtures.classByKey);
    }
  });

  test('student An sees only approved content of class 7A, newest first', () {
    final titles = fixtures
        .libraryOfStudent(FixtureKeys.studentAn)
        .map((c) => c.key)
        .toList();
    expect(titles, [
      FixtureKeys.ebookEnglishShared,
      FixtureKeys.ebookClassRules,
      FixtureKeys.ebookCells,
      FixtureKeys.exerciseFractions,
      FixtureKeys.videoNarrative,
      FixtureKeys.ebookFractions,
    ]);
    expect(titles, isNot(contains(FixtureKeys.draftGeometry)));
    expect(titles, isNot(contains(FixtureKeys.approvedOtherClass)));
  });

  test('the not-set-up fixtures exist', () {
    expect(fixtures.account(FixtureKeys.noProfile).hasProfile, isFalse);
    final nullRole = fixtures.account(FixtureKeys.nullRole);
    expect(nullRole.hasProfile, isTrue);
    expect(nullRole.role, isNull);
  });

  test('reconnect deltas add one library item and one class', () {
    final delta = fixtures.withReconnectDeltas();
    expect(
      delta.libraryOfStudent(FixtureKeys.studentAn).first.key,
      FixtureKeys.deltaReviewEbook,
    );
    expect(
      delta.classesOfTeacher(FixtureKeys.teacherLan).map((c) => c.name),
      ['7A', '7B', '8A', '8B'],
    );
  });

  test('parent Binh is linked to An; parent Thao has no child', () {
    expect(fixtures.linkedStudentNameOf(FixtureKeys.parentBinh), 'Nguyễn Minh An');
    expect(fixtures.linkedStudentNameOf(FixtureKeys.parentNoChild), isNull);
  });
}
