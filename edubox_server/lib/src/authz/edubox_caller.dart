import '../generated/protocol.dart';

/// The authenticated caller of an EduBox endpoint method, resolved from the
/// session and the `users` table on every call.
class EduboxCaller {
  const EduboxCaller({required this.user, required this.role});

  /// The caller's `users` row, read during this call.
  final EduboxUser user;

  /// The caller's parsed role.
  final UserRole role;

  /// The caller's `users.id`.
  int get userId => user.id!;
}
