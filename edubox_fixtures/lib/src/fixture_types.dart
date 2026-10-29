/// Plain data types for the shared fixtures.
///
/// These types are deliberately independent of the server, the generated
/// client, and Flutter, so every consumer can depend on them.
library;

/// One sign-in account: a Serverpod auth user with an email identity, plus an
/// optional EduBox `users` row.
class AccountFixture {
  const AccountFixture({
    required this.key,
    required this.email,
    required this.name,
    this.hasProfile = true,
    this.role,
    this.linkedStudentKey,
    this.blocked = false,
  });

  /// Stable symbolic key used by tests and the fake (never stored).
  final String key;

  /// Sign-in email, lower case.
  final String email;

  /// Full Vietnamese name stored in `users.name`.
  final String name;

  /// False for the auth user that has no `users` row at all.
  final bool hasProfile;

  /// Raw value stored in `users.role`: `student`, `teacher`, `parent`, or
  /// null for the null-role fixture. Ignored when [hasProfile] is false.
  final String? role;

  /// Parents only: the [key] of the linked student, or null when the parent
  /// has no linked child.
  final String? linkedStudentKey;

  /// True when the auth user is blocked (sign-in answers account disabled).
  final bool blocked;
}

/// One class with its teacher, ordered subjects, and members.
class ClassFixture {
  const ClassFixture({
    required this.key,
    required this.name,
    required this.gradeLevel,
    required this.teacherKey,
    required this.subjects,
    required this.studentKeys,
  });

  final String key;
  final String name;
  final int gradeLevel;
  final String teacherKey;

  /// Teacher-ordered subjects; the order is stored and returned.
  final List<String> subjects;
  final List<String> studentKeys;
}

/// Content type values stored in `content.type`.
enum FixtureContentType { ebook, video, exercise }

/// Content status values stored in `content.status`.
enum FixtureContentStatus { draft, approved }

/// One content metadata row and its class scope.
class ContentFixture {
  const ContentFixture({
    required this.key,
    required this.type,
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.status,
    required this.ownerKey,
    required this.classKeys,
    required this.createdAt,
  });

  final String key;
  final FixtureContentType type;
  final String title;

  /// Empty string means "no subject" (the library's `librarySubjectOther`).
  final String subject;
  final int gradeLevel;
  final FixtureContentStatus status;

  /// Owning teacher; also `approvedBy` when [status] is approved.
  final String ownerKey;
  final List<String> classKeys;
  final DateTime createdAt;
}
