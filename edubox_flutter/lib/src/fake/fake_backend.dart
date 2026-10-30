import 'dart:async';

import 'package:edubox_client/edubox_client.dart';
import 'package:edubox_fixtures/edubox_fixtures.dart';

import '../contract/backend.dart';
import '../contract/backend_result.dart';
import '../contract/network_controller.dart';
import '../contract/repositories.dart';
import '../contract/session.dart';

/// How the fake answers data calls. It is derived from [NetworkController]:
/// the fake never keeps a second, independent offline switch.
enum FakeMode {
  /// Normal server answers.
  online,

  /// Offline, but the role home still has its last cached data.
  offlineWithCache,

  /// Offline with an empty cache: screens show their offline-no-data state.
  offlineWithoutCache,
}

/// A fixture-backed backend for every phase 1 screen state.
///
/// It enforces the same role rules as the server, so a wrong-role caller is
/// denied here too. Failure fields switch individual calls without changing
/// the account data; [setRole] simulates an administrator fixing a profile.
///
/// Offline behaviour follows [network] exactly: online calls return fixture
/// data with `BackendOk.cachedAt`, offline/reconnecting calls return the same
/// data as stale while [hasCache] is true, and `OfflineNoCacheError` once it
/// is false. [holdCalls] keeps a call pending for loading/busy previews.
class FakeBackend implements EduBoxBackend {
  FakeBackend({
    FixtureSet? fixtures,
    NetworkController? network,
    this.hasCache = true,
    this.password = devPassword,
    this.latency = Duration.zero,
    DateTime Function()? clock,
  }) : fixtures = fixtures ?? FixtureSet.phase1(),
       network = network ?? ManualNetworkController(),
       _clock = clock ?? DateTime.now;

  FixtureSet fixtures;
  final String password;
  final NetworkController network;
  final DateTime Function() _clock;

  /// False models a device whose drift cache was cleared.
  bool hasCache;

  /// Artificial latency for loading and busy previews.
  Duration latency;

  BackendError? signInError;
  BackendError? restoreError;
  BackendError? profileError;
  BackendError? classesError;
  BackendError? libraryError;
  BackendError? parentError;
  BackendError? pingError;
  BackendError? signOutError;

  final Map<String, String?> _roleOverrides = {};
  final Map<String, int> _failedSignIns = {};
  AccountFixture? _signedInAccount;
  DateTime? _lastRefreshAt;
  Completer<void>? _gate;

  bool get isOnline => network.status == NetworkStatus.online;

  FakeMode get mode {
    if (isOnline) return FakeMode.online;
    return hasCache ? FakeMode.offlineWithCache : FakeMode.offlineWithoutCache;
  }

  /// Compatibility switch for previews; it drives [network], never a second
  /// offline flag.
  set mode(FakeMode value) {
    hasCache = value != FakeMode.offlineWithoutCache;
    final controller = network;
    if (controller is ManualNetworkController) {
      if (value == FakeMode.online) {
        controller.goOnline();
      } else {
        controller.goOffline();
      }
    }
  }

  AuthSession? get currentSession => _signedInAccount == null
      ? null
      : AuthSession(
          signedInEmail: _signedInAccount!.email,
          profileResult: _profileOf(_signedInAccount!),
        );

  /// Signs in as a fixture account without exercising credentials, for
  /// screen previews and widget tests.
  AuthSession signInAs(String accountKey) {
    _signedInAccount = fixtures.account(accountKey);
    _lastRefreshAt = _clock().toUtc();
    return currentSession!;
  }

  /// Simulates the admin changing the raw `users.role` value.
  void setRole(String accountKey, String? role) {
    _roleOverrides[accountKey] = role;
  }

  /// Applies exit criterion 7's server-side reconnect deltas mid-session.
  void applyReconnectDeltas() {
    fixtures = fixtures.withReconnectDeltas();
  }

  /// Empties the modelled local cache for offline-no-cache previews.
  void clearCache() {
    hasCache = false;
    _lastRefreshAt = null;
  }

  /// Keeps every later call pending until [releaseCalls].
  Completer<void> holdCalls() => _gate ??= Completer<void>();

  void releaseCalls() {
    final gate = _gate;
    _gate = null;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  /// Clears any call-specific failure.
  void clearFailures() {
    signInError = null;
    restoreError = null;
    profileError = null;
    classesError = null;
    libraryError = null;
    parentError = null;
    pingError = null;
    signOutError = null;
  }

  @override
  AuthRepository get auth => _FakeAuth(this);

  @override
  ProfileRepository get profile => _FakeProfile(this);

  @override
  ClassesRepository get classes => _FakeClasses(this);

  @override
  LibraryRepository get library => _FakeLibrary(this);

  @override
  ParentRepository get parent => _FakeParent(this);

  @override
  DiagnosticsRepository get diagnostics => _FakeDiagnostics(this);

  @override
  Future<void> dispose() async {}

  Future<void> _wait() async {
    final gate = _gate;
    if (gate != null) await gate.future;
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }

  DateTime get lastRefreshAt => _lastRefreshAt ??= _clock().toUtc();

  DateTime _touchRefresh() => _lastRefreshAt = _clock().toUtc();

  BackendResult<T> _dataResult<T>(T Function() build) {
    if (!isOnline) {
      if (!hasCache) return BackendFailure<T>(const OfflineNoCacheError());
      return BackendOk<T>(
        build(),
        cachedAt: lastRefreshAt,
        isStale: true,
      );
    }
    return BackendOk<T>(build(), cachedAt: _touchRefresh());
  }

  AuthSession? _sessionForCall() {
    final account = _signedInAccount;
    if (account == null) return null;
    return AuthSession(
      signedInEmail: account.email,
      profileResult: _profileOf(account),
    );
  }

  ProfileResult _profileOf(AccountFixture account) {
    final rawRole = _roleOverrides[account.key] ?? account.role;
    final role = rawRole == null ? null : UserRole.values.asNameMap()[rawRole];
    if (!account.hasProfile || role == null) {
      return ProfileResult(
        status: ProfileStatus.notSetUp,
        signedInEmail: account.email,
      );
    }
    final linkedKey = account.linkedStudentKey;
    return ProfileResult(
      status: ProfileStatus.ready,
      signedInEmail: account.email,
      profile: Profile(
        userId: _userIdOf(account),
        role: role,
        name: account.name,
        email: account.email,
        linkedStudentName: linkedKey == null
            ? null
            : fixtures.account(linkedKey).name,
      ),
    );
  }

  int _userIdOf(AccountFixture account) =>
      fixtures.accounts.indexOf(account) + 1;

  BackendError? _roleFailure(UserRole role) {
    final session = _sessionForCall();
    if (session == null) return const SessionExpiredError();
    if (session.isNotSetUp) return const NotSetUpError();
    if (session.role != role) return const PermissionDeniedError();
    return null;
  }

  List<ClassSummary> _teacherClasses() => [
    for (final (index, item)
        in fixtures.classesOfTeacher(_signedInAccount!.key).indexed)
      ClassSummary(
        id: index + 1,
        name: item.name,
        gradeLevel: item.gradeLevel,
        subjects: List.unmodifiable(item.subjects),
        studentCount: item.studentKeys.length,
      ),
  ];

  StudentLibrary _studentLibrary() {
    final classes = fixtures.classesOfStudent(_signedInAccount!.key);
    return StudentLibrary(
      classes: [
        for (final (index, item) in classes.indexed)
          StudentClass(
            id: index + 1,
            name: item.name,
            gradeLevel: item.gradeLevel,
            subjects: List.unmodifiable(item.subjects),
          ),
      ],
      items: [
        for (final (index, item)
            in fixtures.libraryOfStudent(_signedInAccount!.key).indexed)
          LibraryItem(
            id: index + 1,
            type: ContentType.values.byName(item.type.name),
            title: item.title,
            subject: item.subject,
            gradeLevel: item.gradeLevel,
            createdAt: item.createdAt,
          ),
      ],
    );
  }

  ParentHomeData _parentHome() => ParentHomeData(
    linkedStudentName: fixtures.linkedStudentNameOf(_signedInAccount!.key),
  );
}

class _FakeAuth implements AuthRepository {
  _FakeAuth(this.fake);

  final FakeBackend fake;

  static const _maxFailedAttempts = 5;

  @override
  Future<BackendResult<AuthSession>> signIn({
    required String email,
    required String password,
  }) async {
    await fake._wait();
    if (fake.signInError != null) {
      return BackendFailure(fake.signInError!);
    }
    if (!fake.isOnline) {
      return const BackendFailure(BackendUnreachableError());
    }
    final normalized = email.trim().toLowerCase();
    if ((fake._failedSignIns[normalized] ?? 0) >= _maxFailedAttempts) {
      return const BackendFailure(TooManyAttemptsError());
    }
    final account = fake.fixtures.accountByEmail(normalized);
    if (account == null || password != fake.password) {
      fake._failedSignIns[normalized] =
          (fake._failedSignIns[normalized] ?? 0) + 1;
      return const BackendFailure(WrongCredentialsError());
    }
    if (account.blocked) {
      return const BackendFailure(AccountDisabledError());
    }
    fake._failedSignIns.remove(normalized);
    fake._signedInAccount = account;
    fake._touchRefresh();
    return BackendOk(
      fake.currentSession!,
      cachedAt: fake.lastRefreshAt,
    );
  }

  @override
  Future<BackendResult<AuthSession?>> restoreSession() async {
    await fake._wait();
    if (fake.restoreError != null) {
      return BackendFailure(fake.restoreError!);
    }
    final session = fake.currentSession;
    if (session == null) return const BackendOk(null);
    return BackendOk(
      session,
      cachedAt: fake.lastRefreshAt,
      isStale: !fake.isOnline,
    );
  }

  @override
  Future<BackendResult<AuthSession>> refreshProfile() async {
    await fake._wait();
    if (fake.profileError != null) {
      return BackendFailure(fake.profileError!);
    }
    if (!fake.isOnline) {
      return const BackendFailure(BackendUnreachableError());
    }
    if (fake._signedInAccount == null) {
      return const BackendFailure(SessionExpiredError());
    }
    return BackendOk(
      fake.currentSession!,
      cachedAt: fake._touchRefresh(),
    );
  }

  @override
  Future<BackendResult<void>> signOut() async {
    await fake._wait();
    if (fake.signOutError != null) {
      return BackendFailure(fake.signOutError!);
    }
    // Sign-out clears the local session even offline; the server call is
    // best effort.
    fake._signedInAccount = null;
    return const BackendOk(null);
  }
}

class _FakeProfile implements ProfileRepository {
  _FakeProfile(this.fake);

  final FakeBackend fake;

  @override
  Future<BackendResult<ProfileResult>> me() async {
    await fake._wait();
    if (fake.profileError != null) {
      return BackendFailure(fake.profileError!);
    }
    final session = fake._sessionForCall();
    if (session == null) {
      return const BackendFailure(SessionExpiredError());
    }
    return fake._dataResult(() => session.profileResult);
  }
}

class _FakeClasses implements ClassesRepository {
  _FakeClasses(this.fake);

  final FakeBackend fake;

  @override
  Future<BackendResult<List<ClassSummary>>> mine() async {
    await fake._wait();
    if (fake.classesError != null) {
      return BackendFailure(fake.classesError!);
    }
    final denial = fake._roleFailure(UserRole.teacher);
    if (denial != null) return BackendFailure(denial);
    return fake._dataResult(fake._teacherClasses);
  }
}

class _FakeLibrary implements LibraryRepository {
  _FakeLibrary(this.fake);

  final FakeBackend fake;

  @override
  Future<BackendResult<StudentLibrary>> library() async {
    await fake._wait();
    if (fake.libraryError != null) {
      return BackendFailure(fake.libraryError!);
    }
    final denial = fake._roleFailure(UserRole.student);
    if (denial != null) return BackendFailure(denial);
    return fake._dataResult(fake._studentLibrary);
  }
}

class _FakeParent implements ParentRepository {
  _FakeParent(this.fake);

  final FakeBackend fake;

  @override
  Future<BackendResult<ParentHomeData>> home() async {
    await fake._wait();
    if (fake.parentError != null) {
      return BackendFailure(fake.parentError!);
    }
    final denial = fake._roleFailure(UserRole.parent);
    if (denial != null) return BackendFailure(denial);
    return fake._dataResult(fake._parentHome);
  }
}

class _FakeDiagnostics implements DiagnosticsRepository {
  _FakeDiagnostics(this.fake);

  final FakeBackend fake;

  static const total = 3;

  @override
  Stream<PingMessage> pingStream() async* {
    await fake._wait();
    if (fake.pingError != null) {
      throw BackendException(fake.pingError!);
    }
    if (!fake.isOnline) {
      throw const BackendException(BackendUnreachableError());
    }
    final session = fake._sessionForCall();
    if (session == null) {
      throw const BackendException(SessionExpiredError());
    }
    if (session.isNotSetUp) {
      throw const BackendException(NotSetUpError());
    }
    for (var sequence = 1; sequence <= total; sequence++) {
      if (sequence > 1) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      yield PingMessage(
        sequence: sequence,
        total: total,
        role: session.role!,
        sentAt: DateTime.now().toUtc(),
      );
    }
  }
}
