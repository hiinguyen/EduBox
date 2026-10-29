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

abstract class SchoolClass
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  SchoolClass._({
    this.id,
    required this.teacherId,
    required this.name,
    required this.gradeLevel,
  });

  factory SchoolClass({
    int? id,
    required int teacherId,
    required String name,
    required int gradeLevel,
  }) = _SchoolClassImpl;

  factory SchoolClass.fromJson(Map<String, dynamic> jsonSerialization) {
    return SchoolClass(
      id: jsonSerialization['id'] as int?,
      teacherId: jsonSerialization['teacherId'] as int,
      name: jsonSerialization['name'] as String,
      gradeLevel: jsonSerialization['gradeLevel'] as int,
    );
  }

  static final t = SchoolClassTable();

  static const db = SchoolClassRepository._();

  @override
  int? id;

  int teacherId;

  String name;

  int gradeLevel;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [SchoolClass]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SchoolClass copyWith({
    int? id,
    int? teacherId,
    String? name,
    int? gradeLevel,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SchoolClass',
      if (id != null) 'id': id,
      'teacherId': teacherId,
      'name': name,
      'gradeLevel': gradeLevel,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SchoolClassInclude include() {
    return SchoolClassInclude._();
  }

  static SchoolClassIncludeList includeList({
    _is.WhereExpressionBuilder<SchoolClassTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SchoolClassTable>? orderBy,
    _is.OrderByListBuilder<SchoolClassTable>? orderByList,
    SchoolClassInclude? include,
  }) {
    return SchoolClassIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SchoolClass.t),
      orderByList: orderByList?.call(SchoolClass.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SchoolClassImpl extends SchoolClass {
  _SchoolClassImpl({
    int? id,
    required int teacherId,
    required String name,
    required int gradeLevel,
  }) : super._(
         id: id,
         teacherId: teacherId,
         name: name,
         gradeLevel: gradeLevel,
       );

  /// Returns a shallow copy of this [SchoolClass]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SchoolClass copyWith({
    Object? id = _Undefined,
    int? teacherId,
    String? name,
    int? gradeLevel,
  }) {
    return SchoolClass(
      id: id is int? ? id : this.id,
      teacherId: teacherId ?? this.teacherId,
      name: name ?? this.name,
      gradeLevel: gradeLevel ?? this.gradeLevel,
    );
  }
}

class SchoolClassUpdateTable extends _is.UpdateTable<SchoolClassTable> {
  SchoolClassUpdateTable(super.table);

  _is.ColumnValue<int, int> teacherId(int value) => _is.ColumnValue(
    table.teacherId,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<int, int> gradeLevel(int value) => _is.ColumnValue(
    table.gradeLevel,
    value,
  );
}

class SchoolClassTable extends _is.Table<int?> {
  SchoolClassTable({super.tableRelation}) : super(tableName: 'classes') {
    updateTable = SchoolClassUpdateTable(this);
    teacherId = _is.ColumnInt(
      'teacherId',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    gradeLevel = _is.ColumnInt(
      'gradeLevel',
      this,
    );
  }

  late final SchoolClassUpdateTable updateTable;

  late final _is.ColumnInt teacherId;

  late final _is.ColumnString name;

  late final _is.ColumnInt gradeLevel;

  @override
  List<_is.Column> get columns => [
    id,
    teacherId,
    name,
    gradeLevel,
  ];
}

class SchoolClassInclude extends _is.IncludeObject {
  SchoolClassInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => SchoolClass.t;
}

class SchoolClassIncludeList extends _is.IncludeList {
  SchoolClassIncludeList._({
    _is.WhereExpressionBuilder<SchoolClassTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SchoolClass.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => SchoolClass.t;
}

class SchoolClassRepository {
  const SchoolClassRepository._();

  /// Returns a list of [SchoolClass]s matching the given query parameters.
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
  Future<List<SchoolClass>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SchoolClassTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SchoolClassTable>? orderBy,
    _is.OrderByListBuilder<SchoolClassTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SchoolClass>(
      where: where?.call(SchoolClass.t),
      orderBy: orderBy?.call(SchoolClass.t),
      orderByList: orderByList?.call(SchoolClass.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SchoolClass] matching the given query parameters.
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
  Future<SchoolClass?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SchoolClassTable>? where,
    int? offset,
    _is.OrderByBuilder<SchoolClassTable>? orderBy,
    _is.OrderByListBuilder<SchoolClassTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SchoolClass>(
      where: where?.call(SchoolClass.t),
      orderBy: orderBy?.call(SchoolClass.t),
      orderByList: orderByList?.call(SchoolClass.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SchoolClass] by its [id] or null if no such row exists.
  Future<SchoolClass?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SchoolClass>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SchoolClass]s in the list and returns the inserted rows.
  ///
  /// The returned [SchoolClass]s will have their `id` fields set.
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
  Future<List<SchoolClass>> insert(
    _is.DatabaseSession session,
    List<SchoolClass> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<SchoolClass>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [SchoolClass] and returns the inserted row.
  ///
  /// The returned [SchoolClass] will have its `id` field set.
  Future<SchoolClass> insertRow(
    _is.DatabaseSession session,
    SchoolClass row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<SchoolClass>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [SchoolClass]s in the list and returns the resulting rows.
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
  /// The returned [SchoolClass]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SchoolClass>> upsert(
    _is.DatabaseSession session,
    List<SchoolClass> rows, {
    required _is.ColumnSelections<SchoolClassTable> conflictColumns,
    _is.ColumnSelections<SchoolClassTable>? updateColumns,
    _is.WhereExpressionBuilder<SchoolClassTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<SchoolClass>(
      rows,
      conflictColumns: conflictColumns(SchoolClass.t),
      updateColumns: updateColumns?.call(SchoolClass.t),
      updateWhere: updateWhere?.call(SchoolClass.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [SchoolClass] and returns the resulting row.
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
  /// The returned [SchoolClass] will have its `id` field set.
  Future<SchoolClass?> upsertRow(
    _is.DatabaseSession session,
    SchoolClass row, {
    required _is.ColumnSelections<SchoolClassTable> conflictColumns,
    _is.ColumnSelections<SchoolClassTable>? updateColumns,
    _is.WhereExpressionBuilder<SchoolClassTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<SchoolClass>(
      row,
      conflictColumns: conflictColumns(SchoolClass.t),
      updateColumns: updateColumns?.call(SchoolClass.t),
      updateWhere: updateWhere?.call(SchoolClass.t),
      transaction: transaction,
    );
  }

  /// Updates all [SchoolClass]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SchoolClass>> update(
    _is.DatabaseSession session,
    List<SchoolClass> rows, {
    _is.ColumnSelections<SchoolClassTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<SchoolClass>(
      rows,
      columns: columns?.call(SchoolClass.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [SchoolClass]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SchoolClass> updateRow(
    _is.DatabaseSession session,
    SchoolClass row, {
    _is.ColumnSelections<SchoolClassTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<SchoolClass>(
      row,
      columns: columns?.call(SchoolClass.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SchoolClass] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SchoolClass?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<SchoolClassUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<SchoolClass>(
      id,
      columnValues: columnValues(SchoolClass.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SchoolClass]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SchoolClass>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SchoolClassUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SchoolClassTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SchoolClassTable>? orderBy,
    _is.OrderByListBuilder<SchoolClassTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<SchoolClass>(
      columnValues: columnValues(SchoolClass.t.updateTable),
      where: where(SchoolClass.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SchoolClass.t),
      orderByList: orderByList?.call(SchoolClass.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [SchoolClass]s in the list and returns the deleted rows.
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
  Future<List<SchoolClass>> delete(
    _is.DatabaseSession session,
    List<SchoolClass> rows, {
    _is.OrderByBuilder<SchoolClassTable>? orderBy,
    _is.OrderByListBuilder<SchoolClassTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<SchoolClass>(
      rows,
      orderBy: orderBy?.call(SchoolClass.t),
      orderByList: orderByList?.call(SchoolClass.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [SchoolClass].
  Future<SchoolClass> deleteRow(
    _is.DatabaseSession session,
    SchoolClass row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SchoolClass>(
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
  Future<List<SchoolClass>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SchoolClassTable> where,
    _is.OrderByBuilder<SchoolClassTable>? orderBy,
    _is.OrderByListBuilder<SchoolClassTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<SchoolClass>(
      where: where(SchoolClass.t),
      orderBy: orderBy?.call(SchoolClass.t),
      orderByList: orderByList?.call(SchoolClass.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SchoolClassTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<SchoolClass>(
      where: where?.call(SchoolClass.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SchoolClass] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SchoolClassTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SchoolClass>(
      where: where(SchoolClass.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
