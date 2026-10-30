// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_store.dart';

// ignore_for_file: type=lint
class $CachedSnapshotsTable extends CachedSnapshots
    with TableInfo<$CachedSnapshotsTable, CachedSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [kind, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind};
  @override
  CachedSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSnapshot(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedSnapshotsTable createAlias(String alias) {
    return $CachedSnapshotsTable(attachedDatabase, alias);
  }
}

class CachedSnapshot extends DataClass implements Insertable<CachedSnapshot> {
  final String kind;
  final DateTime cachedAt;
  const CachedSnapshot({required this.kind, required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return CachedSnapshotsCompanion(
      kind: Value(kind),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSnapshot(
      kind: serializer.fromJson<String>(json['kind']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedSnapshot copyWith({String? kind, DateTime? cachedAt}) => CachedSnapshot(
    kind: kind ?? this.kind,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedSnapshot copyWithCompanion(CachedSnapshotsCompanion data) {
    return CachedSnapshot(
      kind: data.kind.present ? data.kind.value : this.kind,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSnapshot(')
          ..write('kind: $kind, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSnapshot &&
          other.kind == this.kind &&
          other.cachedAt == this.cachedAt);
}

class CachedSnapshotsCompanion extends UpdateCompanion<CachedSnapshot> {
  final Value<String> kind;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedSnapshotsCompanion({
    this.kind = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSnapshotsCompanion.insert({
    required String kind,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       cachedAt = Value(cachedAt);
  static Insertable<CachedSnapshot> custom({
    Expression<String>? kind,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSnapshotsCompanion copyWith({
    Value<String>? kind,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedSnapshotsCompanion(
      kind: kind ?? this.kind,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSnapshotsCompanion(')
          ..write('kind: $kind, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedProfilesTable extends CachedProfiles
    with TableInfo<$CachedProfilesTable, CachedProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _signedInEmailMeta = const VerificationMeta(
    'signedInEmail',
  );
  @override
  late final GeneratedColumn<String> signedInEmail = GeneratedColumn<String>(
    'signed_in_email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedStudentNameMeta = const VerificationMeta(
    'linkedStudentName',
  );
  @override
  late final GeneratedColumn<String> linkedStudentName =
      GeneratedColumn<String>(
        'linked_student_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    signedInEmail,
    status,
    userId,
    role,
    name,
    email,
    linkedStudentName,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('signed_in_email')) {
      context.handle(
        _signedInEmailMeta,
        signedInEmail.isAcceptableOrUnknown(
          data['signed_in_email']!,
          _signedInEmailMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_signedInEmailMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('linked_student_name')) {
      context.handle(
        _linkedStudentNameMeta,
        linkedStudentName.isAcceptableOrUnknown(
          data['linked_student_name']!,
          _linkedStudentNameMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {signedInEmail};
  @override
  CachedProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProfile(
      signedInEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signed_in_email'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      linkedStudentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_student_name'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedProfilesTable createAlias(String alias) {
    return $CachedProfilesTable(attachedDatabase, alias);
  }
}

class CachedProfile extends DataClass implements Insertable<CachedProfile> {
  final String signedInEmail;
  final String status;
  final int? userId;
  final String? role;
  final String? name;
  final String? email;
  final String? linkedStudentName;
  final DateTime cachedAt;
  const CachedProfile({
    required this.signedInEmail,
    required this.status,
    this.userId,
    this.role,
    this.name,
    this.email,
    this.linkedStudentName,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['signed_in_email'] = Variable<String>(signedInEmail);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    if (!nullToAbsent || role != null) {
      map['role'] = Variable<String>(role);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || linkedStudentName != null) {
      map['linked_student_name'] = Variable<String>(linkedStudentName);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedProfilesCompanion toCompanion(bool nullToAbsent) {
    return CachedProfilesCompanion(
      signedInEmail: Value(signedInEmail),
      status: Value(status),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      linkedStudentName: linkedStudentName == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedStudentName),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedProfile(
      signedInEmail: serializer.fromJson<String>(json['signedInEmail']),
      status: serializer.fromJson<String>(json['status']),
      userId: serializer.fromJson<int?>(json['userId']),
      role: serializer.fromJson<String?>(json['role']),
      name: serializer.fromJson<String?>(json['name']),
      email: serializer.fromJson<String?>(json['email']),
      linkedStudentName: serializer.fromJson<String?>(
        json['linkedStudentName'],
      ),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'signedInEmail': serializer.toJson<String>(signedInEmail),
      'status': serializer.toJson<String>(status),
      'userId': serializer.toJson<int?>(userId),
      'role': serializer.toJson<String?>(role),
      'name': serializer.toJson<String?>(name),
      'email': serializer.toJson<String?>(email),
      'linkedStudentName': serializer.toJson<String?>(linkedStudentName),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedProfile copyWith({
    String? signedInEmail,
    String? status,
    Value<int?> userId = const Value.absent(),
    Value<String?> role = const Value.absent(),
    Value<String?> name = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> linkedStudentName = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedProfile(
    signedInEmail: signedInEmail ?? this.signedInEmail,
    status: status ?? this.status,
    userId: userId.present ? userId.value : this.userId,
    role: role.present ? role.value : this.role,
    name: name.present ? name.value : this.name,
    email: email.present ? email.value : this.email,
    linkedStudentName: linkedStudentName.present
        ? linkedStudentName.value
        : this.linkedStudentName,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedProfile copyWithCompanion(CachedProfilesCompanion data) {
    return CachedProfile(
      signedInEmail: data.signedInEmail.present
          ? data.signedInEmail.value
          : this.signedInEmail,
      status: data.status.present ? data.status.value : this.status,
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      linkedStudentName: data.linkedStudentName.present
          ? data.linkedStudentName.value
          : this.linkedStudentName,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedProfile(')
          ..write('signedInEmail: $signedInEmail, ')
          ..write('status: $status, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('linkedStudentName: $linkedStudentName, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    signedInEmail,
    status,
    userId,
    role,
    name,
    email,
    linkedStudentName,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedProfile &&
          other.signedInEmail == this.signedInEmail &&
          other.status == this.status &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.name == this.name &&
          other.email == this.email &&
          other.linkedStudentName == this.linkedStudentName &&
          other.cachedAt == this.cachedAt);
}

class CachedProfilesCompanion extends UpdateCompanion<CachedProfile> {
  final Value<String> signedInEmail;
  final Value<String> status;
  final Value<int?> userId;
  final Value<String?> role;
  final Value<String?> name;
  final Value<String?> email;
  final Value<String?> linkedStudentName;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedProfilesCompanion({
    this.signedInEmail = const Value.absent(),
    this.status = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.linkedStudentName = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedProfilesCompanion.insert({
    required String signedInEmail,
    required String status,
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.linkedStudentName = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : signedInEmail = Value(signedInEmail),
       status = Value(status),
       cachedAt = Value(cachedAt);
  static Insertable<CachedProfile> custom({
    Expression<String>? signedInEmail,
    Expression<String>? status,
    Expression<int>? userId,
    Expression<String>? role,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? linkedStudentName,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (signedInEmail != null) 'signed_in_email': signedInEmail,
      if (status != null) 'status': status,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (linkedStudentName != null) 'linked_student_name': linkedStudentName,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedProfilesCompanion copyWith({
    Value<String>? signedInEmail,
    Value<String>? status,
    Value<int?>? userId,
    Value<String?>? role,
    Value<String?>? name,
    Value<String?>? email,
    Value<String?>? linkedStudentName,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedProfilesCompanion(
      signedInEmail: signedInEmail ?? this.signedInEmail,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      linkedStudentName: linkedStudentName ?? this.linkedStudentName,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (signedInEmail.present) {
      map['signed_in_email'] = Variable<String>(signedInEmail.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (linkedStudentName.present) {
      map['linked_student_name'] = Variable<String>(linkedStudentName.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedProfilesCompanion(')
          ..write('signedInEmail: $signedInEmail, ')
          ..write('status: $status, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('linkedStudentName: $linkedStudentName, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedClassesTable extends CachedClasses
    with TableInfo<$CachedClassesTable, CachedClassesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedClassesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeLevelMeta = const VerificationMeta(
    'gradeLevel',
  );
  @override
  late final GeneratedColumn<int> gradeLevel = GeneratedColumn<int>(
    'grade_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectsJsonMeta = const VerificationMeta(
    'subjectsJson',
  );
  @override
  late final GeneratedColumn<String> subjectsJson = GeneratedColumn<String>(
    'subjects_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studentCountMeta = const VerificationMeta(
    'studentCount',
  );
  @override
  late final GeneratedColumn<int> studentCount = GeneratedColumn<int>(
    'student_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    gradeLevel,
    subjectsJson,
    studentCount,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_classes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedClassesData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('grade_level')) {
      context.handle(
        _gradeLevelMeta,
        gradeLevel.isAcceptableOrUnknown(data['grade_level']!, _gradeLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeLevelMeta);
    }
    if (data.containsKey('subjects_json')) {
      context.handle(
        _subjectsJsonMeta,
        subjectsJson.isAcceptableOrUnknown(
          data['subjects_json']!,
          _subjectsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subjectsJsonMeta);
    }
    if (data.containsKey('student_count')) {
      context.handle(
        _studentCountMeta,
        studentCount.isAcceptableOrUnknown(
          data['student_count']!,
          _studentCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studentCountMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedClassesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedClassesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      gradeLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade_level'],
      )!,
      subjectsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subjects_json'],
      )!,
      studentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student_count'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CachedClassesTable createAlias(String alias) {
    return $CachedClassesTable(attachedDatabase, alias);
  }
}

class CachedClassesData extends DataClass
    implements Insertable<CachedClassesData> {
  final int id;
  final String name;
  final int gradeLevel;
  final String subjectsJson;
  final int studentCount;
  final int position;
  const CachedClassesData({
    required this.id,
    required this.name,
    required this.gradeLevel,
    required this.subjectsJson,
    required this.studentCount,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['grade_level'] = Variable<int>(gradeLevel);
    map['subjects_json'] = Variable<String>(subjectsJson);
    map['student_count'] = Variable<int>(studentCount);
    map['position'] = Variable<int>(position);
    return map;
  }

  CachedClassesCompanion toCompanion(bool nullToAbsent) {
    return CachedClassesCompanion(
      id: Value(id),
      name: Value(name),
      gradeLevel: Value(gradeLevel),
      subjectsJson: Value(subjectsJson),
      studentCount: Value(studentCount),
      position: Value(position),
    );
  }

  factory CachedClassesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedClassesData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      gradeLevel: serializer.fromJson<int>(json['gradeLevel']),
      subjectsJson: serializer.fromJson<String>(json['subjectsJson']),
      studentCount: serializer.fromJson<int>(json['studentCount']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'gradeLevel': serializer.toJson<int>(gradeLevel),
      'subjectsJson': serializer.toJson<String>(subjectsJson),
      'studentCount': serializer.toJson<int>(studentCount),
      'position': serializer.toJson<int>(position),
    };
  }

  CachedClassesData copyWith({
    int? id,
    String? name,
    int? gradeLevel,
    String? subjectsJson,
    int? studentCount,
    int? position,
  }) => CachedClassesData(
    id: id ?? this.id,
    name: name ?? this.name,
    gradeLevel: gradeLevel ?? this.gradeLevel,
    subjectsJson: subjectsJson ?? this.subjectsJson,
    studentCount: studentCount ?? this.studentCount,
    position: position ?? this.position,
  );
  CachedClassesData copyWithCompanion(CachedClassesCompanion data) {
    return CachedClassesData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      gradeLevel: data.gradeLevel.present
          ? data.gradeLevel.value
          : this.gradeLevel,
      subjectsJson: data.subjectsJson.present
          ? data.subjectsJson.value
          : this.subjectsJson,
      studentCount: data.studentCount.present
          ? data.studentCount.value
          : this.studentCount,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedClassesData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gradeLevel: $gradeLevel, ')
          ..write('subjectsJson: $subjectsJson, ')
          ..write('studentCount: $studentCount, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, gradeLevel, subjectsJson, studentCount, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedClassesData &&
          other.id == this.id &&
          other.name == this.name &&
          other.gradeLevel == this.gradeLevel &&
          other.subjectsJson == this.subjectsJson &&
          other.studentCount == this.studentCount &&
          other.position == this.position);
}

class CachedClassesCompanion extends UpdateCompanion<CachedClassesData> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> gradeLevel;
  final Value<String> subjectsJson;
  final Value<int> studentCount;
  final Value<int> position;
  const CachedClassesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.gradeLevel = const Value.absent(),
    this.subjectsJson = const Value.absent(),
    this.studentCount = const Value.absent(),
    this.position = const Value.absent(),
  });
  CachedClassesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int gradeLevel,
    required String subjectsJson,
    required int studentCount,
    required int position,
  }) : name = Value(name),
       gradeLevel = Value(gradeLevel),
       subjectsJson = Value(subjectsJson),
       studentCount = Value(studentCount),
       position = Value(position);
  static Insertable<CachedClassesData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? gradeLevel,
    Expression<String>? subjectsJson,
    Expression<int>? studentCount,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (gradeLevel != null) 'grade_level': gradeLevel,
      if (subjectsJson != null) 'subjects_json': subjectsJson,
      if (studentCount != null) 'student_count': studentCount,
      if (position != null) 'position': position,
    });
  }

  CachedClassesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? gradeLevel,
    Value<String>? subjectsJson,
    Value<int>? studentCount,
    Value<int>? position,
  }) {
    return CachedClassesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      subjectsJson: subjectsJson ?? this.subjectsJson,
      studentCount: studentCount ?? this.studentCount,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (gradeLevel.present) {
      map['grade_level'] = Variable<int>(gradeLevel.value);
    }
    if (subjectsJson.present) {
      map['subjects_json'] = Variable<String>(subjectsJson.value);
    }
    if (studentCount.present) {
      map['student_count'] = Variable<int>(studentCount.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedClassesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gradeLevel: $gradeLevel, ')
          ..write('subjectsJson: $subjectsJson, ')
          ..write('studentCount: $studentCount, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $CachedLibraryClassesTable extends CachedLibraryClasses
    with TableInfo<$CachedLibraryClassesTable, CachedLibraryClassesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedLibraryClassesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeLevelMeta = const VerificationMeta(
    'gradeLevel',
  );
  @override
  late final GeneratedColumn<int> gradeLevel = GeneratedColumn<int>(
    'grade_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectsJsonMeta = const VerificationMeta(
    'subjectsJson',
  );
  @override
  late final GeneratedColumn<String> subjectsJson = GeneratedColumn<String>(
    'subjects_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    gradeLevel,
    subjectsJson,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_library_classes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedLibraryClassesData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('grade_level')) {
      context.handle(
        _gradeLevelMeta,
        gradeLevel.isAcceptableOrUnknown(data['grade_level']!, _gradeLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeLevelMeta);
    }
    if (data.containsKey('subjects_json')) {
      context.handle(
        _subjectsJsonMeta,
        subjectsJson.isAcceptableOrUnknown(
          data['subjects_json']!,
          _subjectsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subjectsJsonMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedLibraryClassesData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedLibraryClassesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      gradeLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade_level'],
      )!,
      subjectsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subjects_json'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CachedLibraryClassesTable createAlias(String alias) {
    return $CachedLibraryClassesTable(attachedDatabase, alias);
  }
}

class CachedLibraryClassesData extends DataClass
    implements Insertable<CachedLibraryClassesData> {
  final int id;
  final String name;
  final int gradeLevel;
  final String subjectsJson;
  final int position;
  const CachedLibraryClassesData({
    required this.id,
    required this.name,
    required this.gradeLevel,
    required this.subjectsJson,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['grade_level'] = Variable<int>(gradeLevel);
    map['subjects_json'] = Variable<String>(subjectsJson);
    map['position'] = Variable<int>(position);
    return map;
  }

  CachedLibraryClassesCompanion toCompanion(bool nullToAbsent) {
    return CachedLibraryClassesCompanion(
      id: Value(id),
      name: Value(name),
      gradeLevel: Value(gradeLevel),
      subjectsJson: Value(subjectsJson),
      position: Value(position),
    );
  }

  factory CachedLibraryClassesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedLibraryClassesData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      gradeLevel: serializer.fromJson<int>(json['gradeLevel']),
      subjectsJson: serializer.fromJson<String>(json['subjectsJson']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'gradeLevel': serializer.toJson<int>(gradeLevel),
      'subjectsJson': serializer.toJson<String>(subjectsJson),
      'position': serializer.toJson<int>(position),
    };
  }

  CachedLibraryClassesData copyWith({
    int? id,
    String? name,
    int? gradeLevel,
    String? subjectsJson,
    int? position,
  }) => CachedLibraryClassesData(
    id: id ?? this.id,
    name: name ?? this.name,
    gradeLevel: gradeLevel ?? this.gradeLevel,
    subjectsJson: subjectsJson ?? this.subjectsJson,
    position: position ?? this.position,
  );
  CachedLibraryClassesData copyWithCompanion(
    CachedLibraryClassesCompanion data,
  ) {
    return CachedLibraryClassesData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      gradeLevel: data.gradeLevel.present
          ? data.gradeLevel.value
          : this.gradeLevel,
      subjectsJson: data.subjectsJson.present
          ? data.subjectsJson.value
          : this.subjectsJson,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedLibraryClassesData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gradeLevel: $gradeLevel, ')
          ..write('subjectsJson: $subjectsJson, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, gradeLevel, subjectsJson, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedLibraryClassesData &&
          other.id == this.id &&
          other.name == this.name &&
          other.gradeLevel == this.gradeLevel &&
          other.subjectsJson == this.subjectsJson &&
          other.position == this.position);
}

class CachedLibraryClassesCompanion
    extends UpdateCompanion<CachedLibraryClassesData> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> gradeLevel;
  final Value<String> subjectsJson;
  final Value<int> position;
  const CachedLibraryClassesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.gradeLevel = const Value.absent(),
    this.subjectsJson = const Value.absent(),
    this.position = const Value.absent(),
  });
  CachedLibraryClassesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int gradeLevel,
    required String subjectsJson,
    required int position,
  }) : name = Value(name),
       gradeLevel = Value(gradeLevel),
       subjectsJson = Value(subjectsJson),
       position = Value(position);
  static Insertable<CachedLibraryClassesData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? gradeLevel,
    Expression<String>? subjectsJson,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (gradeLevel != null) 'grade_level': gradeLevel,
      if (subjectsJson != null) 'subjects_json': subjectsJson,
      if (position != null) 'position': position,
    });
  }

  CachedLibraryClassesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? gradeLevel,
    Value<String>? subjectsJson,
    Value<int>? position,
  }) {
    return CachedLibraryClassesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      subjectsJson: subjectsJson ?? this.subjectsJson,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (gradeLevel.present) {
      map['grade_level'] = Variable<int>(gradeLevel.value);
    }
    if (subjectsJson.present) {
      map['subjects_json'] = Variable<String>(subjectsJson.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedLibraryClassesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gradeLevel: $gradeLevel, ')
          ..write('subjectsJson: $subjectsJson, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $CachedLibraryItemsTable extends CachedLibraryItems
    with TableInfo<$CachedLibraryItemsTable, CachedLibraryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedLibraryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeLevelMeta = const VerificationMeta(
    'gradeLevel',
  );
  @override
  late final GeneratedColumn<int> gradeLevel = GeneratedColumn<int>(
    'grade_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    title,
    subject,
    gradeLevel,
    createdAt,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_library_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedLibraryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('grade_level')) {
      context.handle(
        _gradeLevelMeta,
        gradeLevel.isAcceptableOrUnknown(data['grade_level']!, _gradeLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeLevelMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedLibraryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedLibraryItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      gradeLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade_level'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CachedLibraryItemsTable createAlias(String alias) {
    return $CachedLibraryItemsTable(attachedDatabase, alias);
  }
}

class CachedLibraryItem extends DataClass
    implements Insertable<CachedLibraryItem> {
  final int id;
  final String type;
  final String title;
  final String subject;
  final int gradeLevel;
  final DateTime createdAt;
  final int position;
  const CachedLibraryItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.createdAt,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['subject'] = Variable<String>(subject);
    map['grade_level'] = Variable<int>(gradeLevel);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['position'] = Variable<int>(position);
    return map;
  }

  CachedLibraryItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedLibraryItemsCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      subject: Value(subject),
      gradeLevel: Value(gradeLevel),
      createdAt: Value(createdAt),
      position: Value(position),
    );
  }

  factory CachedLibraryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedLibraryItem(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      subject: serializer.fromJson<String>(json['subject']),
      gradeLevel: serializer.fromJson<int>(json['gradeLevel']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'subject': serializer.toJson<String>(subject),
      'gradeLevel': serializer.toJson<int>(gradeLevel),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'position': serializer.toJson<int>(position),
    };
  }

  CachedLibraryItem copyWith({
    int? id,
    String? type,
    String? title,
    String? subject,
    int? gradeLevel,
    DateTime? createdAt,
    int? position,
  }) => CachedLibraryItem(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    subject: subject ?? this.subject,
    gradeLevel: gradeLevel ?? this.gradeLevel,
    createdAt: createdAt ?? this.createdAt,
    position: position ?? this.position,
  );
  CachedLibraryItem copyWithCompanion(CachedLibraryItemsCompanion data) {
    return CachedLibraryItem(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      subject: data.subject.present ? data.subject.value : this.subject,
      gradeLevel: data.gradeLevel.present
          ? data.gradeLevel.value
          : this.gradeLevel,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedLibraryItem(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('gradeLevel: $gradeLevel, ')
          ..write('createdAt: $createdAt, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, title, subject, gradeLevel, createdAt, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedLibraryItem &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.subject == this.subject &&
          other.gradeLevel == this.gradeLevel &&
          other.createdAt == this.createdAt &&
          other.position == this.position);
}

class CachedLibraryItemsCompanion extends UpdateCompanion<CachedLibraryItem> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> title;
  final Value<String> subject;
  final Value<int> gradeLevel;
  final Value<DateTime> createdAt;
  final Value<int> position;
  const CachedLibraryItemsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.subject = const Value.absent(),
    this.gradeLevel = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.position = const Value.absent(),
  });
  CachedLibraryItemsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String title,
    required String subject,
    required int gradeLevel,
    required DateTime createdAt,
    required int position,
  }) : type = Value(type),
       title = Value(title),
       subject = Value(subject),
       gradeLevel = Value(gradeLevel),
       createdAt = Value(createdAt),
       position = Value(position);
  static Insertable<CachedLibraryItem> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? subject,
    Expression<int>? gradeLevel,
    Expression<DateTime>? createdAt,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (subject != null) 'subject': subject,
      if (gradeLevel != null) 'grade_level': gradeLevel,
      if (createdAt != null) 'created_at': createdAt,
      if (position != null) 'position': position,
    });
  }

  CachedLibraryItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String>? title,
    Value<String>? subject,
    Value<int>? gradeLevel,
    Value<DateTime>? createdAt,
    Value<int>? position,
  }) {
    return CachedLibraryItemsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      createdAt: createdAt ?? this.createdAt,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (gradeLevel.present) {
      map['grade_level'] = Variable<int>(gradeLevel.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedLibraryItemsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('gradeLevel: $gradeLevel, ')
          ..write('createdAt: $createdAt, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $CachedParentHomesTable extends CachedParentHomes
    with TableInfo<$CachedParentHomesTable, CachedParentHome> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedParentHomesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _linkedStudentNameMeta = const VerificationMeta(
    'linkedStudentName',
  );
  @override
  late final GeneratedColumn<String> linkedStudentName =
      GeneratedColumn<String>(
        'linked_student_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, linkedStudentName, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_parent_homes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedParentHome> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('linked_student_name')) {
      context.handle(
        _linkedStudentNameMeta,
        linkedStudentName.isAcceptableOrUnknown(
          data['linked_student_name']!,
          _linkedStudentNameMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedParentHome map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedParentHome(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      linkedStudentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_student_name'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedParentHomesTable createAlias(String alias) {
    return $CachedParentHomesTable(attachedDatabase, alias);
  }
}

class CachedParentHome extends DataClass
    implements Insertable<CachedParentHome> {
  final int id;
  final String? linkedStudentName;
  final DateTime cachedAt;
  const CachedParentHome({
    required this.id,
    this.linkedStudentName,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || linkedStudentName != null) {
      map['linked_student_name'] = Variable<String>(linkedStudentName);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedParentHomesCompanion toCompanion(bool nullToAbsent) {
    return CachedParentHomesCompanion(
      id: Value(id),
      linkedStudentName: linkedStudentName == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedStudentName),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedParentHome.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedParentHome(
      id: serializer.fromJson<int>(json['id']),
      linkedStudentName: serializer.fromJson<String?>(
        json['linkedStudentName'],
      ),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'linkedStudentName': serializer.toJson<String?>(linkedStudentName),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedParentHome copyWith({
    int? id,
    Value<String?> linkedStudentName = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedParentHome(
    id: id ?? this.id,
    linkedStudentName: linkedStudentName.present
        ? linkedStudentName.value
        : this.linkedStudentName,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedParentHome copyWithCompanion(CachedParentHomesCompanion data) {
    return CachedParentHome(
      id: data.id.present ? data.id.value : this.id,
      linkedStudentName: data.linkedStudentName.present
          ? data.linkedStudentName.value
          : this.linkedStudentName,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedParentHome(')
          ..write('id: $id, ')
          ..write('linkedStudentName: $linkedStudentName, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, linkedStudentName, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedParentHome &&
          other.id == this.id &&
          other.linkedStudentName == this.linkedStudentName &&
          other.cachedAt == this.cachedAt);
}

class CachedParentHomesCompanion extends UpdateCompanion<CachedParentHome> {
  final Value<int> id;
  final Value<String?> linkedStudentName;
  final Value<DateTime> cachedAt;
  const CachedParentHomesCompanion({
    this.id = const Value.absent(),
    this.linkedStudentName = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedParentHomesCompanion.insert({
    this.id = const Value.absent(),
    this.linkedStudentName = const Value.absent(),
    required DateTime cachedAt,
  }) : cachedAt = Value(cachedAt);
  static Insertable<CachedParentHome> custom({
    Expression<int>? id,
    Expression<String>? linkedStudentName,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (linkedStudentName != null) 'linked_student_name': linkedStudentName,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedParentHomesCompanion copyWith({
    Value<int>? id,
    Value<String?>? linkedStudentName,
    Value<DateTime>? cachedAt,
  }) {
    return CachedParentHomesCompanion(
      id: id ?? this.id,
      linkedStudentName: linkedStudentName ?? this.linkedStudentName,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (linkedStudentName.present) {
      map['linked_student_name'] = Variable<String>(linkedStudentName.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedParentHomesCompanion(')
          ..write('id: $id, ')
          ..write('linkedStudentName: $linkedStudentName, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $OutboxEntriesTable extends OutboxEntries
    with TableInfo<$OutboxEntriesTable, OutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operation,
    payloadJson,
    createdAt,
    state,
    attempts,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $OutboxEntriesTable createAlias(String alias) {
    return $OutboxEntriesTable(attachedDatabase, alias);
  }
}

class OutboxEntry extends DataClass implements Insertable<OutboxEntry> {
  final int id;
  final String operation;
  final String payloadJson;
  final DateTime createdAt;
  final String state;
  final int attempts;
  final String? lastError;
  const OutboxEntry({
    required this.id,
    required this.operation,
    required this.payloadJson,
    required this.createdAt,
    required this.state,
    required this.attempts,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['state'] = Variable<String>(state);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  OutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return OutboxEntriesCompanion(
      id: Value(id),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      state: Value(state),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory OutboxEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEntry(
      id: serializer.fromJson<int>(json['id']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      state: serializer.fromJson<String>(json['state']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'state': serializer.toJson<String>(state),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  OutboxEntry copyWith({
    int? id,
    String? operation,
    String? payloadJson,
    DateTime? createdAt,
    String? state,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
  }) => OutboxEntry(
    id: id ?? this.id,
    operation: operation ?? this.operation,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  OutboxEntry copyWithCompanion(OutboxEntriesCompanion data) {
    return OutboxEntry(
      id: data.id.present ? data.id.value : this.id,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      state: data.state.present ? data.state.value : this.state,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntry(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operation,
    payloadJson,
    createdAt,
    state,
    attempts,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEntry &&
          other.id == this.id &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.state == this.state &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class OutboxEntriesCompanion extends UpdateCompanion<OutboxEntry> {
  final Value<int> id;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<String> state;
  final Value<int> attempts;
  final Value<String?> lastError;
  const OutboxEntriesCompanion({
    this.id = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  OutboxEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String operation,
    required String payloadJson,
    required DateTime createdAt,
    required String state,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : operation = Value(operation),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt),
       state = Value(state);
  static Insertable<OutboxEntry> custom({
    Expression<int>? id,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<String>? state,
    Expression<int>? attempts,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (state != null) 'state': state,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
    });
  }

  OutboxEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? operation,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
    Value<String>? state,
    Value<int>? attempts,
    Value<String?>? lastError,
  }) {
    return OutboxEntriesCompanion(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      state: state ?? this.state,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntriesCompanion(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

abstract class _$EduBoxDatabase extends GeneratedDatabase {
  _$EduBoxDatabase(QueryExecutor e) : super(e);
  $EduBoxDatabaseManager get managers => $EduBoxDatabaseManager(this);
  late final $CachedSnapshotsTable cachedSnapshots = $CachedSnapshotsTable(
    this,
  );
  late final $CachedProfilesTable cachedProfiles = $CachedProfilesTable(this);
  late final $CachedClassesTable cachedClasses = $CachedClassesTable(this);
  late final $CachedLibraryClassesTable cachedLibraryClasses =
      $CachedLibraryClassesTable(this);
  late final $CachedLibraryItemsTable cachedLibraryItems =
      $CachedLibraryItemsTable(this);
  late final $CachedParentHomesTable cachedParentHomes =
      $CachedParentHomesTable(this);
  late final $OutboxEntriesTable outboxEntries = $OutboxEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedSnapshots,
    cachedProfiles,
    cachedClasses,
    cachedLibraryClasses,
    cachedLibraryItems,
    cachedParentHomes,
    outboxEntries,
  ];
}

typedef $$CachedSnapshotsTableCreateCompanionBuilder =
    CachedSnapshotsCompanion Function({
      required String kind,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedSnapshotsTableUpdateCompanionBuilder =
    CachedSnapshotsCompanion Function({
      Value<String> kind,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedSnapshotsTableFilterComposer
    extends Composer<_$EduBoxDatabase, $CachedSnapshotsTable> {
  $$CachedSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedSnapshotsTableOrderingComposer
    extends Composer<_$EduBoxDatabase, $CachedSnapshotsTable> {
  $$CachedSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedSnapshotsTableAnnotationComposer
    extends Composer<_$EduBoxDatabase, $CachedSnapshotsTable> {
  $$CachedSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedSnapshotsTableTableManager
    extends
        RootTableManager<
          _$EduBoxDatabase,
          $CachedSnapshotsTable,
          CachedSnapshot,
          $$CachedSnapshotsTableFilterComposer,
          $$CachedSnapshotsTableOrderingComposer,
          $$CachedSnapshotsTableAnnotationComposer,
          $$CachedSnapshotsTableCreateCompanionBuilder,
          $$CachedSnapshotsTableUpdateCompanionBuilder,
          (
            CachedSnapshot,
            BaseReferences<
              _$EduBoxDatabase,
              $CachedSnapshotsTable,
              CachedSnapshot
            >,
          ),
          CachedSnapshot,
          PrefetchHooks Function()
        > {
  $$CachedSnapshotsTableTableManager(
    _$EduBoxDatabase db,
    $CachedSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSnapshotsCompanion(
                kind: kind,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedSnapshotsCompanion.insert(
                kind: kind,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$EduBoxDatabase,
      $CachedSnapshotsTable,
      CachedSnapshot,
      $$CachedSnapshotsTableFilterComposer,
      $$CachedSnapshotsTableOrderingComposer,
      $$CachedSnapshotsTableAnnotationComposer,
      $$CachedSnapshotsTableCreateCompanionBuilder,
      $$CachedSnapshotsTableUpdateCompanionBuilder,
      (
        CachedSnapshot,
        BaseReferences<_$EduBoxDatabase, $CachedSnapshotsTable, CachedSnapshot>,
      ),
      CachedSnapshot,
      PrefetchHooks Function()
    >;
typedef $$CachedProfilesTableCreateCompanionBuilder =
    CachedProfilesCompanion Function({
      required String signedInEmail,
      required String status,
      Value<int?> userId,
      Value<String?> role,
      Value<String?> name,
      Value<String?> email,
      Value<String?> linkedStudentName,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedProfilesTableUpdateCompanionBuilder =
    CachedProfilesCompanion Function({
      Value<String> signedInEmail,
      Value<String> status,
      Value<int?> userId,
      Value<String?> role,
      Value<String?> name,
      Value<String?> email,
      Value<String?> linkedStudentName,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedProfilesTableFilterComposer
    extends Composer<_$EduBoxDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get signedInEmail => $composableBuilder(
    column: $table.signedInEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedStudentName => $composableBuilder(
    column: $table.linkedStudentName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedProfilesTableOrderingComposer
    extends Composer<_$EduBoxDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get signedInEmail => $composableBuilder(
    column: $table.signedInEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedStudentName => $composableBuilder(
    column: $table.linkedStudentName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedProfilesTableAnnotationComposer
    extends Composer<_$EduBoxDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get signedInEmail => $composableBuilder(
    column: $table.signedInEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get linkedStudentName => $composableBuilder(
    column: $table.linkedStudentName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedProfilesTableTableManager
    extends
        RootTableManager<
          _$EduBoxDatabase,
          $CachedProfilesTable,
          CachedProfile,
          $$CachedProfilesTableFilterComposer,
          $$CachedProfilesTableOrderingComposer,
          $$CachedProfilesTableAnnotationComposer,
          $$CachedProfilesTableCreateCompanionBuilder,
          $$CachedProfilesTableUpdateCompanionBuilder,
          (
            CachedProfile,
            BaseReferences<
              _$EduBoxDatabase,
              $CachedProfilesTable,
              CachedProfile
            >,
          ),
          CachedProfile,
          PrefetchHooks Function()
        > {
  $$CachedProfilesTableTableManager(
    _$EduBoxDatabase db,
    $CachedProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> signedInEmail = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> linkedStudentName = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedProfilesCompanion(
                signedInEmail: signedInEmail,
                status: status,
                userId: userId,
                role: role,
                name: name,
                email: email,
                linkedStudentName: linkedStudentName,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String signedInEmail,
                required String status,
                Value<int?> userId = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> linkedStudentName = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedProfilesCompanion.insert(
                signedInEmail: signedInEmail,
                status: status,
                userId: userId,
                role: role,
                name: name,
                email: email,
                linkedStudentName: linkedStudentName,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$EduBoxDatabase,
      $CachedProfilesTable,
      CachedProfile,
      $$CachedProfilesTableFilterComposer,
      $$CachedProfilesTableOrderingComposer,
      $$CachedProfilesTableAnnotationComposer,
      $$CachedProfilesTableCreateCompanionBuilder,
      $$CachedProfilesTableUpdateCompanionBuilder,
      (
        CachedProfile,
        BaseReferences<_$EduBoxDatabase, $CachedProfilesTable, CachedProfile>,
      ),
      CachedProfile,
      PrefetchHooks Function()
    >;
typedef $$CachedClassesTableCreateCompanionBuilder =
    CachedClassesCompanion Function({
      Value<int> id,
      required String name,
      required int gradeLevel,
      required String subjectsJson,
      required int studentCount,
      required int position,
    });
typedef $$CachedClassesTableUpdateCompanionBuilder =
    CachedClassesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> gradeLevel,
      Value<String> subjectsJson,
      Value<int> studentCount,
      Value<int> position,
    });

class $$CachedClassesTableFilterComposer
    extends Composer<_$EduBoxDatabase, $CachedClassesTable> {
  $$CachedClassesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectsJson => $composableBuilder(
    column: $table.subjectsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get studentCount => $composableBuilder(
    column: $table.studentCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedClassesTableOrderingComposer
    extends Composer<_$EduBoxDatabase, $CachedClassesTable> {
  $$CachedClassesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectsJson => $composableBuilder(
    column: $table.subjectsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get studentCount => $composableBuilder(
    column: $table.studentCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedClassesTableAnnotationComposer
    extends Composer<_$EduBoxDatabase, $CachedClassesTable> {
  $$CachedClassesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subjectsJson => $composableBuilder(
    column: $table.subjectsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get studentCount => $composableBuilder(
    column: $table.studentCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$CachedClassesTableTableManager
    extends
        RootTableManager<
          _$EduBoxDatabase,
          $CachedClassesTable,
          CachedClassesData,
          $$CachedClassesTableFilterComposer,
          $$CachedClassesTableOrderingComposer,
          $$CachedClassesTableAnnotationComposer,
          $$CachedClassesTableCreateCompanionBuilder,
          $$CachedClassesTableUpdateCompanionBuilder,
          (
            CachedClassesData,
            BaseReferences<
              _$EduBoxDatabase,
              $CachedClassesTable,
              CachedClassesData
            >,
          ),
          CachedClassesData,
          PrefetchHooks Function()
        > {
  $$CachedClassesTableTableManager(
    _$EduBoxDatabase db,
    $CachedClassesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedClassesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedClassesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedClassesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> gradeLevel = const Value.absent(),
                Value<String> subjectsJson = const Value.absent(),
                Value<int> studentCount = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => CachedClassesCompanion(
                id: id,
                name: name,
                gradeLevel: gradeLevel,
                subjectsJson: subjectsJson,
                studentCount: studentCount,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int gradeLevel,
                required String subjectsJson,
                required int studentCount,
                required int position,
              }) => CachedClassesCompanion.insert(
                id: id,
                name: name,
                gradeLevel: gradeLevel,
                subjectsJson: subjectsJson,
                studentCount: studentCount,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedClassesTableProcessedTableManager =
    ProcessedTableManager<
      _$EduBoxDatabase,
      $CachedClassesTable,
      CachedClassesData,
      $$CachedClassesTableFilterComposer,
      $$CachedClassesTableOrderingComposer,
      $$CachedClassesTableAnnotationComposer,
      $$CachedClassesTableCreateCompanionBuilder,
      $$CachedClassesTableUpdateCompanionBuilder,
      (
        CachedClassesData,
        BaseReferences<
          _$EduBoxDatabase,
          $CachedClassesTable,
          CachedClassesData
        >,
      ),
      CachedClassesData,
      PrefetchHooks Function()
    >;
typedef $$CachedLibraryClassesTableCreateCompanionBuilder =
    CachedLibraryClassesCompanion Function({
      Value<int> id,
      required String name,
      required int gradeLevel,
      required String subjectsJson,
      required int position,
    });
typedef $$CachedLibraryClassesTableUpdateCompanionBuilder =
    CachedLibraryClassesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> gradeLevel,
      Value<String> subjectsJson,
      Value<int> position,
    });

class $$CachedLibraryClassesTableFilterComposer
    extends Composer<_$EduBoxDatabase, $CachedLibraryClassesTable> {
  $$CachedLibraryClassesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectsJson => $composableBuilder(
    column: $table.subjectsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedLibraryClassesTableOrderingComposer
    extends Composer<_$EduBoxDatabase, $CachedLibraryClassesTable> {
  $$CachedLibraryClassesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectsJson => $composableBuilder(
    column: $table.subjectsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedLibraryClassesTableAnnotationComposer
    extends Composer<_$EduBoxDatabase, $CachedLibraryClassesTable> {
  $$CachedLibraryClassesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subjectsJson => $composableBuilder(
    column: $table.subjectsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$CachedLibraryClassesTableTableManager
    extends
        RootTableManager<
          _$EduBoxDatabase,
          $CachedLibraryClassesTable,
          CachedLibraryClassesData,
          $$CachedLibraryClassesTableFilterComposer,
          $$CachedLibraryClassesTableOrderingComposer,
          $$CachedLibraryClassesTableAnnotationComposer,
          $$CachedLibraryClassesTableCreateCompanionBuilder,
          $$CachedLibraryClassesTableUpdateCompanionBuilder,
          (
            CachedLibraryClassesData,
            BaseReferences<
              _$EduBoxDatabase,
              $CachedLibraryClassesTable,
              CachedLibraryClassesData
            >,
          ),
          CachedLibraryClassesData,
          PrefetchHooks Function()
        > {
  $$CachedLibraryClassesTableTableManager(
    _$EduBoxDatabase db,
    $CachedLibraryClassesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedLibraryClassesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedLibraryClassesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedLibraryClassesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> gradeLevel = const Value.absent(),
                Value<String> subjectsJson = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => CachedLibraryClassesCompanion(
                id: id,
                name: name,
                gradeLevel: gradeLevel,
                subjectsJson: subjectsJson,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int gradeLevel,
                required String subjectsJson,
                required int position,
              }) => CachedLibraryClassesCompanion.insert(
                id: id,
                name: name,
                gradeLevel: gradeLevel,
                subjectsJson: subjectsJson,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedLibraryClassesTableProcessedTableManager =
    ProcessedTableManager<
      _$EduBoxDatabase,
      $CachedLibraryClassesTable,
      CachedLibraryClassesData,
      $$CachedLibraryClassesTableFilterComposer,
      $$CachedLibraryClassesTableOrderingComposer,
      $$CachedLibraryClassesTableAnnotationComposer,
      $$CachedLibraryClassesTableCreateCompanionBuilder,
      $$CachedLibraryClassesTableUpdateCompanionBuilder,
      (
        CachedLibraryClassesData,
        BaseReferences<
          _$EduBoxDatabase,
          $CachedLibraryClassesTable,
          CachedLibraryClassesData
        >,
      ),
      CachedLibraryClassesData,
      PrefetchHooks Function()
    >;
typedef $$CachedLibraryItemsTableCreateCompanionBuilder =
    CachedLibraryItemsCompanion Function({
      Value<int> id,
      required String type,
      required String title,
      required String subject,
      required int gradeLevel,
      required DateTime createdAt,
      required int position,
    });
typedef $$CachedLibraryItemsTableUpdateCompanionBuilder =
    CachedLibraryItemsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String> title,
      Value<String> subject,
      Value<int> gradeLevel,
      Value<DateTime> createdAt,
      Value<int> position,
    });

class $$CachedLibraryItemsTableFilterComposer
    extends Composer<_$EduBoxDatabase, $CachedLibraryItemsTable> {
  $$CachedLibraryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedLibraryItemsTableOrderingComposer
    extends Composer<_$EduBoxDatabase, $CachedLibraryItemsTable> {
  $$CachedLibraryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedLibraryItemsTableAnnotationComposer
    extends Composer<_$EduBoxDatabase, $CachedLibraryItemsTable> {
  $$CachedLibraryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<int> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$CachedLibraryItemsTableTableManager
    extends
        RootTableManager<
          _$EduBoxDatabase,
          $CachedLibraryItemsTable,
          CachedLibraryItem,
          $$CachedLibraryItemsTableFilterComposer,
          $$CachedLibraryItemsTableOrderingComposer,
          $$CachedLibraryItemsTableAnnotationComposer,
          $$CachedLibraryItemsTableCreateCompanionBuilder,
          $$CachedLibraryItemsTableUpdateCompanionBuilder,
          (
            CachedLibraryItem,
            BaseReferences<
              _$EduBoxDatabase,
              $CachedLibraryItemsTable,
              CachedLibraryItem
            >,
          ),
          CachedLibraryItem,
          PrefetchHooks Function()
        > {
  $$CachedLibraryItemsTableTableManager(
    _$EduBoxDatabase db,
    $CachedLibraryItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedLibraryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedLibraryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedLibraryItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<int> gradeLevel = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => CachedLibraryItemsCompanion(
                id: id,
                type: type,
                title: title,
                subject: subject,
                gradeLevel: gradeLevel,
                createdAt: createdAt,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required String title,
                required String subject,
                required int gradeLevel,
                required DateTime createdAt,
                required int position,
              }) => CachedLibraryItemsCompanion.insert(
                id: id,
                type: type,
                title: title,
                subject: subject,
                gradeLevel: gradeLevel,
                createdAt: createdAt,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedLibraryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$EduBoxDatabase,
      $CachedLibraryItemsTable,
      CachedLibraryItem,
      $$CachedLibraryItemsTableFilterComposer,
      $$CachedLibraryItemsTableOrderingComposer,
      $$CachedLibraryItemsTableAnnotationComposer,
      $$CachedLibraryItemsTableCreateCompanionBuilder,
      $$CachedLibraryItemsTableUpdateCompanionBuilder,
      (
        CachedLibraryItem,
        BaseReferences<
          _$EduBoxDatabase,
          $CachedLibraryItemsTable,
          CachedLibraryItem
        >,
      ),
      CachedLibraryItem,
      PrefetchHooks Function()
    >;
typedef $$CachedParentHomesTableCreateCompanionBuilder =
    CachedParentHomesCompanion Function({
      Value<int> id,
      Value<String?> linkedStudentName,
      required DateTime cachedAt,
    });
typedef $$CachedParentHomesTableUpdateCompanionBuilder =
    CachedParentHomesCompanion Function({
      Value<int> id,
      Value<String?> linkedStudentName,
      Value<DateTime> cachedAt,
    });

class $$CachedParentHomesTableFilterComposer
    extends Composer<_$EduBoxDatabase, $CachedParentHomesTable> {
  $$CachedParentHomesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedStudentName => $composableBuilder(
    column: $table.linkedStudentName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedParentHomesTableOrderingComposer
    extends Composer<_$EduBoxDatabase, $CachedParentHomesTable> {
  $$CachedParentHomesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedStudentName => $composableBuilder(
    column: $table.linkedStudentName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedParentHomesTableAnnotationComposer
    extends Composer<_$EduBoxDatabase, $CachedParentHomesTable> {
  $$CachedParentHomesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get linkedStudentName => $composableBuilder(
    column: $table.linkedStudentName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedParentHomesTableTableManager
    extends
        RootTableManager<
          _$EduBoxDatabase,
          $CachedParentHomesTable,
          CachedParentHome,
          $$CachedParentHomesTableFilterComposer,
          $$CachedParentHomesTableOrderingComposer,
          $$CachedParentHomesTableAnnotationComposer,
          $$CachedParentHomesTableCreateCompanionBuilder,
          $$CachedParentHomesTableUpdateCompanionBuilder,
          (
            CachedParentHome,
            BaseReferences<
              _$EduBoxDatabase,
              $CachedParentHomesTable,
              CachedParentHome
            >,
          ),
          CachedParentHome,
          PrefetchHooks Function()
        > {
  $$CachedParentHomesTableTableManager(
    _$EduBoxDatabase db,
    $CachedParentHomesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedParentHomesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedParentHomesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedParentHomesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> linkedStudentName = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedParentHomesCompanion(
                id: id,
                linkedStudentName: linkedStudentName,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> linkedStudentName = const Value.absent(),
                required DateTime cachedAt,
              }) => CachedParentHomesCompanion.insert(
                id: id,
                linkedStudentName: linkedStudentName,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedParentHomesTableProcessedTableManager =
    ProcessedTableManager<
      _$EduBoxDatabase,
      $CachedParentHomesTable,
      CachedParentHome,
      $$CachedParentHomesTableFilterComposer,
      $$CachedParentHomesTableOrderingComposer,
      $$CachedParentHomesTableAnnotationComposer,
      $$CachedParentHomesTableCreateCompanionBuilder,
      $$CachedParentHomesTableUpdateCompanionBuilder,
      (
        CachedParentHome,
        BaseReferences<
          _$EduBoxDatabase,
          $CachedParentHomesTable,
          CachedParentHome
        >,
      ),
      CachedParentHome,
      PrefetchHooks Function()
    >;
typedef $$OutboxEntriesTableCreateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<int> id,
      required String operation,
      required String payloadJson,
      required DateTime createdAt,
      required String state,
      Value<int> attempts,
      Value<String?> lastError,
    });
typedef $$OutboxEntriesTableUpdateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<int> id,
      Value<String> operation,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
      Value<String> state,
      Value<int> attempts,
      Value<String?> lastError,
    });

class $$OutboxEntriesTableFilterComposer
    extends Composer<_$EduBoxDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxEntriesTableOrderingComposer
    extends Composer<_$EduBoxDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxEntriesTableAnnotationComposer
    extends Composer<_$EduBoxDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$OutboxEntriesTableTableManager
    extends
        RootTableManager<
          _$EduBoxDatabase,
          $OutboxEntriesTable,
          OutboxEntry,
          $$OutboxEntriesTableFilterComposer,
          $$OutboxEntriesTableOrderingComposer,
          $$OutboxEntriesTableAnnotationComposer,
          $$OutboxEntriesTableCreateCompanionBuilder,
          $$OutboxEntriesTableUpdateCompanionBuilder,
          (
            OutboxEntry,
            BaseReferences<_$EduBoxDatabase, $OutboxEntriesTable, OutboxEntry>,
          ),
          OutboxEntry,
          PrefetchHooks Function()
        > {
  $$OutboxEntriesTableTableManager(
    _$EduBoxDatabase db,
    $OutboxEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => OutboxEntriesCompanion(
                id: id,
                operation: operation,
                payloadJson: payloadJson,
                createdAt: createdAt,
                state: state,
                attempts: attempts,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String operation,
                required String payloadJson,
                required DateTime createdAt,
                required String state,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => OutboxEntriesCompanion.insert(
                id: id,
                operation: operation,
                payloadJson: payloadJson,
                createdAt: createdAt,
                state: state,
                attempts: attempts,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$EduBoxDatabase,
      $OutboxEntriesTable,
      OutboxEntry,
      $$OutboxEntriesTableFilterComposer,
      $$OutboxEntriesTableOrderingComposer,
      $$OutboxEntriesTableAnnotationComposer,
      $$OutboxEntriesTableCreateCompanionBuilder,
      $$OutboxEntriesTableUpdateCompanionBuilder,
      (
        OutboxEntry,
        BaseReferences<_$EduBoxDatabase, $OutboxEntriesTable, OutboxEntry>,
      ),
      OutboxEntry,
      PrefetchHooks Function()
    >;

class $EduBoxDatabaseManager {
  final _$EduBoxDatabase _db;
  $EduBoxDatabaseManager(this._db);
  $$CachedSnapshotsTableTableManager get cachedSnapshots =>
      $$CachedSnapshotsTableTableManager(_db, _db.cachedSnapshots);
  $$CachedProfilesTableTableManager get cachedProfiles =>
      $$CachedProfilesTableTableManager(_db, _db.cachedProfiles);
  $$CachedClassesTableTableManager get cachedClasses =>
      $$CachedClassesTableTableManager(_db, _db.cachedClasses);
  $$CachedLibraryClassesTableTableManager get cachedLibraryClasses =>
      $$CachedLibraryClassesTableTableManager(_db, _db.cachedLibraryClasses);
  $$CachedLibraryItemsTableTableManager get cachedLibraryItems =>
      $$CachedLibraryItemsTableTableManager(_db, _db.cachedLibraryItems);
  $$CachedParentHomesTableTableManager get cachedParentHomes =>
      $$CachedParentHomesTableTableManager(_db, _db.cachedParentHomes);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db, _db.outboxEntries);
}
