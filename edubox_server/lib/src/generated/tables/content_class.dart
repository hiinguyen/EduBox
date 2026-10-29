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

abstract class ContentClass
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ContentClass._({
    this.id,
    required this.contentId,
    required this.classId,
  });

  factory ContentClass({
    int? id,
    required int contentId,
    required int classId,
  }) = _ContentClassImpl;

  factory ContentClass.fromJson(Map<String, dynamic> jsonSerialization) {
    return ContentClass(
      id: jsonSerialization['id'] as int?,
      contentId: jsonSerialization['contentId'] as int,
      classId: jsonSerialization['classId'] as int,
    );
  }

  static final t = ContentClassTable();

  static const db = ContentClassRepository._();

  @override
  int? id;

  int contentId;

  int classId;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ContentClass]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ContentClass copyWith({
    int? id,
    int? contentId,
    int? classId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ContentClass',
      if (id != null) 'id': id,
      'contentId': contentId,
      'classId': classId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ContentClassInclude include() {
    return ContentClassInclude._();
  }

  static ContentClassIncludeList includeList({
    _is.WhereExpressionBuilder<ContentClassTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ContentClassTable>? orderBy,
    _is.OrderByListBuilder<ContentClassTable>? orderByList,
    ContentClassInclude? include,
  }) {
    return ContentClassIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ContentClass.t),
      orderByList: orderByList?.call(ContentClass.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ContentClassImpl extends ContentClass {
  _ContentClassImpl({
    int? id,
    required int contentId,
    required int classId,
  }) : super._(
         id: id,
         contentId: contentId,
         classId: classId,
       );

  /// Returns a shallow copy of this [ContentClass]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ContentClass copyWith({
    Object? id = _Undefined,
    int? contentId,
    int? classId,
  }) {
    return ContentClass(
      id: id is int? ? id : this.id,
      contentId: contentId ?? this.contentId,
      classId: classId ?? this.classId,
    );
  }
}

class ContentClassUpdateTable extends _is.UpdateTable<ContentClassTable> {
  ContentClassUpdateTable(super.table);

  _is.ColumnValue<int, int> contentId(int value) => _is.ColumnValue(
    table.contentId,
    value,
  );

  _is.ColumnValue<int, int> classId(int value) => _is.ColumnValue(
    table.classId,
    value,
  );
}

class ContentClassTable extends _is.Table<int?> {
  ContentClassTable({super.tableRelation})
    : super(tableName: 'content_classes') {
    updateTable = ContentClassUpdateTable(this);
    contentId = _is.ColumnInt(
      'contentId',
      this,
    );
    classId = _is.ColumnInt(
      'classId',
      this,
    );
  }

  late final ContentClassUpdateTable updateTable;

  late final _is.ColumnInt contentId;

  late final _is.ColumnInt classId;

  @override
  List<_is.Column> get columns => [
    id,
    contentId,
    classId,
  ];
}

class ContentClassInclude extends _is.IncludeObject {
  ContentClassInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ContentClass.t;
}

class ContentClassIncludeList extends _is.IncludeList {
  ContentClassIncludeList._({
    _is.WhereExpressionBuilder<ContentClassTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ContentClass.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ContentClass.t;
}

class ContentClassRepository {
  const ContentClassRepository._();

  /// Returns a list of [ContentClass]s matching the given query parameters.
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
  Future<List<ContentClass>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ContentClassTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ContentClassTable>? orderBy,
    _is.OrderByListBuilder<ContentClassTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ContentClass>(
      where: where?.call(ContentClass.t),
      orderBy: orderBy?.call(ContentClass.t),
      orderByList: orderByList?.call(ContentClass.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ContentClass] matching the given query parameters.
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
  Future<ContentClass?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ContentClassTable>? where,
    int? offset,
    _is.OrderByBuilder<ContentClassTable>? orderBy,
    _is.OrderByListBuilder<ContentClassTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ContentClass>(
      where: where?.call(ContentClass.t),
      orderBy: orderBy?.call(ContentClass.t),
      orderByList: orderByList?.call(ContentClass.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ContentClass] by its [id] or null if no such row exists.
  Future<ContentClass?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ContentClass>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ContentClass]s in the list and returns the inserted rows.
  ///
  /// The returned [ContentClass]s will have their `id` fields set.
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
  Future<List<ContentClass>> insert(
    _is.DatabaseSession session,
    List<ContentClass> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ContentClass>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ContentClass] and returns the inserted row.
  ///
  /// The returned [ContentClass] will have its `id` field set.
  Future<ContentClass> insertRow(
    _is.DatabaseSession session,
    ContentClass row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ContentClass>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ContentClass]s in the list and returns the resulting rows.
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
  /// The returned [ContentClass]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ContentClass>> upsert(
    _is.DatabaseSession session,
    List<ContentClass> rows, {
    required _is.ColumnSelections<ContentClassTable> conflictColumns,
    _is.ColumnSelections<ContentClassTable>? updateColumns,
    _is.WhereExpressionBuilder<ContentClassTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ContentClass>(
      rows,
      conflictColumns: conflictColumns(ContentClass.t),
      updateColumns: updateColumns?.call(ContentClass.t),
      updateWhere: updateWhere?.call(ContentClass.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ContentClass] and returns the resulting row.
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
  /// The returned [ContentClass] will have its `id` field set.
  Future<ContentClass?> upsertRow(
    _is.DatabaseSession session,
    ContentClass row, {
    required _is.ColumnSelections<ContentClassTable> conflictColumns,
    _is.ColumnSelections<ContentClassTable>? updateColumns,
    _is.WhereExpressionBuilder<ContentClassTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ContentClass>(
      row,
      conflictColumns: conflictColumns(ContentClass.t),
      updateColumns: updateColumns?.call(ContentClass.t),
      updateWhere: updateWhere?.call(ContentClass.t),
      transaction: transaction,
    );
  }

  /// Updates all [ContentClass]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ContentClass>> update(
    _is.DatabaseSession session,
    List<ContentClass> rows, {
    _is.ColumnSelections<ContentClassTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ContentClass>(
      rows,
      columns: columns?.call(ContentClass.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ContentClass]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ContentClass> updateRow(
    _is.DatabaseSession session,
    ContentClass row, {
    _is.ColumnSelections<ContentClassTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ContentClass>(
      row,
      columns: columns?.call(ContentClass.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ContentClass] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ContentClass?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ContentClassUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ContentClass>(
      id,
      columnValues: columnValues(ContentClass.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ContentClass]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ContentClass>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ContentClassUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ContentClassTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ContentClassTable>? orderBy,
    _is.OrderByListBuilder<ContentClassTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ContentClass>(
      columnValues: columnValues(ContentClass.t.updateTable),
      where: where(ContentClass.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ContentClass.t),
      orderByList: orderByList?.call(ContentClass.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ContentClass]s in the list and returns the deleted rows.
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
  Future<List<ContentClass>> delete(
    _is.DatabaseSession session,
    List<ContentClass> rows, {
    _is.OrderByBuilder<ContentClassTable>? orderBy,
    _is.OrderByListBuilder<ContentClassTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ContentClass>(
      rows,
      orderBy: orderBy?.call(ContentClass.t),
      orderByList: orderByList?.call(ContentClass.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ContentClass].
  Future<ContentClass> deleteRow(
    _is.DatabaseSession session,
    ContentClass row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ContentClass>(
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
  Future<List<ContentClass>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ContentClassTable> where,
    _is.OrderByBuilder<ContentClassTable>? orderBy,
    _is.OrderByListBuilder<ContentClassTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ContentClass>(
      where: where(ContentClass.t),
      orderBy: orderBy?.call(ContentClass.t),
      orderByList: orderByList?.call(ContentClass.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ContentClassTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ContentClass>(
      where: where?.call(ContentClass.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ContentClass] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ContentClassTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ContentClass>(
      where: where(ContentClass.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
