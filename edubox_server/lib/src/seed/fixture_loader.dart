import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

import '../generated/protocol.dart';

/// Database ids of a loaded fixture set, by fixture key.
class SeededFixtures {
  SeededFixtures({
    required this.fixtures,
    required this.authUserIds,
    required this.userIds,
    required this.classIds,
    required this.contentIds,
  });

  final FixtureSet fixtures;

  /// Auth user id per account key (every account has one).
  final Map<String, UuidValue> authUserIds;

  /// `users.id` per account key (accounts with a profile only).
  final Map<String, int> userIds;
  final Map<String, int> classIds;
  final Map<String, int> contentIds;
}

/// Writes a [FixtureSet] into the database. Used by the seed command and by
/// every server integration test, so tests and demo data never diverge.
///
/// It only inserts; resetting tables is the seed command's job.
class FixtureLoader {
  const FixtureLoader();

  /// Loads [fixtures]. Email/password identities are created for the account
  /// keys in [credentialsFor] (all accounts when null). Password hashing is
  /// slow, so tests that never sign in pass an empty set.
  Future<SeededFixtures> load(
    Session session,
    FixtureSet fixtures, {
    Set<String>? credentialsFor,
  }) async {
    final authUserIds = <String, UuidValue>{};
    final userIds = <String, int>{};
    final auth = AuthServices.instance;

    for (final account in fixtures.accounts) {
      final authUser = await auth.authUsers.create(
        session,
        blocked: account.blocked,
      );
      authUserIds[account.key] = authUser.id;
      if (credentialsFor == null || credentialsFor.contains(account.key)) {
        await auth.emailIdp.admin.createEmailAuthentication(
          session,
          authUserId: authUser.id,
          email: account.email,
          password: devPassword,
        );
      }
      if (!account.hasProfile) continue;
      final user = await EduboxUser.db.insertRow(
        session,
        EduboxUser(
          authUserId: authUser.id,
          role: account.role,
          name: account.name,
          email: account.email,
        ),
      );
      userIds[account.key] = user.id!;
    }

    for (final account in fixtures.accounts) {
      final linkedKey = account.linkedStudentKey;
      if (linkedKey == null) continue;
      final parentId = userIds[account.key]!;
      final parent = await EduboxUser.db.findById(session, parentId);
      await EduboxUser.db.updateRow(
        session,
        parent!.copyWith(
          linkedStudentId: userIds[linkedKey],
          linkedStudentName: fixtures.account(linkedKey).name,
        ),
      );
    }

    final classIds = <String, int>{};
    for (final fixture in fixtures.classes) {
      classIds[fixture.key] = await insertClass(session, fixture, userIds);
    }

    final contentIds = <String, int>{};
    for (final fixture in fixtures.content) {
      contentIds[fixture.key] = await insertContent(
        session,
        fixture,
        userIds: userIds,
        classIds: classIds,
      );
    }

    return SeededFixtures(
      fixtures: fixtures,
      authUserIds: authUserIds,
      userIds: userIds,
      classIds: classIds,
      contentIds: contentIds,
    );
  }

  /// Inserts one class with its subjects and members; returns its id.
  Future<int> insertClass(
    Session session,
    ClassFixture fixture,
    Map<String, int> userIds,
  ) async {
    final row = await SchoolClass.db.insertRow(
      session,
      SchoolClass(
        teacherId: userIds[fixture.teacherKey]!,
        name: fixture.name,
        gradeLevel: fixture.gradeLevel,
      ),
    );
    final classId = row.id!;
    await ClassSubject.db.insert(session, [
      for (final (index, subject) in fixture.subjects.indexed)
        ClassSubject(classId: classId, position: index, subject: subject),
    ]);
    await ClassMember.db.insert(session, [
      for (final studentKey in fixture.studentKeys)
        ClassMember(classId: classId, studentId: userIds[studentKey]!),
    ]);
    return classId;
  }

  /// Inserts one content row with its class scope; returns its id.
  Future<int> insertContent(
    Session session,
    ContentFixture fixture, {
    required Map<String, int> userIds,
    required Map<String, int> classIds,
  }) async {
    final ownerId = userIds[fixture.ownerKey]!;
    final approved = fixture.status == FixtureContentStatus.approved;
    final row = await ContentRecord.db.insertRow(
      session,
      ContentRecord(
        ownerTeacherId: ownerId,
        type: ContentType.values.byName(fixture.type.name),
        subject: fixture.subject,
        gradeLevel: fixture.gradeLevel,
        title: fixture.title,
        status: ContentStatus.values.byName(fixture.status.name),
        approvedBy: approved ? ownerId : null,
        createdAt: fixture.createdAt,
      ),
    );
    await ContentClass.db.insert(session, [
      for (final classKey in fixture.classKeys)
        ContentClass(contentId: row.id!, classId: classIds[classKey]!),
    ]);
    return row.id!;
  }
}
