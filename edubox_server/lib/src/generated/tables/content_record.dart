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
import '../enums/content_status.dart' as _inhfue1l;
import '../enums/content_type.dart' as _iqkq9d0y;

abstract class ContentRecord
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ContentRecord._({
    this.id,
    required this.ownerTeacherId,
    required this.type,
    required this.subject,
    required this.gradeLevel,
    required this.title,
    this.storagePath,
    required this.status,
    this.approvedBy,
    required this.createdAt,
  });

  factory ContentRecord({
    int? id,
    required int ownerTeacherId,
    required _iqkq9d0y.ContentType type,
    required String subject,
    required int gradeLevel,
    required String title,
    String? storagePath,
    required _inhfue1l.ContentStatus status,
    int? approvedBy,
    required DateTime createdAt,
  }) = _ContentRecordImpl;

  factory ContentRecord.fromJson(Map<String, dynamic> jsonSerialization) {
    return ContentRecord(
      id: jsonSerialization['id'] as int?,
      ownerTeacherId: jsonSerialization['ownerTeacherId'] as int,
      type: _iqkq9d0y.ContentType.fromJson(
        (jsonSerialization['type'] as String),
      ),
      subject: jsonSerialization['subject'] as String,
      gradeLevel: jsonSerialization['gradeLevel'] as int,
      title: jsonSerialization['title'] as String,
      storagePath: jsonSerialization['storagePath'] as String?,
      status: _inhfue1l.ContentStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      approvedBy: jsonSerialization['approvedBy'] as int?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = ContentRecordTable();

  static const db = ContentRecordRepository._();

  @override
  int? id;

  int ownerTeacherId;

  _iqkq9d0y.ContentType type;

  String subject;

  int gradeLevel;

  String title;

  String? storagePath;

  _inhfue1l.ContentStatus status;

  int? approvedBy;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ContentRecord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ContentRecord copyWith({
    int? id,
    int? ownerTeacherId,
    _iqkq9d0y.ContentType? type,
    String? subject,
    int? gradeLevel,
    String? title,
    String? storagePath,
    _inhfue1l.ContentStatus? status,
    int? approvedBy,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ContentRecord',
      if (id != null) 'id': id,
      'ownerTeacherId': ownerTeacherId,
      'type': type.toJson(),
      'subject': subject,
      'gradeLevel': gradeLevel,
      'title': title,
      if (storagePath != null) 'storagePath': storagePath,
      'status': status.toJson(),
      if (approvedBy != null) 'approvedBy': approvedBy,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ContentRecordInclude include() {
    return ContentRecordInclude._();
  }

  static ContentRecordIncludeList includeList({
    _is.WhereExpressionBuilder<ContentRecordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ContentRecordTable>? orderBy,
    _is.OrderByListBuilder<ContentRecordTable>? orderByList,
    ContentRecordInclude? include,
  }) {
    return ContentRecordIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ContentRecord.t),
      orderByList: orderByList?.call(ContentRecord.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ContentRecordImpl extends ContentRecord {
  _ContentRecordImpl({
    int? id,
    required int ownerTeacherId,
    required _iqkq9d0y.ContentType type,
    required String subject,
    required int gradeLevel,
    required String title,
    String? storagePath,
    required _inhfue1l.ContentStatus status,
    int? approvedBy,
    required DateTime createdAt,
  }) : super._(
         id: id,
         ownerTeacherId: ownerTeacherId,
         type: type,
         subject: subject,
         gradeLevel: gradeLevel,
         title: title,
         storagePath: storagePath,
         status: status,
         approvedBy: approvedBy,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ContentRecord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ContentRecord copyWith({
    Object? id = _Undefined,
    int? ownerTeacherId,
    _iqkq9d0y.ContentType? type,
    String? subject,
    int? gradeLevel,
    String? title,
    Object? storagePath = _Undefined,
    _inhfue1l.ContentStatus? status,
    Object? approvedBy = _Undefined,
    DateTime? createdAt,
  }) {
    return ContentRecord(
      id: id is int? ? id : this.id,
      ownerTeacherId: ownerTeacherId ?? this.ownerTeacherId,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      title: title ?? this.title,
      storagePath: storagePath is String? ? storagePath : this.storagePath,
      status: status ?? this.status,
      approvedBy: approvedBy is int? ? approvedBy : this.approvedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ContentRecordUpdateTable extends _is.UpdateTable<ContentRecordTable> {
  ContentRecordUpdateTable(super.table);

  _is.ColumnValue<int, int> ownerTeacherId(int value) => _is.ColumnValue(
    table.ownerTeacherId,
    value,
  );

  _is.ColumnValue<_iqkq9d0y.ContentType, _iqkq9d0y.ContentType> type(
    _iqkq9d0y.ContentType value,
  ) => _is.ColumnValue(
    table.type,
    value,
  );

  _is.ColumnValue<String, String> subject(String value) => _is.ColumnValue(
    table.subject,
    value,
  );

  _is.ColumnValue<int, int> gradeLevel(int value) => _is.ColumnValue(
    table.gradeLevel,
    value,
  );

  _is.ColumnValue<String, String> title(String value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<String, String> storagePath(String? value) => _is.ColumnValue(
    table.storagePath,
    value,
  );

  _is.ColumnValue<_inhfue1l.ContentStatus, _inhfue1l.ContentStatus> status(
    _inhfue1l.ContentStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<int, int> approvedBy(int? value) => _is.ColumnValue(
    table.approvedBy,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ContentRecordTable extends _is.Table<int?> {
  ContentRecordTable({super.tableRelation}) : super(tableName: 'content') {
    updateTable = ContentRecordUpdateTable(this);
    ownerTeacherId = _is.ColumnInt(
      'ownerTeacherId',
      this,
    );
    type = _is.ColumnEnum(
      'type',
      this,
      _is.EnumSerialization.byName,
    );
    subject = _is.ColumnString(
      'subject',
      this,
    );
    gradeLevel = _is.ColumnInt(
      'gradeLevel',
      this,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    storagePath = _is.ColumnString(
      'storagePath',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    approvedBy = _is.ColumnInt(
      'approvedBy',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ContentRecordUpdateTable updateTable;

  late final _is.ColumnInt ownerTeacherId;

  late final _is.ColumnEnum<_iqkq9d0y.ContentType> type;

  late final _is.ColumnString subject;

  late final _is.ColumnInt gradeLevel;

  late final _is.ColumnString title;

  late final _is.ColumnString storagePath;

  late final _is.ColumnEnum<_inhfue1l.ContentStatus> status;

  late final _is.ColumnInt approvedBy;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    ownerTeacherId,
    type,
    subject,
    gradeLevel,
    title,
    storagePath,
    status,
    approvedBy,
    createdAt,
  ];
}

class ContentRecordInclude extends _is.IncludeObject {
  ContentRecordInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ContentRecord.t;
}

class ContentRecordIncludeList extends _is.IncludeList {
  ContentRecordIncludeList._({
    _is.WhereExpressionBuilder<ContentRecordTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ContentRecord.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ContentRecord.t;
}

class ContentRecordRepository {
  const ContentRecordRepository._();

  /// Returns a list of [ContentRecord]s matching the given query parameters.
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
  Future<List<ContentRecord>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ContentRecordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ContentRecordTable>? orderBy,
    _is.OrderByListBuilder<ContentRecordTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ContentRecord>(
      where: where?.call(ContentRecord.t),
      orderBy: orderBy?.call(ContentRecord.t),
      orderByList: orderByList?.call(ContentRecord.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ContentRecord] matching the given query parameters.
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
  Future<ContentRecord?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ContentRecordTable>? where,
    int? offset,
    _is.OrderByBuilder<ContentRecordTable>? orderBy,
    _is.OrderByListBuilder<ContentRecordTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ContentRecord>(
      where: where?.call(ContentRecord.t),
      orderBy: orderBy?.call(ContentRecord.t),
      orderByList: orderByList?.call(ContentRecord.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ContentRecord] by its [id] or null if no such row exists.
  Future<ContentRecord?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ContentRecord>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ContentRecord]s in the list and returns the inserted rows.
  ///
  /// The returned [ContentRecord]s will have their `id` fields set.
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
  Future<List<ContentRecord>> insert(
    _is.DatabaseSession session,
    List<ContentRecord> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ContentRecord>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ContentRecord] and returns the inserted row.
  ///
  /// The returned [ContentRecord] will have its `id` field set.
  Future<ContentRecord> insertRow(
    _is.DatabaseSession session,
    ContentRecord row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ContentRecord>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ContentRecord]s in the list and returns the resulting rows.
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
  /// The returned [ContentRecord]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ContentRecord>> upsert(
    _is.DatabaseSession session,
    List<ContentRecord> rows, {
    required _is.ColumnSelections<ContentRecordTable> conflictColumns,
    _is.ColumnSelections<ContentRecordTable>? updateColumns,
    _is.WhereExpressionBuilder<ContentRecordTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ContentRecord>(
      rows,
      conflictColumns: conflictColumns(ContentRecord.t),
      updateColumns: updateColumns?.call(ContentRecord.t),
      updateWhere: updateWhere?.call(ContentRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ContentRecord] and returns the resulting row.
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
  /// The returned [ContentRecord] will have its `id` field set.
  Future<ContentRecord?> upsertRow(
    _is.DatabaseSession session,
    ContentRecord row, {
    required _is.ColumnSelections<ContentRecordTable> conflictColumns,
    _is.ColumnSelections<ContentRecordTable>? updateColumns,
    _is.WhereExpressionBuilder<ContentRecordTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ContentRecord>(
      row,
      conflictColumns: conflictColumns(ContentRecord.t),
      updateColumns: updateColumns?.call(ContentRecord.t),
      updateWhere: updateWhere?.call(ContentRecord.t),
      transaction: transaction,
    );
  }

  /// Updates all [ContentRecord]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ContentRecord>> update(
    _is.DatabaseSession session,
    List<ContentRecord> rows, {
    _is.ColumnSelections<ContentRecordTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ContentRecord>(
      rows,
      columns: columns?.call(ContentRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ContentRecord]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ContentRecord> updateRow(
    _is.DatabaseSession session,
    ContentRecord row, {
    _is.ColumnSelections<ContentRecordTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ContentRecord>(
      row,
      columns: columns?.call(ContentRecord.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ContentRecord] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ContentRecord?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ContentRecordUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ContentRecord>(
      id,
      columnValues: columnValues(ContentRecord.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ContentRecord]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ContentRecord>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ContentRecordUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ContentRecordTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ContentRecordTable>? orderBy,
    _is.OrderByListBuilder<ContentRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ContentRecord>(
      columnValues: columnValues(ContentRecord.t.updateTable),
      where: where(ContentRecord.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ContentRecord.t),
      orderByList: orderByList?.call(ContentRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ContentRecord]s in the list and returns the deleted rows.
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
  Future<List<ContentRecord>> delete(
    _is.DatabaseSession session,
    List<ContentRecord> rows, {
    _is.OrderByBuilder<ContentRecordTable>? orderBy,
    _is.OrderByListBuilder<ContentRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ContentRecord>(
      rows,
      orderBy: orderBy?.call(ContentRecord.t),
      orderByList: orderByList?.call(ContentRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ContentRecord].
  Future<ContentRecord> deleteRow(
    _is.DatabaseSession session,
    ContentRecord row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ContentRecord>(
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
  Future<List<ContentRecord>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ContentRecordTable> where,
    _is.OrderByBuilder<ContentRecordTable>? orderBy,
    _is.OrderByListBuilder<ContentRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ContentRecord>(
      where: where(ContentRecord.t),
      orderBy: orderBy?.call(ContentRecord.t),
      orderByList: orderByList?.call(ContentRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ContentRecordTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ContentRecord>(
      where: where?.call(ContentRecord.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ContentRecord] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ContentRecordTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ContentRecord>(
      where: where(ContentRecord.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
