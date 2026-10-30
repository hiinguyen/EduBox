// CONTRACT (phase 1): the authorization matrix.
//
// Every method the server dispatches must appear in exactly one of the four
// lists below; `authorization_matrix_test.dart` fails otherwise. When a phase
// adds an endpoint method, it adds the method's row here in the same change.

import 'package:edubox_fixtures/edubox_fixtures.dart';

import '../test_tools/serverpod_test_tools.dart';

/// The kinds of caller every EduBox endpoint method is tested with.
enum MatrixCaller {
  student(FixtureKeys.studentAn),
  teacher(FixtureKeys.teacherLan),
  parent(FixtureKeys.parentBinh),

  /// An auth user with no `users` row.
  noProfile(FixtureKeys.noProfile),

  /// A `users` row whose role is null.
  nullRole(FixtureKeys.nullRole),

  /// No session at all.
  anonymous(null);

  const MatrixCaller(this.fixtureKey);

  /// The fixture account this caller signs in as (null for [anonymous]).
  final String? fixtureKey;
}

/// One EduBox endpoint method: who may call it, and how to call it.
class MethodRule {
  const MethodRule({
    required this.allowed,
    required this.invoke,
    this.isStream = false,
  });

  /// Callers that must succeed. Every other caller must be denied:
  /// [MatrixCaller.anonymous] by Serverpod (requireLogin), the not-set-up
  /// callers with `AccessDeniedReason.notSetUp`, and the remaining roles
  /// with `AccessDeniedReason.wrongRole`.
  final Set<MatrixCaller> allowed;

  /// Calls the method and waits for its full result (a stream is drained).
  final Future<Object?> Function(
    TestEndpoints endpoints,
    TestSessionBuilder sessionBuilder,
  )
  invoke;

  final bool isStream;
}

/// EduBox endpoint methods (key: `<endpoint>.<method>`).
final Map<String, MethodRule> eduboxMethodMatrix = {
  'profile.me': MethodRule(
    // Not-set-up callers are allowed: they receive `notSetUp`, never an error.
    allowed: {
      MatrixCaller.student,
      MatrixCaller.teacher,
      MatrixCaller.parent,
      MatrixCaller.noProfile,
      MatrixCaller.nullRole,
    },
    invoke: (e, sb) => e.profile.me(sb),
  ),
  'classes.mine': MethodRule(
    allowed: {MatrixCaller.teacher},
    invoke: (e, sb) => e.classes.mine(sb),
  ),
  'content.library': MethodRule(
    allowed: {MatrixCaller.student},
    invoke: (e, sb) => e.content.library(sb),
  ),
  'diagnostics.pingStream': MethodRule(
    allowed: {MatrixCaller.student, MatrixCaller.teacher, MatrixCaller.parent},
    invoke: (e, sb) => e.diagnostics.pingStream(sb).toList(),
    isStream: true,
  ),
};

/// Test-only HTTP/endpoint surface that is not role-gated but is guarded by
/// the e2e control token and exists only in the `development` (compose e2e)
/// and `test` run modes when `edubox.e2eControl` is true. `production`,
/// `staging` and every other mode reject it. `test/integration/e2e/`
/// `e2e_control_test.dart` proves the allowed and denied states.
const Map<String, String> tokenGuardedE2eMethods = {
  'e2e.run':
      'Allowed only in the development/test run modes with '
      'edubox.e2eControl/EDUBOX_E2E_CONTROL=true; every call requires the '
      'e2eControlToken password. Production and staging always deny.',
};

/// Auth-module methods a caller may use without a session, each with the
/// reason it is safe. Each has a test in `module_endpoints_test.dart`.
const Map<String, String> moduleUnauthenticatedExceptions = {
  'emailIdp.login':
      'Sign-in. Wrong credentials, rate limit, and blocked users are tested.',
  'jwtRefresh.refreshAccessToken':
      'Session refresh. Needs a valid refresh token; none is denied.',
  'serverpod_auth_core.status.isSignedIn':
      'Returns false without a session; reads and writes nothing.',
  'serverpod_auth_core.status.signOutDevice':
      'No-op without a session (the client session manager calls it).',
  'serverpod_auth_core.status.signOutAllDevices': 'No-op without a session.',
};

/// Serverpod core raw routes (not in the generated client) that are
/// reachable without a session, each with the reason it is safe. Tested over
/// real HTTP in `module_endpoints_test.dart`.
const Map<String, String> frameworkUnauthenticatedExceptions = {
  'serverpod_cloud_storage.file':
      'Serves the database-backed "public" storage only; EduBox never writes '
      'to it (EduBox files live in the private MinIO bucket).',
  'serverpod_cloud_storage.temporaryFile':
      'Needs a server-issued download key; EduBox issues none.',
  'serverpod_cloud_storage.upload':
      'Needs a server-issued upload key; EduBox issues none.',
};

/// Auth-module methods that must deny an unauthenticated caller.
const Set<String> moduleDeniedUnauthenticated = {
  'serverpod_auth_core.userProfileInfo.get',
};
