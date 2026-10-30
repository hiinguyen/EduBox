import 'package:edubox_client/edubox_client.dart';
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/data/edubox_api.dart';
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    show
        AuthUserBlockedException,
        EmailAccountLoginException,
        EmailAccountLoginExceptionReason;

/// A host-side stand-in for the Serverpod server: it answers from the phase 1
/// fixtures and throws the same exception types the generated client throws,
/// so `CachedBackend` and `mapApiError` are tested end to end without a
/// server or the secure-storage plugin.
class FixtureEduBoxApi implements EduBoxApi {
  FixtureEduBoxApi({this.unreachable = false});

  /// True models a closed port: every call throws a network exception.
  bool unreachable;

  FixtureSet fixtures = FixtureSet.phase1();
  final Map<String, String?> _roleOverrides = {};
  final Map<String, int> _failedLogins = {};
  String? _storedAccountKey;

  /// Number of server calls made (offline paths must not add to it).
  int calls = 0;

  void setRole(String accountKey, String? role) =>
      _roleOverrides[accountKey] = role;

  void _dial() {
    calls++;
    if (unreachable) {
      throw const ServerpodClientNetworkException('connection refused');
    }
  }

  AccountFixture _caller() {
    final key = _storedAccountKey;
    if (key == null) throw ServerpodClientUnauthorized();
    return fixtures.account(key);
  }

  @override
  Future<void> login({required String email, required String password}) async {
    _dial();
    final normalized = email.trim().toLowerCase();
    if ((_failedLogins[normalized] ?? 0) >= 5) {
      throw EmailAccountLoginException(
        reason: EmailAccountLoginExceptionReason.tooManyAttempts,
      );
    }
    final account = fixtures.accountByEmail(normalized);
    if (account == null || password != devPassword) {
      _failedLogins[normalized] = (_failedLogins[normalized] ?? 0) + 1;
      throw EmailAccountLoginException(
        reason: EmailAccountLoginExceptionReason.invalidCredentials,
      );
    }
    if (account.blocked) throw AuthUserBlockedException();
    _failedLogins.remove(normalized);
    _storedAccountKey = account.key;
  }

  @override
  Future<bool> restoreStoredAuth() async => _storedAccountKey != null;

  @override
  Future<ProfileResult> profileMe() async {
    _dial();
    return _profileOf(_caller());
  }

  @override
  Future<List<ClassSummary>> classesMine() async {
    _dial();
    final caller = _requireRole(UserRole.teacher);
    return [
      for (final (index, item) in fixtures.classesOfTeacher(caller.key).indexed)
        ClassSummary(
          id: index + 1,
          name: item.name,
          gradeLevel: item.gradeLevel,
          subjects: List.of(item.subjects),
          studentCount: item.studentKeys.length,
        ),
    ];
  }

  @override
  Future<StudentLibrary> contentLibrary() async {
    _dial();
    final caller = _requireRole(UserRole.student);
    return StudentLibrary(
      classes: [
        for (final (index, item)
            in fixtures.classesOfStudent(caller.key).indexed)
          StudentClass(
            id: index + 1,
            name: item.name,
            gradeLevel: item.gradeLevel,
            subjects: List.of(item.subjects),
          ),
      ],
      items: [
        for (final (index, item)
            in fixtures.libraryOfStudent(caller.key).indexed)
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

  @override
  Stream<PingMessage> pingStream() async* {
    calls++;
    if (unreachable) {
      // The real streaming client throws transport MethodStreamExceptions,
      // not the unary ServerpodClientNetworkException.
      throw const WebSocketConnectException('connection refused');
    }
    final key = _storedAccountKey;
    if (key == null) {
      // With requireLogin the server answers authenticationFailed before the
      // endpoint guard, so the stream never reaches AccessDenied(unauthenticated).
      throw OpenMethodStreamException(
        OpenMethodStreamResponseType.authenticationFailed,
      );
    }
    final profile = _profileOf(fixtures.account(key));
    if (profile.status != ProfileStatus.ready) {
      throw AccessDeniedException(reason: AccessDeniedReason.notSetUp);
    }
    for (var sequence = 1; sequence <= 3; sequence++) {
      yield PingMessage(
        sequence: sequence,
        total: 3,
        role: profile.profile!.role,
        sentAt: DateTime.now().toUtc(),
      );
    }
  }

  @override
  Future<void> signOut() async {
    _dial();
    _storedAccountKey = null;
  }

  @override
  Future<void> clearStoredAuth() async => _storedAccountKey = null;

  @override
  Future<void> close() async {}

  AccountFixture _requireRole(UserRole role) {
    final caller = _caller();
    final profile = _profileOf(caller);
    if (profile.status != ProfileStatus.ready) {
      throw AccessDeniedException(reason: AccessDeniedReason.notSetUp);
    }
    if (profile.profile!.role != role) {
      throw AccessDeniedException(reason: AccessDeniedReason.wrongRole);
    }
    return caller;
  }

  ProfileResult _profileOf(AccountFixture account) {
    final raw = _roleOverrides.containsKey(account.key)
        ? _roleOverrides[account.key]
        : account.role;
    final role = raw == null ? null : UserRole.values.asNameMap()[raw];
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
        userId: fixtures.accounts.indexOf(account) + 1,
        role: role,
        name: account.name,
        email: account.email,
        linkedStudentName: linkedKey == null
            ? null
            : fixtures.account(linkedKey).name,
      ),
    );
  }
}
