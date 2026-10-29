import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../generated/protocol.dart';
import 'edubox_caller.dart';
import 'role.dart';

/// Loads the caller's `users` row for the current session, or null when the
/// session is unauthenticated or the auth user has no `users` row.
///
/// The row is read on every call and never cached, so a role change applies
/// to the caller's very next call (exit criterion 13).
Future<EduboxUser?> findCallerUser(Session session) async {
  final authenticated = session.authenticated;
  if (authenticated == null) return null;
  return EduboxUser.db.findFirstRow(
    session,
    where: (t) => t.authUserId.equals(authenticated.authUserId),
  );
}

/// The authorization guard. Every EduBox endpoint method calls this before it
/// touches any data.
///
/// Throws [AccessDeniedException] with:
/// - [AccessDeniedReason.unauthenticated] when there is no session,
/// - [AccessDeniedReason.notSetUp] when the caller has no `users` row, a null
///   role, or a role the server cannot parse,
/// - [AccessDeniedReason.wrongRole] when [allowedRoles] is given and does not
///   contain the caller's role.
Future<EduboxCaller> requireCaller(
  Session session, {
  Set<UserRole>? allowedRoles,
}) async {
  if (session.authenticated == null) {
    throw AccessDeniedException(reason: AccessDeniedReason.unauthenticated);
  }
  final user = await findCallerUser(session);
  final role = parseStoredRole(user?.role);
  if (user == null || role == null) {
    throw AccessDeniedException(reason: AccessDeniedReason.notSetUp);
  }
  if (allowedRoles != null && !allowedRoles.contains(role)) {
    throw AccessDeniedException(reason: AccessDeniedReason.wrongRole);
  }
  return EduboxCaller(user: user, role: role);
}

/// Shorthand for a method only one role may call.
Future<EduboxCaller> requireRole(Session session, UserRole role) =>
    requireCaller(session, allowedRoles: {role});
