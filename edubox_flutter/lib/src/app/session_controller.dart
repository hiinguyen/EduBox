import 'package:flutter/foundation.dart';

import '../contract/backend.dart';
import '../contract/backend_result.dart';
import '../contract/session.dart';

/// Which top-level screen the app shows. Each stage replaces the previous
/// one (no back stack), so system back at any root exits the app.
enum AppStage {
  /// Restoring a stored session: the mark and `appOpening`.
  opening,

  /// App-start session or role resolution failed: the panel with
  /// `backendUnreachable` and `retry`.
  startFailed,

  /// No session: `sign-in`.
  signedOut,

  /// Signed in, but no valid role: `account-not-set-up`.
  notSetUp,

  /// Signed in with a role: the role home.
  home,
}

/// Owns the signed-in session and the top-level stage.
class SessionController extends ChangeNotifier {
  SessionController(this.backend);

  final EduBoxBackend backend;

  AppStage _stage = AppStage.opening;
  AuthSession? _session;
  DateTime? _sessionRefreshedAt;

  AppStage get stage => _stage;

  AuthSession? get session => _session;

  /// `BackendOk.cachedAt` of the last sign-in, restore or check-again: the
  /// last time the profile was refreshed from the server.
  DateTime? get sessionRefreshedAt => _sessionRefreshedAt;

  /// Restores a stored session (online or from the cache when offline).
  Future<void> start() async {
    _go(AppStage.opening);
    final result = await backend.auth.restoreSession();
    switch (result) {
      case BackendOk(:final value, :final cachedAt):
        if (value == null) {
          _session = null;
          _go(AppStage.signedOut);
        } else {
          accept(value, refreshedAt: cachedAt);
        }
      case BackendFailure(error: SessionExpiredError()):
        _session = null;
        _go(AppStage.signedOut);
      case BackendFailure():
        _go(AppStage.startFailed);
    }
  }

  /// Routes a freshly resolved session to its stage.
  void accept(AuthSession session, {DateTime? refreshedAt}) {
    _session = session;
    _sessionRefreshedAt = refreshedAt;
    _go(session.isReady ? AppStage.home : AppStage.notSetUp);
  }

  /// A call reported `SessionExpiredError`: clear locally, go to sign-in.
  Future<void> expire() async {
    await backend.auth.signOut();
    _session = null;
    _go(AppStage.signedOut);
  }

  /// Signs out. On failure the stage does not change and the error is
  /// returned for the caller to show.
  Future<BackendError?> signOut() async {
    final result = await backend.auth.signOut();
    if (result case BackendFailure(:final error)) return error;
    _session = null;
    _sessionRefreshedAt = null;
    _go(AppStage.signedOut);
    return null;
  }

  void _go(AppStage stage) {
    _stage = stage;
    notifyListeners();
  }
}
