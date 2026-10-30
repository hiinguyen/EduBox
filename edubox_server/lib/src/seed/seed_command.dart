import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../storage/object_store.dart';
import 'fixture_loader.dart';

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
/// `reset` empties every table in [seedResetTables] in one statement, empties
/// the e2e bucket through `e2eStore.deletePrefix(session, '')`, then loads
/// `FixtureSet.phase1()` with credentials for every account. The delta steps
/// expect a reset database, look fixtures up by email and class name, and are
/// idempotent: running one twice changes nothing the second time. See
/// docs/build/phase-1/contract.md sections 2.5-2.6.
Future<void> runSeedStep(
  Session session,
  SeedStep step, {
  required ObjectStore e2eStore,
}) async {
  switch (step) {
    case SeedStep.reset:
      await _reset(session, e2eStore);
    case SeedStep.reconnectLibrary:
      await _insertReconnectContent(session);
    case SeedStep.reconnectClasses:
      await _insertReconnectClass(session);
    case SeedStep.assignRole:
      await _assignNullRoleFixture(session);
  }
}

Future<void> _reset(Session session, ObjectStore e2eStore) async {
  final tables = seedResetTables.map((table) => '"$table"').join(', ');
  await session.db.unsafeExecute(
    'TRUNCATE TABLE $tables RESTART IDENTITY CASCADE',
  );
  await e2eStore.deletePrefix(session, '');
  await const FixtureLoader().load(session, FixtureSet.phase1());
}

Future<void> _insertReconnectContent(Session session) async {
  final existing = await ContentRecord.db.findFirstRow(
    session,
    where: (table) => table.title.equals(reconnectDeltaContent.title),
  );
  if (existing != null) return;
  await const FixtureLoader().insertContent(
    session,
    reconnectDeltaContent,
    userIds: await _userIdsByKey(session),
    classIds: await _classIdsByKey(session),
  );
}

Future<void> _insertReconnectClass(Session session) async {
  final existing = await SchoolClass.db.findFirstRow(
    session,
    where: (table) => table.name.equals(reconnectDeltaClass.name),
  );
  if (existing != null) return;
  await const FixtureLoader().insertClass(
    session,
    reconnectDeltaClass,
    await _userIdsByKey(session),
  );
}

Future<void> _assignNullRoleFixture(Session session) async {
  final email = FixtureSet.phase1().account(FixtureKeys.nullRole).email;
  final user = await EduboxUser.db.findFirstRow(
    session,
    where: (table) => table.email.equals(email),
  );
  if (user == null) {
    throw StateError(
      'Fixture ${FixtureKeys.nullRole} has no users row; run the reset step '
      'first.',
    );
  }
  await EduboxUser.db.updateRow(session, user.copyWith(role: 'student'));
}

/// `users.id` per fixture account key, for every seeded account that has a
/// profile. Throws when a profile fixture is missing (no reset yet).
Future<Map<String, int>> _userIdsByKey(Session session) async {
  final idByEmail = {
    for (final user in await EduboxUser.db.find(session)) user.email: user.id!,
  };
  return {
    for (final account in FixtureSet.phase1().accounts)
      if (account.hasProfile) account.key: _require(idByEmail, account.email),
  };
}

/// `classes.id` per fixture class key for the phase 1 classes.
Future<Map<String, int>> _classIdsByKey(Session session) async {
  final idByName = {
    for (final row in await SchoolClass.db.find(session)) row.name: row.id!,
  };
  return {
    for (final fixture in FixtureSet.phase1().classes)
      fixture.key: _require(idByName, fixture.name),
  };
}

int _require(Map<String, int> ids, String name) {
  final id = ids[name];
  if (id == null) {
    throw StateError(
      'Fixture "$name" is not seeded; run the reset step first.',
    );
  }
  return id;
}
