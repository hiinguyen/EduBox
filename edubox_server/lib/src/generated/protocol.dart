/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:edubox_server/src/generated/dto/class_summary.dart'
    as _ie2k138y;
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'dto/class_summary.dart' as _i1stsozf;
import 'dto/library_item.dart' as _ihvkgxwr;
import 'dto/ping_message.dart' as _iptwwf38;
import 'dto/profile.dart' as _i803mohe;
import 'dto/profile_result.dart' as _iiofgk2r;
import 'dto/student_class.dart' as _iv0apgib;
import 'dto/student_library.dart' as _ie4th1ag;
import 'enums/access_denied_reason.dart' as _ivmxmlsf;
import 'enums/content_status.dart' as _ihs3uvql;
import 'enums/content_type.dart' as _ilnr5g4x;
import 'enums/profile_status.dart' as _i4pxzrse;
import 'enums/user_role.dart' as _iez5w9yk;
import 'exceptions/access_denied_exception.dart' as _iiozc5q0;
import 'tables/class_member.dart' as _izitgulh;
import 'tables/class_subject.dart' as _idq7h264;
import 'tables/content_class.dart' as _ia3wwh2b;
import 'tables/content_record.dart' as _itiewxwm;
import 'tables/edubox_user.dart' as _ivszvoxo;
import 'tables/school_class.dart' as _issv2a3i;
export 'dto/class_summary.dart';
export 'dto/library_item.dart';
export 'dto/ping_message.dart';
export 'dto/profile.dart';
export 'dto/profile_result.dart';
export 'dto/student_class.dart';
export 'dto/student_library.dart';
export 'enums/access_denied_reason.dart';
export 'enums/content_status.dart';
export 'enums/content_type.dart';
export 'enums/profile_status.dart';
export 'enums/user_role.dart';
export 'exceptions/access_denied_exception.dart';
export 'tables/class_member.dart';
export 'tables/class_subject.dart';
export 'tables/content_class.dart';
export 'tables/content_record.dart';
export 'tables/edubox_user.dart';
export 'tables/school_class.dart';

class Protocol extends _is.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'class_members',
      dartName: 'ClassMember',
      schema: 'public',
      module: 'edubox',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'classId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'studentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'class_members_fk_0',
          columns: ['classId'],
          referenceTable: 'classes',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'class_members_fk_1',
          columns: ['studentId'],
          referenceTable: 'users',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'class_members_class_student_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'classId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'studentId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'class_members_student_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'studentId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'class_subjects',
      dartName: 'ClassSubject',
      schema: 'public',
      module: 'edubox',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'classId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'position',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'subject',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'class_subjects_fk_0',
          columns: ['classId'],
          referenceTable: 'classes',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'class_subjects_class_position_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'classId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'position',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'classes',
      dartName: 'SchoolClass',
      schema: 'public',
      module: 'edubox',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'teacherId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'gradeLevel',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'classes_fk_0',
          columns: ['teacherId'],
          referenceTable: 'users',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'classes_teacher_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'teacherId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'content',
      dartName: 'ContentRecord',
      schema: 'public',
      module: 'edubox',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'ownerTeacherId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'type',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ContentType',
        ),
        _isp.ColumnDefinition(
          name: 'subject',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'gradeLevel',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'storagePath',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ContentStatus',
        ),
        _isp.ColumnDefinition(
          name: 'approvedBy',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'content_fk_0',
          columns: ['ownerTeacherId'],
          referenceTable: 'users',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'content_fk_1',
          columns: ['approvedBy'],
          referenceTable: 'users',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'content_status_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'content_classes',
      dartName: 'ContentClass',
      schema: 'public',
      module: 'edubox',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'contentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'classId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'content_classes_fk_0',
          columns: ['contentId'],
          referenceTable: 'content',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'content_classes_fk_1',
          columns: ['classId'],
          referenceTable: 'classes',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'content_classes_content_class_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'contentId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'classId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'content_classes_class_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'classId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'users',
      dartName: 'EduboxUser',
      schema: 'public',
      module: 'edubox',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'authUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'role',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'email',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'linkedStudentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'linkedStudentName',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'users_fk_0',
          columns: ['authUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'users_fk_1',
          columns: ['linkedStudentId'],
          referenceTable: 'users',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'users_auth_user_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._iais.Protocol.targetTableDefinitions,
    ..._iacs.Protocol.targetTableDefinitions,
    ..._isp.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _is.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i1stsozf.ClassSummary) {
      return _i1stsozf.ClassSummary.fromJson(data) as T;
    }
    if (t == _ihvkgxwr.LibraryItem) {
      return _ihvkgxwr.LibraryItem.fromJson(data) as T;
    }
    if (t == _iptwwf38.PingMessage) {
      return _iptwwf38.PingMessage.fromJson(data) as T;
    }
    if (t == _i803mohe.Profile) {
      return _i803mohe.Profile.fromJson(data) as T;
    }
    if (t == _iiofgk2r.ProfileResult) {
      return _iiofgk2r.ProfileResult.fromJson(data) as T;
    }
    if (t == _iv0apgib.StudentClass) {
      return _iv0apgib.StudentClass.fromJson(data) as T;
    }
    if (t == _ie4th1ag.StudentLibrary) {
      return _ie4th1ag.StudentLibrary.fromJson(data) as T;
    }
    if (t == _ivmxmlsf.AccessDeniedReason) {
      return _ivmxmlsf.AccessDeniedReason.fromJson(data) as T;
    }
    if (t == _ihs3uvql.ContentStatus) {
      return _ihs3uvql.ContentStatus.fromJson(data) as T;
    }
    if (t == _ilnr5g4x.ContentType) {
      return _ilnr5g4x.ContentType.fromJson(data) as T;
    }
    if (t == _i4pxzrse.ProfileStatus) {
      return _i4pxzrse.ProfileStatus.fromJson(data) as T;
    }
    if (t == _iez5w9yk.UserRole) {
      return _iez5w9yk.UserRole.fromJson(data) as T;
    }
    if (t == _iiozc5q0.AccessDeniedException) {
      return _iiozc5q0.AccessDeniedException.fromJson(data) as T;
    }
    if (t == _izitgulh.ClassMember) {
      return _izitgulh.ClassMember.fromJson(data) as T;
    }
    if (t == _idq7h264.ClassSubject) {
      return _idq7h264.ClassSubject.fromJson(data) as T;
    }
    if (t == _ia3wwh2b.ContentClass) {
      return _ia3wwh2b.ContentClass.fromJson(data) as T;
    }
    if (t == _itiewxwm.ContentRecord) {
      return _itiewxwm.ContentRecord.fromJson(data) as T;
    }
    if (t == _ivszvoxo.EduboxUser) {
      return _ivszvoxo.EduboxUser.fromJson(data) as T;
    }
    if (t == _issv2a3i.SchoolClass) {
      return _issv2a3i.SchoolClass.fromJson(data) as T;
    }
    if (t == _is.getType<_i1stsozf.ClassSummary?>()) {
      return (data != null ? _i1stsozf.ClassSummary.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ihvkgxwr.LibraryItem?>()) {
      return (data != null ? _ihvkgxwr.LibraryItem.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iptwwf38.PingMessage?>()) {
      return (data != null ? _iptwwf38.PingMessage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i803mohe.Profile?>()) {
      return (data != null ? _i803mohe.Profile.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iiofgk2r.ProfileResult?>()) {
      return (data != null ? _iiofgk2r.ProfileResult.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iv0apgib.StudentClass?>()) {
      return (data != null ? _iv0apgib.StudentClass.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ie4th1ag.StudentLibrary?>()) {
      return (data != null ? _ie4th1ag.StudentLibrary.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ivmxmlsf.AccessDeniedReason?>()) {
      return (data != null ? _ivmxmlsf.AccessDeniedReason.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ihs3uvql.ContentStatus?>()) {
      return (data != null ? _ihs3uvql.ContentStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ilnr5g4x.ContentType?>()) {
      return (data != null ? _ilnr5g4x.ContentType.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i4pxzrse.ProfileStatus?>()) {
      return (data != null ? _i4pxzrse.ProfileStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iez5w9yk.UserRole?>()) {
      return (data != null ? _iez5w9yk.UserRole.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iiozc5q0.AccessDeniedException?>()) {
      return (data != null
              ? _iiozc5q0.AccessDeniedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_izitgulh.ClassMember?>()) {
      return (data != null ? _izitgulh.ClassMember.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_idq7h264.ClassSubject?>()) {
      return (data != null ? _idq7h264.ClassSubject.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ia3wwh2b.ContentClass?>()) {
      return (data != null ? _ia3wwh2b.ContentClass.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_itiewxwm.ContentRecord?>()) {
      return (data != null ? _itiewxwm.ContentRecord.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ivszvoxo.EduboxUser?>()) {
      return (data != null ? _ivszvoxo.EduboxUser.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_issv2a3i.SchoolClass?>()) {
      return (data != null ? _issv2a3i.SchoolClass.fromJson(data) : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_iv0apgib.StudentClass>) {
      return (data as List)
              .map((e) => deserialize<_iv0apgib.StudentClass>(e))
              .toList()
          as T;
    }
    if (t == List<_ihvkgxwr.LibraryItem>) {
      return (data as List)
              .map((e) => deserialize<_ihvkgxwr.LibraryItem>(e))
              .toList()
          as T;
    }
    if (t == List<_ie2k138y.ClassSummary>) {
      return (data as List)
              .map((e) => deserialize<_ie2k138y.ClassSummary>(e))
              .toList()
          as T;
    }
    try {
      return _iais.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacs.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _isp.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i1stsozf.ClassSummary => 'ClassSummary',
      _ihvkgxwr.LibraryItem => 'LibraryItem',
      _iptwwf38.PingMessage => 'PingMessage',
      _i803mohe.Profile => 'Profile',
      _iiofgk2r.ProfileResult => 'ProfileResult',
      _iv0apgib.StudentClass => 'StudentClass',
      _ie4th1ag.StudentLibrary => 'StudentLibrary',
      _ivmxmlsf.AccessDeniedReason => 'AccessDeniedReason',
      _ihs3uvql.ContentStatus => 'ContentStatus',
      _ilnr5g4x.ContentType => 'ContentType',
      _i4pxzrse.ProfileStatus => 'ProfileStatus',
      _iez5w9yk.UserRole => 'UserRole',
      _iiozc5q0.AccessDeniedException => 'AccessDeniedException',
      _izitgulh.ClassMember => 'ClassMember',
      _idq7h264.ClassSubject => 'ClassSubject',
      _ia3wwh2b.ContentClass => 'ContentClass',
      _itiewxwm.ContentRecord => 'ContentRecord',
      _ivszvoxo.EduboxUser => 'EduboxUser',
      _issv2a3i.SchoolClass => 'SchoolClass',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('edubox.', '');
    }

    switch (data) {
      case _i1stsozf.ClassSummary():
        return 'ClassSummary';
      case _ihvkgxwr.LibraryItem():
        return 'LibraryItem';
      case _iptwwf38.PingMessage():
        return 'PingMessage';
      case _i803mohe.Profile():
        return 'Profile';
      case _iiofgk2r.ProfileResult():
        return 'ProfileResult';
      case _iv0apgib.StudentClass():
        return 'StudentClass';
      case _ie4th1ag.StudentLibrary():
        return 'StudentLibrary';
      case _ivmxmlsf.AccessDeniedReason():
        return 'AccessDeniedReason';
      case _ihs3uvql.ContentStatus():
        return 'ContentStatus';
      case _ilnr5g4x.ContentType():
        return 'ContentType';
      case _i4pxzrse.ProfileStatus():
        return 'ProfileStatus';
      case _iez5w9yk.UserRole():
        return 'UserRole';
      case _iiozc5q0.AccessDeniedException():
        return 'AccessDeniedException';
      case _izitgulh.ClassMember():
        return 'ClassMember';
      case _idq7h264.ClassSubject():
        return 'ClassSubject';
      case _ia3wwh2b.ContentClass():
        return 'ContentClass';
      case _itiewxwm.ContentRecord():
        return 'ContentRecord';
      case _ivszvoxo.EduboxUser():
        return 'EduboxUser';
      case _issv2a3i.SchoolClass():
        return 'SchoolClass';
    }
    className = _iais.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacs.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'ClassSummary') {
      return deserialize<_i1stsozf.ClassSummary>(data['data']);
    }
    if (dataClassName == 'LibraryItem') {
      return deserialize<_ihvkgxwr.LibraryItem>(data['data']);
    }
    if (dataClassName == 'PingMessage') {
      return deserialize<_iptwwf38.PingMessage>(data['data']);
    }
    if (dataClassName == 'Profile') {
      return deserialize<_i803mohe.Profile>(data['data']);
    }
    if (dataClassName == 'ProfileResult') {
      return deserialize<_iiofgk2r.ProfileResult>(data['data']);
    }
    if (dataClassName == 'StudentClass') {
      return deserialize<_iv0apgib.StudentClass>(data['data']);
    }
    if (dataClassName == 'StudentLibrary') {
      return deserialize<_ie4th1ag.StudentLibrary>(data['data']);
    }
    if (dataClassName == 'AccessDeniedReason') {
      return deserialize<_ivmxmlsf.AccessDeniedReason>(data['data']);
    }
    if (dataClassName == 'ContentStatus') {
      return deserialize<_ihs3uvql.ContentStatus>(data['data']);
    }
    if (dataClassName == 'ContentType') {
      return deserialize<_ilnr5g4x.ContentType>(data['data']);
    }
    if (dataClassName == 'ProfileStatus') {
      return deserialize<_i4pxzrse.ProfileStatus>(data['data']);
    }
    if (dataClassName == 'UserRole') {
      return deserialize<_iez5w9yk.UserRole>(data['data']);
    }
    if (dataClassName == 'AccessDeniedException') {
      return deserialize<_iiozc5q0.AccessDeniedException>(data['data']);
    }
    if (dataClassName == 'ClassMember') {
      return deserialize<_izitgulh.ClassMember>(data['data']);
    }
    if (dataClassName == 'ClassSubject') {
      return deserialize<_idq7h264.ClassSubject>(data['data']);
    }
    if (dataClassName == 'ContentClass') {
      return deserialize<_ia3wwh2b.ContentClass>(data['data']);
    }
    if (dataClassName == 'ContentRecord') {
      return deserialize<_itiewxwm.ContentRecord>(data['data']);
    }
    if (dataClassName == 'EduboxUser') {
      return deserialize<_ivszvoxo.EduboxUser>(data['data']);
    }
    if (dataClassName == 'SchoolClass') {
      return deserialize<_issv2a3i.SchoolClass>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iais.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacs.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _isp.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iais.Protocol().registerHostProtocol('edubox', this);
    _iacs.Protocol().registerHostProtocol('edubox', this);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _iais.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _iacs.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _izitgulh.ClassMember:
        return _izitgulh.ClassMember.t;
      case _idq7h264.ClassSubject:
        return _idq7h264.ClassSubject.t;
      case _ia3wwh2b.ContentClass:
        return _ia3wwh2b.ContentClass.t;
      case _itiewxwm.ContentRecord:
        return _itiewxwm.ContentRecord.t;
      case _ivszvoxo.EduboxUser:
        return _ivszvoxo.EduboxUser.t;
      case _issv2a3i.SchoolClass:
        return _issv2a3i.SchoolClass.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'edubox';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _iais.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacs.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
