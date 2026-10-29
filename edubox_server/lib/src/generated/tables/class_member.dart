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

abstract class ClassMember
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ClassMember._({
    this.id,
    required this.classId,
    required this.studentId,
  });

  factory ClassMember({
    int? id,
    required int classId,
    required int studentId,
  }) = _ClassMemberImpl;

  factory ClassMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return ClassMember(
      id: jsonSerialization['id'] as int?,
      classId: jsonSerialization['classId'] as int,
      studentId: jsonSerialization['studentId'] as int,
    );
  }

  static final t = ClassMemberTable();

  static const db = ClassMemberRepository._();

  @override
  int? id;

  int classId;

  int studentId;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ClassMember]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ClassMember copyWith({
    int? id,
    int? classId,
    int? studentId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ClassMember',
      if (id != null) 'id': id,
      'classId': classId,
      'studentId': studentId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ClassMemberInclude include() {
    return ClassMemberInclude._();
  }

  static ClassMemberIncludeList includeList({
    _is.WhereExpressionBuilder<ClassMemberTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ClassMemberTable>? orderBy,
    _is.OrderByListBuilder<ClassMemberTable>? orderByList,
    ClassMemberInclude? include,
  }) {
    return ClassMemberIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ClassMember.t),
      orderByList: orderByList?.call(ClassMember.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ClassMemberImpl extends ClassMember {
  _ClassMemberImpl({
    int? id,
    required int classId,
    required int studentId,
  }) : super._(
         id: id,
         classId: classId,
         studentId: studentId,
       );

  /// Returns a shallow copy of this [ClassMember]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ClassMember copyWith({
    Object? id = _Undefined,
    int? classId,
    int? studentId,
  }) {
    return ClassMember(
      id: id is int? ? id : this.id,
      classId: classId ?? this.classId,
      studentId: studentId ?? this.studentId,
    );
  }
}

class ClassMemberUpdateTable extends _is.UpdateTable<ClassMemberTable> {
  ClassMemberUpdateTable(super.table);

  _is.ColumnValue<int, int> classId(int value) => _is.ColumnValue(
    table.classId,
    value,
  );

  _is.ColumnValue<int, int> studentId(int value) => _is.ColumnValue(
    table.studentId,
    value,
  );
}

class ClassMemberTable extends _is.Table<int?> {
  ClassMemberTable({super.tableRelation}) : super(tableName: 'class_members') {
    updateTable = ClassMemberUpdateTable(this);
    classId = _is.ColumnInt(
      'classId',
      this,
    );
    studentId = _is.ColumnInt(
      'studentId',
      this,
    );
  }

  late final ClassMemberUpdateTable updateTable;

  late final _is.ColumnInt classId;

  late final _is.ColumnInt studentId;

  @override
  List<_is.Column> get columns => [
    id,
    classId,
    studentId,
  ];
}

class ClassMemberInclude extends _is.IncludeObject {
  ClassMemberInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ClassMember.t;
}

class ClassMemberIncludeList extends _is.IncludeList {
  ClassMemberIncludeList._({
    _is.WhereExpressionBuilder<ClassMemberTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ClassMember.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ClassMember.t;
}

class ClassMemberRepository {
  const ClassMemberRepository._();

  /// Returns a list of [ClassMember]s matching the given query parameters.
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
  Future<List<ClassMember>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ClassMemberTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ClassMemberTable>? orderBy,
    _is.OrderByListBuilder<ClassMemberTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ClassMember>(
      where: where?.call(ClassMember.t),
      orderBy: orderBy?.call(ClassMember.t),
      orderByList: orderByList?.call(ClassMember.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ClassMember] matching the given query parameters.
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
  Future<ClassMember?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ClassMemberTable>? where,
    int? offset,
    _is.OrderByBuilder<ClassMemberTable>? orderBy,
    _is.OrderByListBuilder<ClassMemberTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ClassMember>(
      where: where?.call(ClassMember.t),
      orderBy: orderBy?.call(ClassMember.t),
      orderByList: orderByList?.call(ClassMember.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ClassMember] by its [id] or null if no such row exists.
  Future<ClassMember?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ClassMember>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ClassMember]s in the list and returns the inserted rows.
  ///
  /// The returned [ClassMember]s will have their `id` fields set.
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
  Future<List<ClassMember>> insert(
    _is.DatabaseSession session,
    List<ClassMember> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ClassMember>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ClassMember] and returns the inserted row.
  ///
  /// The returned [ClassMember] will have its `id` field set.
  Future<ClassMember> insertRow(
    _is.DatabaseSession session,
    ClassMember row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ClassMember>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ClassMember]s in the list and returns the resulting rows.
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
  /// The returned [ClassMember]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ClassMember>> upsert(
    _is.DatabaseSession session,
    List<ClassMember> rows, {
    required _is.ColumnSelections<ClassMemberTable> conflictColumns,
    _is.ColumnSelections<ClassMemberTable>? updateColumns,
    _is.WhereExpressionBuilder<ClassMemberTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ClassMember>(
      rows,
      conflictColumns: conflictColumns(ClassMember.t),
      updateColumns: updateColumns?.call(ClassMember.t),
      updateWhere: updateWhere?.call(ClassMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ClassMember] and returns the resulting row.
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
  /// The returned [ClassMember] will have its `id` field set.
  Future<ClassMember?> upsertRow(
    _is.DatabaseSession session,
    ClassMember row, {
    required _is.ColumnSelections<ClassMemberTable> conflictColumns,
    _is.ColumnSelections<ClassMemberTable>? updateColumns,
    _is.WhereExpressionBuilder<ClassMemberTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ClassMember>(
      row,
      conflictColumns: conflictColumns(ClassMember.t),
      updateColumns: updateColumns?.call(ClassMember.t),
      updateWhere: updateWhere?.call(ClassMember.t),
      transaction: transaction,
    );
  }

  /// Updates all [ClassMember]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ClassMember>> update(
    _is.DatabaseSession session,
    List<ClassMember> rows, {
    _is.ColumnSelections<ClassMemberTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ClassMember>(
      rows,
      columns: columns?.call(ClassMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ClassMember]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ClassMember> updateRow(
    _is.DatabaseSession session,
    ClassMember row, {
    _is.ColumnSelections<ClassMemberTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ClassMember>(
      row,
      columns: columns?.call(ClassMember.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ClassMember] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ClassMember?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ClassMemberUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ClassMember>(
      id,
      columnValues: columnValues(ClassMember.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ClassMember]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ClassMember>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ClassMemberUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ClassMemberTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ClassMemberTable>? orderBy,
    _is.OrderByListBuilder<ClassMemberTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ClassMember>(
      columnValues: columnValues(ClassMember.t.updateTable),
      where: where(ClassMember.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ClassMember.t),
      orderByList: orderByList?.call(ClassMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ClassMember]s in the list and returns the deleted rows.
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
  Future<List<ClassMember>> delete(
    _is.DatabaseSession session,
    List<ClassMember> rows, {
    _is.OrderByBuilder<ClassMemberTable>? orderBy,
    _is.OrderByListBuilder<ClassMemberTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ClassMember>(
      rows,
      orderBy: orderBy?.call(ClassMember.t),
      orderByList: orderByList?.call(ClassMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ClassMember].
  Future<ClassMember> deleteRow(
    _is.DatabaseSession session,
    ClassMember row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ClassMember>(
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
  Future<List<ClassMember>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ClassMemberTable> where,
    _is.OrderByBuilder<ClassMemberTable>? orderBy,
    _is.OrderByListBuilder<ClassMemberTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ClassMember>(
      where: where(ClassMember.t),
      orderBy: orderBy?.call(ClassMember.t),
      orderByList: orderByList?.call(ClassMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ClassMemberTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ClassMember>(
      where: where?.call(ClassMember.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ClassMember] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ClassMemberTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ClassMember>(
      where: where(ClassMember.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
