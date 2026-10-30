import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

/// The token manager used by every run mode: JWT access tokens validated
/// without a database round trip, refreshed through `jwtRefresh`.
List<TokenManagerBuilder> eduboxTokenManagerBuilders() => [
  JwtConfigFromPasswords(),
];

/// The only identity provider: email and password.
///
/// Accounts are created by the seed/admin script only. Registration and
/// password reset are never exposed (see `email_idp_endpoint.dart`), so the
/// verification-code callbacks are left unset and nothing sends email.
List<IdentityProviderBuilder> eduboxIdentityProviderBuilders() => [
  EmailIdpConfigFromPasswords(),
];

/// Registers EduBox authentication on [pod]. Tests call [AuthServices.set]
/// with the same builders (see `test/integration/support/harness.dart`).
void configureAuthServices(Serverpod pod) {
  pod.initializeAuthServices(
    tokenManagerBuilders: eduboxTokenManagerBuilders(),
    identityProviderBuilders: eduboxIdentityProviderBuilders(),
  );
}
