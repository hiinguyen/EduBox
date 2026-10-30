import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

/// Email sign-in. Exposes `login` only.
///
/// This endpoint intentionally does not extend `EmailIdpBaseEndpoint`, so the
/// generated client has no registration, account-request, or password-reset
/// call at all (roadmap phase 1, exit criterion 12).
///
/// Errors reach the client typed:
/// - `EmailAccountLoginException(reason: invalidCredentials)` for a wrong
///   email or password (account existence is never revealed),
/// - `EmailAccountLoginException(reason: tooManyAttempts)` after 5 failed
///   attempts within 5 minutes,
/// - `AuthUserBlockedException` for a blocked auth user.
class EmailIdpEndpoint extends Endpoint {
  /// Signs in with email and password and returns a JWT session.
  @unauthenticatedClientCall
  Future<AuthSuccess> login(
    Session session, {
    required String email,
    required String password,
  }) {
    return AuthServices.instance.emailIdp.login(
      session,
      email: email,
      password: password,
    );
  }
}
