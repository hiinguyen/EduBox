import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../authz/edubox_endpoint.dart';
import '../authz/guard.dart';
import '../authz/role.dart';
import '../generated/protocol.dart';

/// The caller's own profile.
class ProfileEndpoint extends EduboxEndpoint {
  /// Returns the caller's own profile (`ready`), or `notSetUp` when the
  /// caller has no `users` row, a null role, or an unparseable role.
  ///
  /// Allowed: any authenticated caller, including not-set-up users. It never
  /// answers `notSetUp` with an error, and never returns another user's data.
  Future<ProfileResult> me(Session session) async {
    final user = await findCallerUser(session);
    final role = parseStoredRole(user?.role);
    if (user == null || role == null) {
      return ProfileResult(
        status: ProfileStatus.notSetUp,
        signedInEmail: user?.email ?? await _emailOfAuthUser(session),
      );
    }
    return ProfileResult(
      status: ProfileStatus.ready,
      signedInEmail: user.email,
      profile: Profile(
        userId: user.id!,
        role: role,
        name: user.name,
        email: user.email,
        linkedStudentName: role == UserRole.parent
            ? user.linkedStudentName
            : null,
      ),
    );
  }

  Future<String?> _emailOfAuthUser(Session session) async {
    final authUserId = session.authenticated?.authUserId;
    if (authUserId == null) return null;
    final account = await EmailAccount.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(authUserId),
    );
    return account?.email;
  }
}
