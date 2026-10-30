/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _is;

abstract class ClassSubject
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ClassSubject._({
    this.id,
    required this.classId,
    required this.position,
    required this.subject,
  });

  factory ClassSubject({
    int? id,
    required int classId,
    required int position,
    required String subject,
  }) = _ClassSubjectImpl;

  factory ClassSubject.fromJson(Map<String, dynamic> jsonSerialization) {
    return ClassSubject(
      id: jsonSerialization['id'] as int?,
      classId: jsonSerialization['classId'] as int,
      position: jsonSerialization['position'] as int,
      subject: jsonSerialization['subject'] as String,
    );
  }

  static final t = ClassSubjectTable();

  static const db = ClassSubjectRepository._();

  @override
  int? id;

  int classId;

  int position;

  String subject;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ClassSubject]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ClassSubject copyWith({
    int? id,
    int? classId,
    int? position,
    String? subject,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ClassSubject',
      if (id != null) 'id': id,
      'classId': classId,
      'position': position,
      'subject': subject,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ClassSubjectInclude include() {
    return ClassSubjectInclude._();
  }

  static ClassSubjectIncludeList includeList({
    _is.WhereExpressionBuilder<ClassSubjectTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ClassSubjectTable>? orderBy,
    _is.OrderByListBuilder<ClassSubjectTable>? orderByList,
    ClassSubjectInclude? include,
  }) {
    return ClassSubjectIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ClassSubject.t),
      orderByList: orderByList?.call(ClassSubject.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ClassSubjectImpl extends ClassSubject {
  _ClassSubjectImpl({
    int? id,
    required int classId,
    required int position,
    required String subject,
  }) : super._(
         id: id,
         classId: classId,
         position: position,
         subject: subject,
       );

  /// Returns a shallow copy of this [ClassSubject]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ClassSubject copyWith({
    Object? id = _Undefined,
    int? classId,
    int? position,
    String? subject,
  }) {
    return ClassSubject(
      id: id is int? ? id : this.id,
      classId: classId ?? this.classId,
      position: position ?? this.position,
      subject: subject ?? this.subject,
    );
  }
}

class ClassSubjectUpdateTable extends _is.UpdateTable<ClassSubjectTable> {
  ClassSubjectUpdateTable(super.table);

  _is.ColumnValue<int, int> classId(int value) => _is.ColumnValue(
    table.classId,
    value,
  );

  _is.ColumnValue<int, int> position(int value) => _is.ColumnValue(
    table.position,
    value,
  );

  _is.ColumnValue<String, String> subject(String value) => _is.ColumnValue(
    table.subject,
    value,
  );
}

class ClassSubjectTable extends _is.Table<int?> {
  ClassSubjectTable({super.tableRelation})
    : super(tableName: 'class_subjects') {
    updateTable = ClassSubjectUpdateTable(this);
    classId = _is.ColumnInt(
      'classId',
      this,
    );
    position = _is.ColumnInt(
      'position',
      this,
    );
    subject = _is.ColumnString(
      'subject',
      this,
    );
  }

  late final ClassSubjectUpdateTable updateTable;

  late final _is.ColumnInt classId;

  late final _is.ColumnInt position;

  late final _is.ColumnString subject;

  @override
  List<_is.Column> get columns => [
    id,
    classId,
    position,
    subject,
  ];
}

class ClassSubjectInclude extends _is.IncludeObject {
  ClassSubjectInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ClassSubject.t;
}

class ClassSubjectIncludeList extends _is.IncludeList {
  ClassSubjectIncludeList._({
    _is.WhereExpressionBuilder<ClassSubjectTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ClassSubject.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ClassSubject.t;
}

class ClassSubjectRepository {
  const ClassSubjectRepository._();

  /// Returns a list of [ClassSubject]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<ClassSubject>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ClassSubjectTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ClassSubjectTable>? orderBy,
    _is.OrderByListBuilder<ClassSubjectTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ClassSubject>(
      where: where?.call(ClassSubject.t),
      orderBy: orderBy?.call(ClassSubject.t),
      orderByList: orderByList?.call(ClassSubject.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ClassSubject] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<ClassSubject?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ClassSubjectTable>? where,
    int? offset,
    _is.OrderByBuilder<ClassSubjectTable>? orderBy,
    _is.OrderByListBuilder<ClassSubjectTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ClassSubject>(
      where: where?.call(ClassSubject.t),
      orderBy: orderBy?.call(ClassSubject.t),
      orderByList: orderByList?.call(ClassSubject.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ClassSubject] by its [id] or null if no such row exists.
  Future<ClassSubject?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ClassSubject>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ClassSubject]s in the list and returns the inserted rows.
  ///
  /// The returned [ClassSubject]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ClassSubject>> insert(
    _is.DatabaseSession session,
    List<ClassSubject> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ClassSubject>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ClassSubject] and returns the inserted row.
  ///
  /// The returned [ClassSubject] will have its `id` field set.
  Future<ClassSubject> insertRow(
    _is.DatabaseSession session,
    ClassSubject row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ClassSubject>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ClassSubject]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [ClassSubject]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ClassSubject>> upsert(
    _is.DatabaseSession session,
    List<ClassSubject> rows, {
    required _is.ColumnSelections<ClassSubjectTable> conflictColumns,
    _is.ColumnSelections<ClassSubjectTable>? updateColumns,
    _is.WhereExpressionBuilder<ClassSubjectTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ClassSubject>(
      rows,
      conflictColumns: conflictColumns(ClassSubject.t),
      updateColumns: updateColumns?.call(ClassSubject.t),
      updateWhere: updateWhere?.call(ClassSubject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ClassSubject] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [ClassSubject] will have its `id` field set.
  Future<ClassSubject?> upsertRow(
    _is.DatabaseSession session,
    ClassSubject row, {
    required _is.ColumnSelections<ClassSubjectTable> conflictColumns,
    _is.ColumnSelections<ClassSubjectTable>? updateColumns,
    _is.WhereExpressionBuilder<ClassSubjectTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ClassSubject>(
      row,
      conflictColumns: conflictColumns(ClassSubject.t),
      updateColumns: updateColumns?.call(ClassSubject.t),
      updateWhere: updateWhere?.call(ClassSubject.t),
      transaction: transaction,
    );
  }

  /// Updates all [ClassSubject]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ClassSubject>> update(
    _is.DatabaseSession session,
    List<ClassSubject> rows, {
    _is.ColumnSelections<ClassSubjectTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ClassSubject>(
      rows,
      columns: columns?.call(ClassSubject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ClassSubject]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ClassSubject> updateRow(
    _is.DatabaseSession session,
    ClassSubject row, {
    _is.ColumnSelections<ClassSubjectTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ClassSubject>(
      row,
      columns: columns?.call(ClassSubject.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ClassSubject] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ClassSubject?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ClassSubjectUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ClassSubject>(
      id,
      columnValues: columnValues(ClassSubject.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ClassSubject]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ClassSubject>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ClassSubjectUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ClassSubjectTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ClassSubjectTable>? orderBy,
    _is.OrderByListBuilder<ClassSubjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ClassSubject>(
      columnValues: columnValues(ClassSubject.t.updateTable),
      where: where(ClassSubject.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ClassSubject.t),
      orderByList: orderByList?.call(ClassSubject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ClassSubject]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ClassSubject>> delete(
    _is.DatabaseSession session,
    List<ClassSubject> rows, {
    _is.OrderByBuilder<ClassSubjectTable>? orderBy,
    _is.OrderByListBuilder<ClassSubjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ClassSubject>(
      rows,
      orderBy: orderBy?.call(ClassSubject.t),
      orderByList: orderByList?.call(ClassSubject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ClassSubject].
  Future<ClassSubject> deleteRow(
    _is.DatabaseSession session,
    ClassSubject row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ClassSubject>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ClassSubject>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ClassSubjectTable> where,
    _is.OrderByBuilder<ClassSubjectTable>? orderBy,
    _is.OrderByListBuilder<ClassSubjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ClassSubject>(
      where: where(ClassSubject.t),
      orderBy: orderBy?.call(ClassSubject.t),
      orderByList: orderByList?.call(ClassSubject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ClassSubjectTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ClassSubject>(
      where: where?.call(ClassSubject.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ClassSubject] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ClassSubjectTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ClassSubject>(
      where: where(ClassSubject.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
