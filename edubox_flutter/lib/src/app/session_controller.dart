import 'package:flutter/foundation.dart';

import '../contract/backend.dart';
import '../contract/backend_result.dart';
import '../contract/session.dart';
import 'connectivity_state.dart';

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
  SessionController(this.backend, {this.connectivity}) {
    connectivity?.register(_refreshAfterReconnect);
  }

  final EduBoxBackend backend;
  final ConnectivityState? connectivity;

  AppStage _stage = AppStage.opening;
  AuthSession? _session;
  DateTime? _sessionRefreshedAt;
  bool _isStale = false;
  bool _disposed = false;

  AppStage get stage => _stage;

  AuthSession? get session => _session;

  /// `BackendOk.cachedAt` of the last sign-in, restore or check-again: the
  /// last time the profile was refreshed from the server.
  DateTime? get sessionRefreshedAt => _sessionRefreshedAt;

  /// Restores a stored session (online or from the cache when offline).
  Future<void> start() async {
    _go(AppStage.opening);
    final result = await backend.auth.restoreSession();
    if (_disposed) return;
    switch (result) {
      case BackendOk(:final value, :final cachedAt, :final isStale):
        if (value == null) {
          _clearSession();
          _go(AppStage.signedOut);
        } else {
          accept(value, refreshedAt: cachedAt, isStale: isStale);
        }
      case BackendFailure(error: SessionExpiredError()):
        _clearSession();
        _go(AppStage.signedOut);
      case BackendFailure():
        _go(AppStage.startFailed);
    }
  }

  /// Routes a freshly resolved session to its stage.
  void accept(
    AuthSession session, {
    DateTime? refreshedAt,
    bool isStale = false,
  }) {
    if (_disposed) return;
    _session = session;
    _sessionRefreshedAt = refreshedAt;
    _isStale = isStale;
    _go(session.isReady ? AppStage.home : AppStage.notSetUp);
  }

  /// Re-resolves a session restored from the offline cache when the seam
  /// comes back online, so a role changed or removed while offline applies
  /// without a restart (contract 3.2/3.4). The cached role is render-only;
  /// this is the authoritative read that follows it.
  Future<void> _refreshAfterReconnect() async {
    if (_disposed || _session == null || !_isStale) return;
    final result = await backend.auth.refreshProfile();
    if (_disposed) return;
    switch (result) {
      case BackendOk(:final value, :final cachedAt):
        accept(value, refreshedAt: cachedAt);
      case BackendFailure(error: SessionExpiredError()):
        _clearSession();
        _go(AppStage.signedOut);
      case BackendFailure():
        // Transient: keep rendering the cached role home; the next reconnect
        // tries again.
        break;
    }
  }

  /// A call reported `SessionExpiredError`: clear locally, go to sign-in.
  Future<void> expire() async {
    final result = await backend.auth.signOut();
    if (_disposed) return;
    if (result case BackendFailure(:final error)) {
      debugPrint('EduBox session expire: local sign-out failed: $error');
    }
    _clearSession();
    _go(AppStage.signedOut);
  }

  /// Signs out. On failure the stage does not change and the error is
  /// returned for the caller to show.
  Future<BackendError?> signOut() async {
    final result = await backend.auth.signOut();
    if (_disposed) return null;
    if (result case BackendFailure(:final error)) return error;
    _clearSession();
    _go(AppStage.signedOut);
    return null;
  }

  void _clearSession() {
    _session = null;
    _sessionRefreshedAt = null;
    _isStale = false;
  }

  void _go(AppStage stage) {
    if (_disposed) return;
    _stage = stage;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    connectivity?.unregister(_refreshAfterReconnect);
    super.dispose();
  }
}
