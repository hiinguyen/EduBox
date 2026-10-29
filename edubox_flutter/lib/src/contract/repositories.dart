import 'package:edubox_client/edubox_client.dart';

import 'backend_result.dart';
import 'session.dart';

/// Sign-in, session restore, check-again and sign-out.
abstract interface class AuthRepository {
  /// Signs in with email/password and resolves the EduBox profile.
  ///
  /// Failures: wrong credentials, too many attempts, account disabled,
  /// backend unreachable, unexpected.
  Future<BackendResult<AuthSession>> signIn({
    required String email,
    required String password,
  });

  /// Restores a stored session without contacting the server when the
  /// session manager supports offline restore. `BackendOk(null)` means
  /// "no stored session".
  Future<BackendResult<AuthSession?>> restoreSession();

  /// Re-runs only the profile/role resolution (account-not-set-up
  /// "check again"); never re-authenticates.
  ///
  /// Failures: backend unreachable, unexpected.
  Future<BackendResult<AuthSession>> refreshProfile();

  Future<BackendResult<void>> signOut();
}

/// `profile.me`: the caller's own profile, or a typed not-set-up state.
abstract interface class ProfileRepository {
  Future<BackendResult<ProfileResult>> me();
}

/// `classes.mine`: the calling teacher's classes.
abstract interface class ClassesRepository {
  Future<BackendResult<List<ClassSummary>>> mine();
}

/// `content.library`: the calling student's approved content.
abstract interface class LibraryRepository {
  Future<BackendResult<StudentLibrary>> library();
}

/// Phase 1 parent home data (derived from `profile.me` on the server binding).
abstract interface class ParentRepository {
  Future<BackendResult<ParentHomeData>> home();
}

/// `diagnostics.pingStream`: three role-carrying messages, then close.
abstract interface class DiagnosticsRepository {
  Stream<PingMessage> pingStream();
}
