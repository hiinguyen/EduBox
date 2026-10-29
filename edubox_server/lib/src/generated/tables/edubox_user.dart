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

abstract class EduboxUser
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  EduboxUser._({
    this.id,
    required this.authUserId,
    this.role,
    required this.name,
    required this.email,
    this.linkedStudentId,
    this.linkedStudentName,
  });

  factory EduboxUser({
    int? id,
    required _is.UuidValue authUserId,
    String? role,
    required String name,
    required String email,
    int? linkedStudentId,
    String? linkedStudentName,
  }) = _EduboxUserImpl;

  factory EduboxUser.fromJson(Map<String, dynamic> jsonSerialization) {
    return EduboxUser(
      id: jsonSerialization['id'] as int?,
      authUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      role: jsonSerialization['role'] as String?,
      name: jsonSerialization['name'] as String,
      email: jsonSerialization['email'] as String,
      linkedStudentId: jsonSerialization['linkedStudentId'] as int?,
      linkedStudentName: jsonSerialization['linkedStudentName'] as String?,
    );
  }

  static final t = EduboxUserTable();

  static const db = EduboxUserRepository._();

  @override
  int? id;

  _is.UuidValue authUserId;

  String? role;

  String name;

  String email;

  int? linkedStudentId;

  String? linkedStudentName;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [EduboxUser]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  EduboxUser copyWith({
    int? id,
    _is.UuidValue? authUserId,
    String? role,
    String? name,
    String? email,
    int? linkedStudentId,
    String? linkedStudentName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EduboxUser',
      if (id != null) 'id': id,
      'authUserId': authUserId.toJson(),
      if (role != null) 'role': role,
      'name': name,
      'email': email,
      if (linkedStudentId != null) 'linkedStudentId': linkedStudentId,
      if (linkedStudentName != null) 'linkedStudentName': linkedStudentName,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static EduboxUserInclude include() {
    return EduboxUserInclude._();
  }

  static EduboxUserIncludeList includeList({
    _is.WhereExpressionBuilder<EduboxUserTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EduboxUserTable>? orderBy,
    _is.OrderByListBuilder<EduboxUserTable>? orderByList,
    EduboxUserInclude? include,
  }) {
    return EduboxUserIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EduboxUser.t),
      orderByList: orderByList?.call(EduboxUser.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EduboxUserImpl extends EduboxUser {
  _EduboxUserImpl({
    int? id,
    required _is.UuidValue authUserId,
    String? role,
    required String name,
    required String email,
    int? linkedStudentId,
    String? linkedStudentName,
  }) : super._(
         id: id,
         authUserId: authUserId,
         role: role,
         name: name,
         email: email,
         linkedStudentId: linkedStudentId,
         linkedStudentName: linkedStudentName,
       );

  /// Returns a shallow copy of this [EduboxUser]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  EduboxUser copyWith({
    Object? id = _Undefined,
    _is.UuidValue? authUserId,
    Object? role = _Undefined,
    String? name,
    String? email,
    Object? linkedStudentId = _Undefined,
    Object? linkedStudentName = _Undefined,
  }) {
    return EduboxUser(
      id: id is int? ? id : this.id,
      authUserId: authUserId ?? this.authUserId,
      role: role is String? ? role : this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      linkedStudentId: linkedStudentId is int?
          ? linkedStudentId
          : this.linkedStudentId,
      linkedStudentName: linkedStudentName is String?
          ? linkedStudentName
          : this.linkedStudentName,
    );
  }
}

class EduboxUserUpdateTable extends _is.UpdateTable<EduboxUserTable> {
  EduboxUserUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> authUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.authUserId,
    value,
  );

  _is.ColumnValue<String, String> role(String? value) => _is.ColumnValue(
    table.role,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> email(String value) => _is.ColumnValue(
    table.email,
    value,
  );

  _is.ColumnValue<int, int> linkedStudentId(int? value) => _is.ColumnValue(
    table.linkedStudentId,
    value,
  );

  _is.ColumnValue<String, String> linkedStudentName(String? value) =>
      _is.ColumnValue(
        table.linkedStudentName,
        value,
      );
}

class EduboxUserTable extends _is.Table<int?> {
  EduboxUserTable({super.tableRelation}) : super(tableName: 'users') {
    updateTable = EduboxUserUpdateTable(this);
    authUserId = _is.ColumnUuid(
      'authUserId',
      this,
    );
    role = _is.ColumnString(
      'role',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    email = _is.ColumnString(
      'email',
      this,
    );
    linkedStudentId = _is.ColumnInt(
      'linkedStudentId',
      this,
    );
    linkedStudentName = _is.ColumnString(
      'linkedStudentName',
      this,
    );
  }

  late final EduboxUserUpdateTable updateTable;

  late final _is.ColumnUuid authUserId;

  late final _is.ColumnString role;

  late final _is.ColumnString name;

  late final _is.ColumnString email;

  late final _is.ColumnInt linkedStudentId;

  late final _is.ColumnString linkedStudentName;

  @override
  List<_is.Column> get columns => [
    id,
    authUserId,
    role,
    name,
    email,
    linkedStudentId,
    linkedStudentName,
  ];
}

class EduboxUserInclude extends _is.IncludeObject {
  EduboxUserInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => EduboxUser.t;
}

class EduboxUserIncludeList extends _is.IncludeList {
  EduboxUserIncludeList._({
    _is.WhereExpressionBuilder<EduboxUserTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EduboxUser.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => EduboxUser.t;
}

class EduboxUserRepository {
  const EduboxUserRepository._();

  /// Returns a list of [EduboxUser]s matching the given query parameters.
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
  Future<List<EduboxUser>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EduboxUserTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EduboxUserTable>? orderBy,
    _is.OrderByListBuilder<EduboxUserTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<EduboxUser>(
      where: where?.call(EduboxUser.t),
      orderBy: orderBy?.call(EduboxUser.t),
      orderByList: orderByList?.call(EduboxUser.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [EduboxUser] matching the given query parameters.
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
  Future<EduboxUser?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EduboxUserTable>? where,
    int? offset,
    _is.OrderByBuilder<EduboxUserTable>? orderBy,
    _is.OrderByListBuilder<EduboxUserTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<EduboxUser>(
      where: where?.call(EduboxUser.t),
      orderBy: orderBy?.call(EduboxUser.t),
      orderByList: orderByList?.call(EduboxUser.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [EduboxUser] by its [id] or null if no such row exists.
  Future<EduboxUser?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<EduboxUser>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [EduboxUser]s in the list and returns the inserted rows.
  ///
  /// The returned [EduboxUser]s will have their `id` fields set.
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
  Future<List<EduboxUser>> insert(
    _is.DatabaseSession session,
    List<EduboxUser> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<EduboxUser>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [EduboxUser] and returns the inserted row.
  ///
  /// The returned [EduboxUser] will have its `id` field set.
  Future<EduboxUser> insertRow(
    _is.DatabaseSession session,
    EduboxUser row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<EduboxUser>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [EduboxUser]s in the list and returns the resulting rows.
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
  /// The returned [EduboxUser]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EduboxUser>> upsert(
    _is.DatabaseSession session,
    List<EduboxUser> rows, {
    required _is.ColumnSelections<EduboxUserTable> conflictColumns,
    _is.ColumnSelections<EduboxUserTable>? updateColumns,
    _is.WhereExpressionBuilder<EduboxUserTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<EduboxUser>(
      rows,
      conflictColumns: conflictColumns(EduboxUser.t),
      updateColumns: updateColumns?.call(EduboxUser.t),
      updateWhere: updateWhere?.call(EduboxUser.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [EduboxUser] and returns the resulting row.
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
  /// The returned [EduboxUser] will have its `id` field set.
  Future<EduboxUser?> upsertRow(
    _is.DatabaseSession session,
    EduboxUser row, {
    required _is.ColumnSelections<EduboxUserTable> conflictColumns,
    _is.ColumnSelections<EduboxUserTable>? updateColumns,
    _is.WhereExpressionBuilder<EduboxUserTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<EduboxUser>(
      row,
      conflictColumns: conflictColumns(EduboxUser.t),
      updateColumns: updateColumns?.call(EduboxUser.t),
      updateWhere: updateWhere?.call(EduboxUser.t),
      transaction: transaction,
    );
  }

  /// Updates all [EduboxUser]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EduboxUser>> update(
    _is.DatabaseSession session,
    List<EduboxUser> rows, {
    _is.ColumnSelections<EduboxUserTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<EduboxUser>(
      rows,
      columns: columns?.call(EduboxUser.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [EduboxUser]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EduboxUser> updateRow(
    _is.DatabaseSession session,
    EduboxUser row, {
    _is.ColumnSelections<EduboxUserTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<EduboxUser>(
      row,
      columns: columns?.call(EduboxUser.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EduboxUser] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<EduboxUser?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<EduboxUserUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<EduboxUser>(
      id,
      columnValues: columnValues(EduboxUser.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [EduboxUser]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EduboxUser>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<EduboxUserUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<EduboxUserTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EduboxUserTable>? orderBy,
    _is.OrderByListBuilder<EduboxUserTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<EduboxUser>(
      columnValues: columnValues(EduboxUser.t.updateTable),
      where: where(EduboxUser.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EduboxUser.t),
      orderByList: orderByList?.call(EduboxUser.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [EduboxUser]s in the list and returns the deleted rows.
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
  Future<List<EduboxUser>> delete(
    _is.DatabaseSession session,
    List<EduboxUser> rows, {
    _is.OrderByBuilder<EduboxUserTable>? orderBy,
    _is.OrderByListBuilder<EduboxUserTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<EduboxUser>(
      rows,
      orderBy: orderBy?.call(EduboxUser.t),
      orderByList: orderByList?.call(EduboxUser.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [EduboxUser].
  Future<EduboxUser> deleteRow(
    _is.DatabaseSession session,
    EduboxUser row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EduboxUser>(
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
  Future<List<EduboxUser>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EduboxUserTable> where,
    _is.OrderByBuilder<EduboxUserTable>? orderBy,
    _is.OrderByListBuilder<EduboxUserTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<EduboxUser>(
      where: where(EduboxUser.t),
      orderBy: orderBy?.call(EduboxUser.t),
      orderByList: orderByList?.call(EduboxUser.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EduboxUserTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<EduboxUser>(
      where: where?.call(EduboxUser.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [EduboxUser] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EduboxUserTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<EduboxUser>(
      where: where(EduboxUser.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
