@Tags(['integration'])
library;

import 'package:test/test.dart';

import '../support/harness.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('classes.mine', (sessionBuilder, endpoints) {
    setUpAll(initTestAuthServices);

    test('returns only the teacher\'s own classes, ordered, with subjects '
        'and member counts', () async {
      final seeded = await seedPhase1(sessionBuilder);
      final classes = await endpoints.classes.mine(
        signedInAs(sessionBuilder, seeded, FixtureKeys.teacherLan),
      );
      expect(classes.map((c) => c.name), ['7A', '7B', '8A']);
      expect(classes[0].subjects, ['Toán', 'Ngữ văn', 'Khoa học tự nhiên']);
      expect(classes[0].studentCount, 1);
      expect(classes[0].gradeLevel, 7);
      expect(classes[2].subjects, isEmpty);
      expect(classes[2].studentCount, 0);
      expect(
        classes.map((c) => c.id),
        isNot(contains(seeded.classIds[FixtureKeys.class9A])),
      );
    });

    test('the other teacher sees only their own class', () async {
      final seeded = await seedPhase1(sessionBuilder);
      final classes = await endpoints.classes.mine(
        signedInAs(sessionBuilder, seeded, FixtureKeys.teacherNam),
      );
      expect(classes.map((c) => c.name), ['9A']);
    });
  });
}
