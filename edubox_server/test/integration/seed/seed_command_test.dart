import 'dart:io';
import 'dart:typed_data';

import 'package:edubox_server/src/generated/protocol.dart';
import 'package:edubox_server/src/seed/seed_command.dart';
import 'package:edubox_server/src/storage/object_store.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../../bin/seed.dart';
import '../support/harness.dart';
import '../test_tools/serverpod_test_tools.dart';

/// The acceptance tests for the seed contract in
/// docs/build/phase-1/contract.md sections 2.5-2.6.
///
/// Each test resets the ephemeral test database, so committed rows from one
/// test cannot leak into the next.
void main() {
  withServerpod(
    'seed reset',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      setUpAll(initTestAuthServices);

      late Session session;
      late _RecordingStore store;

      setUp(() async {
        session = sessionBuilder.build();
        store = _RecordingStore();
        await runSeedStep(session, SeedStep.reset, e2eStore: store);
      });

      test('writes every fixture account with its exact identity, role, link '
          'and credentials', () async {
        for (final account in FixtureSet.phase1().accounts) {
          final email = await EmailAccount.db.findFirstRow(
            session,
            where: (table) => table.email.equals(account.email),
          );
          expect(email, isNotNull, reason: account.key);
          final authUser = await AuthUser.db.findById(
            session,
            email!.authUserId,
          );
          expect(authUser, isNotNull, reason: account.key);
          expect(authUser!.blocked, account.blocked, reason: account.key);

          final user = await EduboxUser.db.findFirstRow(
            session,
            where: (table) => table.email.equals(account.email),
          );
          if (!account.hasProfile) {
            expect(user, isNull, reason: account.key);
            continue;
          }
          expect(user, isNotNull, reason: account.key);
          expect(user!.authUserId, authUser.id, reason: account.key);
          expect(user.role, account.role, reason: account.key);
          expect(user.name, account.name, reason: account.key);
          expect(user.email, account.email, reason: account.key);
          final linkedKey = account.linkedStudentKey;
          if (linkedKey == null) {
            expect(user.linkedStudentId, isNull, reason: account.key);
            expect(user.linkedStudentName, isNull, reason: account.key);
          } else {
            expect(
              user.linkedStudentId,
              (await _userByEmail(
                session,
                FixtureSet.phase1()
                    .account(
                      linkedKey,
                    )
                    .email,
              ))!.id,
              reason: account.key,
            );
            expect(
              user.linkedStudentName,
              FixtureSet.phase1().account(linkedKey).name,
              reason: account.key,
            );
          }
        }
      });

      test('seeded credentials sign in for every role', () async {
        for (final key in [
          FixtureKeys.studentAn,
          FixtureKeys.teacherLan,
          FixtureKeys.parentBinh,
        ]) {
          final account = FixtureSet.phase1().account(key);
          final result = await endpoints.emailIdp.login(
            anonymous(sessionBuilder),
            email: account.email,
            password: devPassword,
          );
          expect(result.authUserId, isNotNull, reason: key);
        }
      });

      test('writes every class with exact teacher, grade, ordered subjects and '
          'membership', () async {
        for (final fixture in FixtureSet.phase1().classes) {
          final row = await SchoolClass.db.findFirstRow(
            session,
            where: (table) => table.name.equals(fixture.name),
          );
          expect(row, isNotNull, reason: fixture.key);
          expect(
            row!.teacherId,
            (await _userByEmail(
              session,
              FixtureSet.phase1().account(fixture.teacherKey).email,
            ))!.id,
            reason: fixture.key,
          );
          expect(row.gradeLevel, fixture.gradeLevel, reason: fixture.key);

          final subjectRows = await ClassSubject.db.find(
            session,
            where: (table) => table.classId.equals(row.id!),
            orderBy: (table) => table.position,
          );
          final subjects = subjectRows
              .map((subject) => subject.subject)
              .toList();
          expect(subjects, fixture.subjects, reason: fixture.key);

          final members = await ClassMember.db.find(
            session,
            where: (table) => table.classId.equals(row.id!),
          );
          final memberIds = members.map((member) => member.studentId).toSet();
          final expectedIds = <int>{
            for (final studentKey in fixture.studentKeys)
              (await _userByEmail(
                session,
                FixtureSet.phase1().account(studentKey).email,
              ))!.id!,
          };
          expect(memberIds, expectedIds, reason: fixture.key);
        }
      });

      test('writes every content fixture with exact owner, status, metadata '
          'and class scope', () async {
        for (final fixture in FixtureSet.phase1().content) {
          final row = await ContentRecord.db.findFirstRow(
            session,
            where: (table) => table.title.equals(fixture.title),
          );
          expect(row, isNotNull, reason: fixture.key);
          expect(
            row!.ownerTeacherId,
            (await _userByEmail(
              session,
              FixtureSet.phase1().account(fixture.ownerKey).email,
            ))!.id,
            reason: fixture.key,
          );
          expect(row.type.name, fixture.type.name, reason: fixture.key);
          expect(row.subject, fixture.subject, reason: fixture.key);
          expect(row.gradeLevel, fixture.gradeLevel, reason: fixture.key);
          expect(row.status.name, fixture.status.name, reason: fixture.key);
          expect(
            row.approvedBy,
            fixture.status == FixtureContentStatus.approved
                ? row.ownerTeacherId
                : isNull,
            reason: fixture.key,
          );

          final scope = await ContentClass.db.find(
            session,
            where: (table) => table.contentId.equals(row.id!),
          );
          final classIds = scope.map((item) => item.classId).toSet();
          final expectedClassIds = <int>{
            for (final classKey in fixture.classKeys)
              (await SchoolClass.db.findFirstRow(
                session,
                where: (table) => table.name.equals(
                  FixtureSet.phase1().classByKey(classKey).name,
                ),
              ))!.id!,
          };
          expect(classIds, expectedClassIds, reason: fixture.key);
        }

        final library = FixtureSet.phase1().libraryOfStudent(
          FixtureKeys.studentAn,
        );
        expect(
          library.map((item) => item.title),
          isNot(contains('Bản nháp: Hình học chương 2')),
        );
        expect(
          library.map((item) => item.title),
          isNot(contains('Chuyển động cơ học')),
        );
      });

      test('a reset removes rows created after seeding and restores the '
          'fixture state', () async {
        final fixtures = FixtureSet.phase1();
        final countsBefore = await _fixtureCounts(session);
        final authUsersBefore = await AuthUser.db.count(session);
        final emailAccountsBefore = await EmailAccount.db.count(session);

        await runSeedStep(
          session,
          SeedStep.reconnectLibrary,
          e2eStore: store,
        );
        await runSeedStep(
          session,
          SeedStep.reconnectClasses,
          e2eStore: store,
        );
        await runSeedStep(session, SeedStep.assignRole, e2eStore: store);
        expect(
          await ContentRecord.db.findFirstRow(
            session,
            where: (table) => table.title.equals(reconnectDeltaContent.title),
          ),
          isNotNull,
        );
        expect(
          await SchoolClass.db.findFirstRow(
            session,
            where: (table) => table.name.equals(reconnectDeltaClass.name),
          ),
          isNotNull,
        );
        expect(
          (await _userByEmail(
            session,
            fixtures.account(FixtureKeys.nullRole).email,
          ))!.role,
          'student',
        );

        final strayAuthUser = await AuthUser.db.insertRow(
          session,
          AuthUser(scopeNames: const <String>{}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: strayAuthUser.id!,
            email: 'stray.reset@edubox.test',
            passwordHash: 'test-only-not-a-real-hash',
          ),
        );
        expect(await AuthUser.db.count(session), authUsersBefore + 1);
        expect(await EmailAccount.db.count(session), emailAccountsBefore + 1);

        store.deletedPrefixes.clear();
        await runSeedStep(session, SeedStep.reset, e2eStore: store);

        expect(await _fixtureCounts(session), countsBefore);
        expect(await AuthUser.db.count(session), authUsersBefore);
        expect(await EmailAccount.db.count(session), emailAccountsBefore);
        expect(store.deletedPrefixes, contains(''));
        expect(
          await ContentRecord.db.findFirstRow(
            session,
            where: (table) => table.title.equals(reconnectDeltaContent.title),
          ),
          isNull,
        );
        expect(
          await SchoolClass.db.findFirstRow(
            session,
            where: (table) => table.name.equals(reconnectDeltaClass.name),
          ),
          isNull,
        );
        expect(
          (await _userByEmail(
            session,
            fixtures.account(FixtureKeys.nullRole).email,
          ))!.role,
          isNull,
        );
      });

      test('runSeedCli resets this test database and exits 0', () async {
        final database =
            (await session.db.unsafeQuery(
                  'SELECT current_database() AS name',
                )).first[0]!
                as String;

        final s3 = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => s3.close(force: true));
        final endpoint = Uri.parse('http://${s3.address.host}:${s3.port}');
        s3.listen((request) async {
          request.response
            ..headers.set(HttpHeaders.contentTypeHeader, 'application/xml')
            ..write(
              '<?xml version="1.0" encoding="UTF-8"?>'
              '<ListBucketResult '
              'xmlns="http://s3.amazonaws.com/doc/2006-03-01/">'
              '<Name>edubox-test</Name><Prefix></Prefix>'
              '<KeyCount>0</KeyCount><MaxKeys>1000</MaxKeys>'
              '<IsTruncated>false</IsTruncated>'
              '</ListBucketResult>',
            );
          await request.response.close();
        });

        final exitCode = await runSeedCli(
          const SeedArgs(runMode: 'test', step: SeedStep.reset),
          environment: {
            'EDUBOX_STORAGE_ENDPOINT': endpoint.toString(),
            'EDUBOX_STORAGE_PUBLIC_ENDPOINT': endpoint.toString(),
          },
          configOverride: (config) => _withDatabase(config, database),
        );
        expect(exitCode, 0);
        expect(await EduboxUser.db.count(session), 14);
        expect(await SchoolClass.db.count(session), 5);
        expect(await ContentRecord.db.count(session), 9);
        expect(await EmailAccount.db.count(session), 15);
      });
    },
  );

  withServerpod(
    'seed reconnect and role steps',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      setUpAll(initTestAuthServices);

      late Session session;
      late _RecordingStore store;

      setUp(() async {
        session = sessionBuilder.build();
        store = _RecordingStore();
        await runSeedStep(session, SeedStep.reset, e2eStore: store);
      });

      test('reconnect-library adds the approved 7A item only', () async {
        final before = FixtureSet.phase1().libraryOfStudent(
          FixtureKeys.studentAn,
        );
        await runSeedStep(
          session,
          SeedStep.reconnectLibrary,
          e2eStore: store,
        );
        final row = await ContentRecord.db.findFirstRow(
          session,
          where: (table) => table.title.equals(reconnectDeltaContent.title),
        );
        expect(row, isNotNull);
        expect(row!.status, ContentStatus.approved);
        expect(row.subject, reconnectDeltaContent.subject);
        expect(row.gradeLevel, reconnectDeltaContent.gradeLevel);
        expect(
          (await ContentClass.db.find(
            session,
            where: (table) => table.contentId.equals(row.id!),
          )).single.classId,
          (await SchoolClass.db.findFirstRow(
            session,
            where: (table) => table.name.equals('7A'),
          ))!.id,
        );
        expect(
          FixtureSet.phase1()
              .withReconnectDeltas()
              .libraryOfStudent(FixtureKeys.studentAn)
              .length,
          before.length + 1,
        );
      });

      test('reconnect-classes adds class 8B for teacher Lan', () async {
        await runSeedStep(
          session,
          SeedStep.reconnectClasses,
          e2eStore: store,
        );
        final row = await SchoolClass.db.findFirstRow(
          session,
          where: (table) => table.name.equals(reconnectDeltaClass.name),
        );
        expect(row, isNotNull);
        expect(row!.gradeLevel, reconnectDeltaClass.gradeLevel);
        expect(
          row.teacherId,
          (await _userByEmail(
            session,
            FixtureSet.phase1().account(FixtureKeys.teacherLan).email,
          ))!.id,
        );
        expect(
          (await ClassSubject.db.find(
            session,
            where: (table) => table.classId.equals(row.id!),
          )).map((subject) => subject.subject),
          reconnectDeltaClass.subjects,
        );
      });

      test('the delta steps are idempotent', () async {
        for (var run = 0; run < 2; run++) {
          await runSeedStep(
            session,
            SeedStep.reconnectLibrary,
            e2eStore: store,
          );
          await runSeedStep(
            session,
            SeedStep.reconnectClasses,
            e2eStore: store,
          );
          await runSeedStep(session, SeedStep.assignRole, e2eStore: store);
        }
        expect(
          await ContentRecord.db.count(
            session,
            where: (table) => table.title.equals(reconnectDeltaContent.title),
          ),
          1,
        );
        expect(
          await SchoolClass.db.count(
            session,
            where: (table) => table.name.equals(reconnectDeltaClass.name),
          ),
          1,
        );
        expect(
          await ContentRecord.db.count(session),
          FixtureSet.phase1().content.length + 1,
        );
        expect(
          await SchoolClass.db.count(session),
          FixtureSet.phase1().classes.length + 1,
        );
      });

      test(
        'assign-role makes the null-role fixture ready on the next call',
        () async {
          final before = await EduboxUser.db.findFirstRow(
            session,
            where: (table) => table.email.equals(
              FixtureSet.phase1().account(FixtureKeys.nullRole).email,
            ),
          );
          expect(before!.role, isNull);

          await runSeedStep(session, SeedStep.assignRole, e2eStore: store);

          final after = await EduboxUser.db.findById(session, before.id!);
          expect(after!.role, 'student');
          final me = await endpoints.profile.me(
            sessionBuilder.copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                before.authUserId.uuid,
                {},
              ),
            ),
          );
          expect(me.status, ProfileStatus.ready);
          expect(me.profile!.role, UserRole.student);
        },
      );
    },
  );

  withServerpod(
    'seed delta steps before reset',
    (sessionBuilder, endpoints) {
      test('a delta step before reset throws StateError', () async {
        final session = sessionBuilder.build();
        final store = _RecordingStore();
        for (final step in [
          SeedStep.reconnectLibrary,
          SeedStep.reconnectClasses,
          SeedStep.assignRole,
        ]) {
          await expectLater(
            runSeedStep(session, step, e2eStore: store),
            throwsA(isA<StateError>()),
            reason: step.cliName,
          );
        }
      });
    },
  );
}

Future<EduboxUser?> _userByEmail(Session session, String email) =>
    EduboxUser.db.findFirstRow(
      session,
      where: (table) => table.email.equals(email),
    );

Future<List<int>> _fixtureCounts(Session session) async => [
  await EduboxUser.db.count(session),
  await SchoolClass.db.count(session),
  await ClassSubject.db.count(session),
  await ClassMember.db.count(session),
  await ContentRecord.db.count(session),
  await ContentClass.db.count(session),
];

/// Points the CLI's own Serverpod at the group's ephemeral database, with a
/// single connection so the CLI does not exhaust the test postmaster.
ServerpodConfig _withDatabase(ServerpodConfig config, String databaseName) {
  final database = config.database;
  if (database is! PostgresDatabaseConfig) return config;
  return config.copyWith(
    // The test passwords have no serviceSecret; a valid one keeps the CLI
    // from logging the Insights-disabled warning during the test.
    serviceSecret: 'test-only-service-secret-0000000000',
    database: PostgresDatabaseConfig(
      host: database.host,
      port: database.port,
      user: database.user,
      password: database.password,
      name: databaseName,
      requireSsl: database.requireSsl,
      isUnixSocket: database.isUnixSocket,
      searchPaths: database.searchPaths,
      maxConnectionCount: 1,
      dataPath: database.dataPath,
    ),
  );
}

class _RecordingStore implements ObjectStore {
  final List<String> deletedPrefixes = [];

  @override
  Future<void> put(
    Session session,
    String path,
    ByteData bytes, {
    String? contentType,
  }) async {}

  @override
  Future<ByteData> get(Session session, String path) async =>
      ByteData.sublistView(Uint8List(0));

  @override
  Future<Uri> signedGetUrl(
    Session session,
    String path, {
    Duration expiresIn = const Duration(minutes: 5),
  }) async => Uri.parse('http://localhost:9000/unused');

  @override
  Future<void> deletePrefix(Session session, String prefix) async {
    deletedPrefixes.add(prefix);
  }
}
