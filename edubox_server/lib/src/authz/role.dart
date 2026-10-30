import '../generated/protocol.dart';

/// Parses the raw `users.role` text. Returns null for null, empty, or any
/// value other than the three exact role names (case-sensitive), which the
/// server treats as "not set up".
UserRole? parseStoredRole(String? raw) => switch (raw) {
  'student' => UserRole.student,
  'teacher' => UserRole.teacher,
  'parent' => UserRole.parent,
  _ => null,
};
