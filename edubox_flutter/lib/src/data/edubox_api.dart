import 'package:edubox_client/edubox_client.dart'
    show ClassSummary, PingMessage, ProfileResult, StudentLibrary;

/// The raw server calls the data layer needs, one method per endpoint.
///
/// Every method throws the server/transport exception unchanged; the caller
/// maps it with `mapApiError`. Production is `ClientEduBoxApi` (the
/// generated Serverpod client); unit tests use a fixture-backed fake.
abstract interface class EduBoxApi {
  /// `emailIdp.login`, then stores the returned session in the auth module's
  /// session manager.
  Future<void> login({required String email, required String password});

  /// Restores the stored auth session from local secure storage without a
  /// server call. Returns true when a session is stored.
  Future<bool> restoreStoredAuth();

  /// `profile.me`.
  Future<ProfileResult> profileMe();

  /// `classes.mine`.
  Future<List<ClassSummary>> classesMine();

  /// `content.library`.
  Future<StudentLibrary> contentLibrary();

  /// `diagnostics.pingStream`.
  Stream<PingMessage> pingStream();

  /// Best-effort server sign-out; always clears the stored auth session,
  /// even when the server call fails.
  Future<void> signOut();

  /// Clears the stored auth session without a server call.
  Future<void> clearStoredAuth();

  Future<void> close();
}
