import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:edubox_client/edubox_client.dart';

import '../contract/outbox.dart';
import '../contract/session.dart';

part 'local_store.g.dart';

/// Marker rows that distinguish "cached empty" from "never cached".
class CachedSnapshots extends Table {
  TextColumn get kind => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {kind};
}

/// The signed-in session and its server-resolved profile/role.
class CachedProfiles extends Table {
  TextColumn get signedInEmail => text()();
  TextColumn get status => text()();
  IntColumn get userId => integer().nullable()();
  TextColumn get role => text().nullable()();
  TextColumn get name => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get linkedStudentName => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {signedInEmail};
}

/// Teacher-home rows (`classes.mine`).
class CachedClasses extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get gradeLevel => integer()();
  TextColumn get subjectsJson => text()();
  IntColumn get studentCount => integer()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Student-library classes (`content.library.classes`).
class CachedLibraryClasses extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get gradeLevel => integer()();
  TextColumn get subjectsJson => text()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Student-library items (`content.library.items`).
class CachedLibraryItems extends Table {
  IntColumn get id => integer()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get subject => text()();
  IntColumn get gradeLevel => integer()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Parent-home phase 1 data (one row).
class CachedParentHomes extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get linkedStudentName => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The phase 1 outbox table. No phase 1 screen writes through it yet.
class OutboxEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get state => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

@DriftDatabase(
  tables: [
    CachedSnapshots,
    CachedProfiles,
    CachedClasses,
    CachedLibraryClasses,
    CachedLibraryItems,
    CachedParentHomes,
    OutboxEntries,
  ],
)
class EduBoxDatabase extends _$EduBoxDatabase {
  EduBoxDatabase(super.e);

  /// A throwaway database for tests and previews.
  factory EduBoxDatabase.inMemory() => EduBoxDatabase(NativeDatabase.memory());

  /// Opens the on-disk phase 1 store.
  factory EduBoxDatabase.open(File file) =>
      EduBoxDatabase(NativeDatabase.createInBackground(file));

  @override
  int get schemaVersion => 1;
}

/// Read/write access to the phase 1 drift cache.
///
/// The frontend track composes this with the network seam: online calls save
/// snapshots here, offline calls read them, and a missing marker is the
/// "offline without cache" state. The local store is never the source of
/// authorization; it only mirrors the last server answer.
class CachedDataStore {
  CachedDataStore(this.db);

  final EduBoxDatabase db;

  static const _sessionKind = 'session';
  static const _teacherClassesKind = 'teacherClasses';
  static const _studentLibraryKind = 'studentLibrary';
  static const _parentHomeKind = 'parentHome';

  Future<void> saveSession(AuthSession session) async {
    final profile = session.profile;
    final now = DateTime.now().toUtc();
    await db.transaction(() async {
      // One session at a time: a sign-in as another account replaces the row.
      await db.delete(db.cachedProfiles).go();
      await db
          .into(db.cachedProfiles)
          .insertOnConflictUpdate(
            CachedProfilesCompanion.insert(
              signedInEmail: session.signedInEmail,
              status: session.status.name,
              userId: Value(profile?.userId),
              role: Value(profile?.role.name),
              name: Value(profile?.name),
              email: Value(profile?.email),
              linkedStudentName: Value(profile?.linkedStudentName),
              cachedAt: now,
            ),
          );
      await _markSnapshot(_sessionKind, now);
    });
  }

  Future<AuthSession?> readSession() async {
    if (!await _hasSnapshot(_sessionKind)) return null;
    final row = await db.select(db.cachedProfiles).getSingleOrNull();
    if (row == null) return null;
    return AuthSession(
      signedInEmail: row.signedInEmail,
      profileResult: _profileResultFromRow(row),
    );
  }

  Future<void> clearSession() async {
    await db.transaction(() async {
      await db.delete(db.cachedProfiles).go();
      await _deleteSnapshot(_sessionKind);
    });
  }

  Future<void> saveTeacherClasses(List<ClassSummary> classes) async {
    final now = DateTime.now().toUtc();
    await db.transaction(() async {
      await db.delete(db.cachedClasses).go();
      await db.batch((batch) {
        batch.insertAll(db.cachedClasses, [
          for (final (position, item) in classes.indexed)
            CachedClassesCompanion.insert(
              id: Value(item.id),
              name: item.name,
              gradeLevel: item.gradeLevel,
              subjectsJson: jsonEncode(item.subjects),
              studentCount: item.studentCount,
              position: position,
            ),
        ]);
      });
      await _markSnapshot(_teacherClassesKind, now);
    });
  }

  Future<List<ClassSummary>?> readTeacherClasses() async {
    if (!await _hasSnapshot(_teacherClassesKind)) return null;
    final rows = await (db.select(
      db.cachedClasses,
    )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
    return [
      for (final row in rows)
        ClassSummary(
          id: row.id,
          name: row.name,
          gradeLevel: row.gradeLevel,
          subjects: _stringList(row.subjectsJson),
          studentCount: row.studentCount,
        ),
    ];
  }

  Future<void> saveStudentLibrary(StudentLibrary library) async {
    final now = DateTime.now().toUtc();
    await db.transaction(() async {
      await db.delete(db.cachedLibraryClasses).go();
      await db.delete(db.cachedLibraryItems).go();
      await db.batch((batch) {
        batch.insertAll(db.cachedLibraryClasses, [
          for (final (position, item) in library.classes.indexed)
            CachedLibraryClassesCompanion.insert(
              id: Value(item.id),
              name: item.name,
              gradeLevel: item.gradeLevel,
              subjectsJson: jsonEncode(item.subjects),
              position: position,
            ),
        ]);
        batch.insertAll(db.cachedLibraryItems, [
          for (final (position, item) in library.items.indexed)
            CachedLibraryItemsCompanion.insert(
              id: Value(item.id),
              type: item.type.name,
              title: item.title,
              subject: item.subject,
              gradeLevel: item.gradeLevel,
              createdAt: item.createdAt,
              position: position,
            ),
        ]);
      });
      await _markSnapshot(_studentLibraryKind, now);
    });
  }

  Future<StudentLibrary?> readStudentLibrary() async {
    if (!await _hasSnapshot(_studentLibraryKind)) return null;
    final classRows = await (db.select(
      db.cachedLibraryClasses,
    )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
    final itemRows = await (db.select(
      db.cachedLibraryItems,
    )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
    return StudentLibrary(
      classes: [
        for (final row in classRows)
          StudentClass(
            id: row.id,
            name: row.name,
            gradeLevel: row.gradeLevel,
            subjects: _stringList(row.subjectsJson),
          ),
      ],
      items: [
        for (final row in itemRows)
          LibraryItem(
            id: row.id,
            type: ContentType.values.byName(row.type),
            title: row.title,
            subject: row.subject,
            gradeLevel: row.gradeLevel,
            createdAt: row.createdAt,
          ),
      ],
    );
  }

  Future<void> saveParentHome(ParentHomeData data) async {
    final now = DateTime.now().toUtc();
    await db.transaction(() async {
      await db
          .into(db.cachedParentHomes)
          .insertOnConflictUpdate(
            CachedParentHomesCompanion.insert(
              id: const Value(0),
              linkedStudentName: Value(data.linkedStudentName),
              cachedAt: now,
            ),
          );
      await _markSnapshot(_parentHomeKind, now);
    });
  }

  Future<ParentHomeData?> readParentHome() async {
    if (!await _hasSnapshot(_parentHomeKind)) return null;
    final row = await db.select(db.cachedParentHomes).getSingleOrNull();
    if (row == null) return null;
    return ParentHomeData(linkedStudentName: row.linkedStudentName);
  }

  Future<void> clearAll() async {
    await db.transaction(() async {
      await db.delete(db.cachedProfiles).go();
      await db.delete(db.cachedClasses).go();
      await db.delete(db.cachedLibraryClasses).go();
      await db.delete(db.cachedLibraryItems).go();
      await db.delete(db.cachedParentHomes).go();
      await db.delete(db.cachedSnapshots).go();
      await db.delete(db.outboxEntries).go();
    });
  }

  Future<void> close() => db.close();

  Future<bool> _hasSnapshot(String kind) async {
    final query = db.select(db.cachedSnapshots)
      ..where((t) => t.kind.equals(kind));
    return await query.getSingleOrNull() != null;
  }

  Future<void> _markSnapshot(String kind, DateTime cachedAt) async {
    await db
        .into(db.cachedSnapshots)
        .insertOnConflictUpdate(
          CachedSnapshotsCompanion.insert(kind: kind, cachedAt: cachedAt),
        );
  }

  Future<void> _deleteSnapshot(String kind) async {
    await (db.delete(
      db.cachedSnapshots,
    )..where((t) => t.kind.equals(kind))).go();
  }

  static List<String> _stringList(String json) => [
    for (final value in jsonDecode(json) as List<Object?>) value! as String,
  ];

  static ProfileResult _profileResultFromRow(CachedProfile row) {
    final role = row.role == null
        ? null
        : UserRole.values.asNameMap()[row.role];
    if (row.status != ProfileStatus.ready.name ||
        role == null ||
        row.userId == null ||
        row.name == null ||
        row.email == null) {
      return ProfileResult(
        status: ProfileStatus.notSetUp,
        signedInEmail: row.signedInEmail,
      );
    }
    return ProfileResult(
      status: ProfileStatus.ready,
      signedInEmail: row.signedInEmail,
      profile: Profile(
        userId: row.userId!,
        role: role,
        name: row.name!,
        email: row.email!,
        linkedStudentName: row.linkedStudentName,
      ),
    );
  }
}

/// The drift-backed outbox, implementing the phase 1 interface.
class DriftOutbox implements Outbox {
  DriftOutbox(this.db);

  final EduBoxDatabase db;

  @override
  Future<int> enqueue(OutboxWrite write) => db
      .into(db.outboxEntries)
      .insert(
        OutboxEntriesCompanion.insert(
          operation: write.operation,
          payloadJson: jsonEncode(write.payload),
          createdAt: write.createdAt,
          state: write.state.name,
          attempts: Value(write.attempts),
          lastError: Value(write.lastError),
        ),
      );

  @override
  Future<List<OutboxWrite>> pending() async {
    final rows = await _orderedRows(
      (t) => t.state.equals(OutboxState.pending.name),
    );
    return rows.map(_toWrite).toList();
  }

  @override
  Future<List<OutboxWrite>> all() async {
    final rows = await _orderedRows();
    return rows.map(_toWrite).toList();
  }

  @override
  Future<void> markSent(int id) async {
    await (db.delete(db.outboxEntries)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> markFailed(int id, String reason) async {
    final row = await (db.select(
      db.outboxEntries,
    )..where((t) => t.id.equals(id))).getSingle();
    await (db.update(
      db.outboxEntries,
    )..where((t) => t.id.equals(id))).write(
      OutboxEntriesCompanion(
        state: Value(OutboxState.failed.name),
        attempts: Value(row.attempts + 1),
        lastError: Value(reason),
      ),
    );
  }

  @override
  Future<void> retry(int id) async {
    await (db.update(
      db.outboxEntries,
    )..where((t) => t.id.equals(id))).write(
      const OutboxEntriesCompanion(
        state: Value('pending'),
        lastError: Value(null),
      ),
    );
  }

  Future<List<OutboxEntry>> _orderedRows([
    Expression<bool> Function(OutboxEntries table)? where,
  ]) {
    final query = db.select(db.outboxEntries)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    if (where != null) query.where(where);
    return query.get();
  }

  static OutboxWrite _toWrite(OutboxEntry row) => OutboxWrite(
    id: row.id,
    operation: row.operation,
    payload: (jsonDecode(row.payloadJson) as Map<String, dynamic>)
        .cast<String, Object?>(),
    createdAt: row.createdAt,
    state: OutboxState.values.byName(row.state),
    attempts: row.attempts,
    lastError: row.lastError,
  );
}
