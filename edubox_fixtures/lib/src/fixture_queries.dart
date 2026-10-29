import 'fixture_types.dart';
import 'phase1_fixtures.dart';

/// Read-only lookups over a fixture set.
///
/// These encode the phase 1 visibility rules in the simplest possible form,
/// so they double as the oracle for the server tests, the fake backend, and
/// the app contract tests.
class FixtureSet {
  FixtureSet({
    required this.accounts,
    required this.classes,
    required this.content,
  });

  /// The phase 1 fixtures without any reconnect delta applied.
  factory FixtureSet.phase1() => FixtureSet(
    accounts: phase1Accounts,
    classes: phase1Classes,
    content: phase1Content,
  );

  final List<AccountFixture> accounts;
  final List<ClassFixture> classes;
  final List<ContentFixture> content;

  /// Returns a copy with the reconnect deltas of exit criterion 7 applied.
  FixtureSet withReconnectDeltas() => FixtureSet(
    accounts: accounts,
    classes: [...classes, reconnectDeltaClass],
    content: [...content, reconnectDeltaContent],
  );

  AccountFixture account(String key) =>
      accounts.firstWhere((a) => a.key == key, orElse: () => _missing(key));

  /// Looks up an account by email, ignoring case and surrounding spaces.
  AccountFixture? accountByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final account in accounts) {
      if (account.email == normalized) return account;
    }
    return null;
  }

  ClassFixture classByKey(String key) =>
      classes.firstWhere((c) => c.key == key, orElse: () => _missing(key));

  /// Classes the student is a member of, in fixture order.
  List<ClassFixture> classesOfStudent(String studentKey) =>
      classes.where((c) => c.studentKeys.contains(studentKey)).toList();

  /// Classes the teacher teaches, sorted by grade, then name.
  List<ClassFixture> classesOfTeacher(String teacherKey) {
    final result = classes.where((c) => c.teacherKey == teacherKey).toList()
      ..sort((a, b) {
        final byGrade = a.gradeLevel.compareTo(b.gradeLevel);
        return byGrade != 0 ? byGrade : a.name.compareTo(b.name);
      });
    return result;
  }

  /// Approved content scoped to at least one of the student's classes,
  /// newest first. This is exactly what `content.library` must return.
  List<ContentFixture> libraryOfStudent(String studentKey) {
    final classKeys = classesOfStudent(studentKey).map((c) => c.key).toSet();
    final result = content
        .where(
          (item) =>
              item.status == FixtureContentStatus.approved &&
              item.classKeys.any(classKeys.contains),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  /// The linked student's display name for a parent, or null.
  String? linkedStudentNameOf(String parentKey) {
    final linkedKey = account(parentKey).linkedStudentKey;
    return linkedKey == null ? null : account(linkedKey).name;
  }

  static Never _missing(String key) =>
      throw ArgumentError.value(key, 'key', 'No fixture with this key');
}
