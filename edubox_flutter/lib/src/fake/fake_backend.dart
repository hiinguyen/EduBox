import 'dart:async';

import 'package:edubox_client/edubox_client.dart';
import 'package:edubox_fixtures/edubox_fixtures.dart';

import '../contract/backend.dart';
import '../contract/backend_result.dart';
import '../contract/repositories.dart';
import '../contract/session.dart';

/// How the fake answers data calls.
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
class FakeBackend implements EduBoxBackend {
  FakeBackend({
    FixtureSet? fixtures,
    this.mode = FakeMode.online,
    this.password = devPassword,
  }) : fixtures = fixtures ?? FixtureSet.phase1();

  final FixtureSet fixtures;
  final String password;

  FakeMode mode;

  BackendError? signInError;
  BackendError? restoreError;
  BackendError? profileError;
  BackendError? classesError;
  BackendError? libraryError;
  BackendError? parentError;
  BackendError? pingError;
  BackendError? signOutError;

  final Map<String, String?> _roleOverrides = {};
  AccountFixture? _signedInAccount;

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
    return currentSession!;
  }

  /// Simulates the admin changing the raw `users.role` value.
  void setRole(String accountKey, String? role) {
    _roleOverrides[accountKey] = role;
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
    if (session == null) return const PermissionDeniedError();
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

  @override
  Future<BackendResult<AuthSession>> signIn({
    required String email,
    required String password,
  }) async {
    if (fake.signInError != null) {
      return BackendFailure(fake.signInError!);
    }
    if (fake.mode != FakeMode.online) {
      return const BackendFailure(BackendUnreachableError());
    }
    final account = fake.fixtures.accountByEmail(email);
    if (account == null || password != fake.password) {
      return const BackendFailure(WrongCredentialsError());
    }
    if (account.blocked) {
      return const BackendFailure(AccountDisabledError());
    }
    fake._signedInAccount = account;
    return BackendOk(fake.currentSession!);
  }

  @override
  Future<BackendResult<AuthSession?>> restoreSession() async {
    if (fake.restoreError != null) {
      return BackendFailure(fake.restoreError!);
    }
    return BackendOk(fake.currentSession);
  }

  @override
  Future<BackendResult<AuthSession>> refreshProfile() async {
    if (fake.profileError != null) {
      return BackendFailure(fake.profileError!);
    }
    if (fake._signedInAccount == null) {
      return const BackendFailure(NotSetUpError());
    }
    if (fake.mode != FakeMode.online) {
      return const BackendFailure(BackendUnreachableError());
    }
    return BackendOk(fake.currentSession!);
  }

  @override
  Future<BackendResult<void>> signOut() async {
    if (fake.signOutError != null) {
      return BackendFailure(fake.signOutError!);
    }
    fake._signedInAccount = null;
    return const BackendOk(null);
  }
}

class _FakeProfile implements ProfileRepository {
  _FakeProfile(this.fake);

  final FakeBackend fake;

  @override
  Future<BackendResult<ProfileResult>> me() async {
    if (fake.profileError != null) {
      return BackendFailure(fake.profileError!);
    }
    final session = fake._sessionForCall();
    if (session == null) {
      return const BackendFailure(PermissionDeniedError());
    }
    if (fake.mode == FakeMode.offlineWithoutCache) {
      return const BackendFailure(OfflineNoCacheError());
    }
    return BackendOk(session.profileResult);
  }
}

class _FakeClasses implements ClassesRepository {
  _FakeClasses(this.fake);

  final FakeBackend fake;

  @override
  Future<BackendResult<List<ClassSummary>>> mine() async {
    if (fake.classesError != null) {
      return BackendFailure(fake.classesError!);
    }
    final denial = fake._roleFailure(UserRole.teacher);
    if (denial != null) return BackendFailure(denial);
    if (fake.mode == FakeMode.offlineWithoutCache) {
      return const BackendFailure(OfflineNoCacheError());
    }
    return BackendOk(fake._teacherClasses());
  }
}

class _FakeLibrary implements LibraryRepository {
  _FakeLibrary(this.fake);

  final FakeBackend fake;

  @override
  Future<BackendResult<StudentLibrary>> library() async {
    if (fake.libraryError != null) {
      return BackendFailure(fake.libraryError!);
    }
    final denial = fake._roleFailure(UserRole.student);
    if (denial != null) return BackendFailure(denial);
    if (fake.mode == FakeMode.offlineWithoutCache) {
      return const BackendFailure(OfflineNoCacheError());
    }
    return BackendOk(fake._studentLibrary());
  }
}

class _FakeParent implements ParentRepository {
  _FakeParent(this.fake);

  final FakeBackend fake;

  @override
  Future<BackendResult<ParentHomeData>> home() async {
    if (fake.parentError != null) {
      return BackendFailure(fake.parentError!);
    }
    final denial = fake._roleFailure(UserRole.parent);
    if (denial != null) return BackendFailure(denial);
    if (fake.mode == FakeMode.offlineWithoutCache) {
      return const BackendFailure(OfflineNoCacheError());
    }
    return BackendOk(fake._parentHome());
  }
}

class _FakeDiagnostics implements DiagnosticsRepository {
  _FakeDiagnostics(this.fake);

  final FakeBackend fake;

  static const total = 3;

  @override
  Stream<PingMessage> pingStream() async* {
    if (fake.pingError != null) {
      throw BackendException(fake.pingError!);
    }
    if (fake.mode != FakeMode.online) {
      throw const BackendException(BackendUnreachableError());
    }
    final session = fake._sessionForCall();
    if (session == null || !session.isReady) {
      throw const BackendException(PermissionDeniedError());
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
