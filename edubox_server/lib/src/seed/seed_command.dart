import 'package:serverpod/serverpod.dart';

import '../storage/object_store.dart';

/// The steps of the seed command.
///
/// CLI: `docker compose run --rm seed [--step <cliName>]` (default `reset`),
/// which runs `bin/seed --mode development --step <cliName>` against the
/// development database and the e2e bucket. Exit code 0 on success, 1 on any
/// failure, 64 on a usage error.
enum SeedStep {
  /// Truncates [seedResetTables], empties the e2e bucket, then loads
  /// `FixtureSet.phase1()` through `FixtureLoader` with credentials for every
  /// account. Every e2e run starts with this.
  reset('reset'),

  /// Exit criterion 7: inserts `reconnectDeltaContent` (a new approved item
  /// for class 7A) on top of a reset database.
  reconnectLibrary('reconnect-library'),

  /// Exit criterion 7: inserts `reconnectDeltaClass` (class 8B for teacher
  /// Lan) on top of a reset database.
  reconnectClasses('reconnect-classes'),

  /// Account-not-set-up check-again coverage: sets the null-role fixture's
  /// role to `student`.
  assignRole('assign-role');

  const SeedStep(this.cliName);

  /// The `--step` value.
  final String cliName;

  /// Parses a `--step` value; returns null for an unknown value.
  static SeedStep? tryParse(String value) {
    for (final step in values) {
      if (step.cliName == value) return step;
    }
    return null;
  }
}

/// Every table the `reset` step truncates (`TRUNCATE ... RESTART IDENTITY
/// CASCADE`): all EduBox data tables plus the Serverpod auth tables. The
/// schema and the migration bookkeeping tables are never touched.
///
/// A server test fails when a table of the latest migration that is not a
/// Serverpod system table is missing from this list, so a new phase that
/// adds a table must add it here.
const List<String> seedResetTables = [
  // EduBox data.
  'content_classes',
  'content',
  'class_members',
  'class_subjects',
  'classes',
  'users',
  // Serverpod auth (serverpod_auth_core and serverpod_auth_idp).
  'serverpod_auth_core_jwt_refresh_token',
  'serverpod_auth_core_profile',
  'serverpod_auth_core_profile_image',
  'serverpod_auth_core_session',
  'serverpod_auth_core_user',
  'serverpod_auth_idp_anonymous_account',
  'serverpod_auth_idp_apple_account',
  'serverpod_auth_idp_email_account',
  'serverpod_auth_idp_email_account_password_reset_request',
  'serverpod_auth_idp_email_account_request',
  'serverpod_auth_idp_facebook_account',
  'serverpod_auth_idp_firebase_account',
  'serverpod_auth_idp_github_account',
  'serverpod_auth_idp_google_account',
  'serverpod_auth_idp_microsoft_account',
  'serverpod_auth_idp_passkey_account',
  'serverpod_auth_idp_passkey_challenge',
  'serverpod_auth_idp_rate_limited_request_attempt',
  'serverpod_auth_idp_secret_challenge',
];

/// Runs one seed step.
///
/// BACKEND TRACK: implement. `reset` truncates [seedResetTables] in one
/// statement, calls `store.deletePrefix(session, '')` on the e2e bucket's
/// store, then `FixtureLoader().load(session, FixtureSet.phase1())`; the
/// delta steps look fixtures up by key through the loaded ids (query by
/// email and class name). The acceptance tests are the `backend-pending`
/// cases in `test/integration/seed/`; see
/// docs/build/phase-1/contract.md section 2.5.
Future<void> runSeedStep(
  Session session,
  SeedStep step, {
  required ObjectStore e2eStore,
}) => throw UnimplementedError('BACKEND TRACK: runSeedStep(${step.cliName})');
