import 'dart:async';

import 'package:edubox_client/edubox_client.dart'
    show
        ClassSummary,
        PingMessage,
        ProfileResult,
        ProfileStatus,
        StudentLibrary,
        UserRole;

import '../contract/backend.dart';
import '../contract/backend_result.dart';
import '../contract/network_controller.dart';
import '../contract/repositories.dart';
import '../contract/session.dart';
import '../local/local_store.dart';
import 'edubox_api.dart';
import 'error_mapping.dart';

/// The production [EduBoxBackend]: the server API, the drift cache and the
/// network seam (contract.md sections 3.3-3.5).
///
/// Online it calls the server, saves the snapshot and returns
/// `isStale: false`. Offline or reconnecting it never dials the server: data
/// reads return the snapshot with `isStale: true` or `OfflineNoCacheError`,
/// and `signIn` / `refreshProfile` fail fast with `BackendUnreachableError`.
/// On every `offline|reconnecting -> online` transition it refreshes
/// `profile.me` and the signed-in role home in the background. It owns
/// [api] and [store] and closes both in [dispose].
class CachedBackend implements EduBoxBackend {
  CachedBackend({
    required this.api,
    required this.store,
    required this.network,
  }) {
    _lastStatus = network.status;
    _networkSub = network.changes.listen(_onNetworkChange);
  }

  final EduBoxApi api;
  final CachedDataStore store;
  final NetworkController network;

  late NetworkStatus _lastStatus;
  late final StreamSubscription<NetworkStatus> _networkSub;

  /// Completes when the most recent reconnect refresh finishes (tests).
  Future<void> reconnectRefresh = Future.value();

  bool get _online => network.status == NetworkStatus.online;

  @override
  late final AuthRepository auth = _Auth(this);

  @override
  late final ProfileRepository profile = _Profile(this);

  @override
  late final ClassesRepository classes = _Classes(this);

  @override
  late final LibraryRepository library = _Library(this);

  @override
  late final ParentRepository parent = _Parent(this);

  @override
  late final DiagnosticsRepository diagnostics = _Diagnostics(this);

  @override
  Future<void> dispose() async {
    await _networkSub.cancel();
    await api.close();
    await store.close();
  }

  void _onNetworkChange(NetworkStatus status) {
    final wasOffline = _lastStatus != NetworkStatus.online;
    _lastStatus = status;
    if (wasOffline && status == NetworkStatus.online) {
      reconnectRefresh = _refreshAfterReconnect();
    }
  }

  Future<void> _refreshAfterReconnect() async {
    final cached = await store.readSession();
    if (cached == null) return;
    final me = await profile.me();
    final session = me.valueOrNull;
    if (session == null || session.status != ProfileStatus.ready) return;
    switch (session.profile?.role) {
      case UserRole.student:
        await library.library();
      case UserRole.teacher:
        await classes.mine();
      case UserRole.parent:
        await parent.home();
      case null:
        break;
    }
  }

  /// Runs [call] against the server, mapping any exception.
  Future<BackendResult<T>> _guard<T>(
    Future<BackendResult<T>> Function() call,
  ) async {
    try {
      return await call();
    } catch (error) {
      return BackendFailure<T>(mapApiError(error));
    }
  }

  /// Saves the session for a fresh `profile.me` answer.
  Future<AuthSession> _saveProfile(ProfileResult result, String? email) async {
    final cached = await store.readSession();
    final session = AuthSession(
      signedInEmail:
          result.signedInEmail ?? email ?? cached?.value.signedInEmail ?? '',
      profileResult: result,
    );
    await store.saveSession(session);
    return session;
  }

  /// Offline role gate from the cached session (render-only, never an
  /// authorization decision; the server re-checks every online call).
  Future<BackendError?> _offlineRoleFailure(UserRole role) async {
    final cached = await store.readSession();
    if (cached == null) return const OfflineNoCacheError();
    final session = cached.value;
    if (session.isNotSetUp) return const NotSetUpError();
    if (session.role != role) return const PermissionDeniedError();
    return null;
  }
}

class _Auth implements AuthRepository {
  _Auth(this.b);

  final CachedBackend b;

  @override
  Future<BackendResult<AuthSession>> signIn({
    required String email,
    required String password,
  }) async {
    if (!b._online) return const BackendFailure(BackendUnreachableError());
    final normalized = email.trim().toLowerCase();
    return b._guard(() async {
      await b.api.login(email: normalized, password: password);
      final result = await b.api.profileMe();
      final session = await b._saveProfile(result, normalized);
      final saved = await b.store.readSession();
      return BackendOk(session, cachedAt: saved?.cachedAt);
    });
  }

  @override
  Future<BackendResult<AuthSession?>> restoreSession() async {
    if (!b._online) {
      final cached = await b.store.readSession();
      if (cached == null) return const BackendOk(null);
      return BackendOk(cached.value, cachedAt: cached.cachedAt, isStale: true);
    }
    final hasAuth = await b._guard<bool>(
      () async => BackendOk(await b.api.restoreStoredAuth()),
    );
    if (hasAuth case BackendFailure(:final error)) return BackendFailure(error);
    if (hasAuth.valueOrNull != true) {
      await b.store.clearAll();
      return const BackendOk(null);
    }
    final result = await _refresh();
    if (result case BackendFailure(error: SessionExpiredError())) {
      await b.api.clearStoredAuth();
      await b.store.clearAll();
      return const BackendOk(null);
    }
    return result;
  }

  @override
  Future<BackendResult<AuthSession>> refreshProfile() async {
    if (!b._online) return const BackendFailure(BackendUnreachableError());
    final hasAuth = await b._guard<bool>(
      () async => BackendOk(await b.api.restoreStoredAuth()),
    );
    if (hasAuth case BackendFailure(:final error)) return BackendFailure(error);
    if (hasAuth.valueOrNull != true) {
      return const BackendFailure(SessionExpiredError());
    }
    return _refresh();
  }

  Future<BackendResult<AuthSession>> _refresh() => b._guard(() async {
    final result = await b.api.profileMe();
    final session = await b._saveProfile(result, null);
    final saved = await b.store.readSession();
    return BackendOk(session, cachedAt: saved?.cachedAt);
  });

  @override
  Future<BackendResult<void>> signOut() async {
    if (b._online) {
      try {
        await b.api.signOut();
      } catch (_) {
        // Best effort: the local session is cleared below regardless.
        await b.api.clearStoredAuth();
      }
    } else {
      await b.api.clearStoredAuth();
    }
    try {
      await b.store.clearAll();
      return const BackendOk(null);
    } catch (error) {
      return BackendFailure(UnexpectedBackendError(error));
    }
  }
}

class _Profile implements ProfileRepository {
  _Profile(this.b);

  final CachedBackend b;

  @override
  Future<BackendResult<ProfileResult>> me() async {
    if (!b._online) {
      final cached = await b.store.readSession();
      if (cached == null) return const BackendFailure(OfflineNoCacheError());
      return BackendOk(
        cached.value.profileResult,
        cachedAt: cached.cachedAt,
        isStale: true,
      );
    }
    return b._guard(() async {
      final result = await b.api.profileMe();
      await b._saveProfile(result, null);
      final saved = await b.store.readSession();
      return BackendOk(result, cachedAt: saved?.cachedAt);
    });
  }
}

class _Classes implements ClassesRepository {
  _Classes(this.b);

  final CachedBackend b;

  @override
  Future<BackendResult<List<ClassSummary>>> mine() async {
    if (!b._online) {
      final denial = await b._offlineRoleFailure(UserRole.teacher);
      if (denial != null) return BackendFailure(denial);
      final cached = await b.store.readTeacherClasses();
      if (cached == null) return const BackendFailure(OfflineNoCacheError());
      return BackendOk(cached.value, cachedAt: cached.cachedAt, isStale: true);
    }
    return b._guard(() async {
      final value = await b.api.classesMine();
      await b.store.saveTeacherClasses(value);
      final saved = await b.store.readTeacherClasses();
      return BackendOk(value, cachedAt: saved?.cachedAt);
    });
  }
}

class _Library implements LibraryRepository {
  _Library(this.b);

  final CachedBackend b;

  @override
  Future<BackendResult<StudentLibrary>> library() async {
    if (!b._online) {
      final denial = await b._offlineRoleFailure(UserRole.student);
      if (denial != null) return BackendFailure(denial);
      final cached = await b.store.readStudentLibrary();
      if (cached == null) return const BackendFailure(OfflineNoCacheError());
      return BackendOk(cached.value, cachedAt: cached.cachedAt, isStale: true);
    }
    return b._guard(() async {
      final value = await b.api.contentLibrary();
      await b.store.saveStudentLibrary(value);
      final saved = await b.store.readStudentLibrary();
      return BackendOk(value, cachedAt: saved?.cachedAt);
    });
  }
}

class _Parent implements ParentRepository {
  _Parent(this.b);

  final CachedBackend b;

  @override
  Future<BackendResult<ParentHomeData>> home() async {
    if (!b._online) {
      final denial = await b._offlineRoleFailure(UserRole.parent);
      if (denial != null) return BackendFailure(denial);
      final cached = await b.store.readParentHome();
      if (cached == null) return const BackendFailure(OfflineNoCacheError());
      return BackendOk(cached.value, cachedAt: cached.cachedAt, isStale: true);
    }
    return b._guard(() async {
      final result = await b.api.profileMe();
      await b._saveProfile(result, null);
      final profile = result.profile;
      if (result.status != ProfileStatus.ready || profile == null) {
        return const BackendFailure(NotSetUpError());
      }
      if (profile.role != UserRole.parent) {
        return const BackendFailure(PermissionDeniedError());
      }
      final data = ParentHomeData(linkedStudentName: profile.linkedStudentName);
      await b.store.saveParentHome(data);
      final saved = await b.store.readParentHome();
      return BackendOk(data, cachedAt: saved?.cachedAt);
    });
  }
}

class _Diagnostics implements DiagnosticsRepository {
  _Diagnostics(this.b);

  final CachedBackend b;

  @override
  Stream<PingMessage> pingStream() {
    if (!b._online) {
      return Stream.error(const BackendException(BackendUnreachableError()));
    }
    return b.api.pingStream().handleError(
      (Object error) => throw BackendException(mapApiError(error)),
    );
  }
}
