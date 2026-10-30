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
import 'package:edubox_client/src/protocol/dto/class_summary.dart' as _i80od7do;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
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
export 'client.dart';

class Protocol extends _isc.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

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
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
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
    if (t == _isc.getType<_i1stsozf.ClassSummary?>()) {
      return (data != null ? _i1stsozf.ClassSummary.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ihvkgxwr.LibraryItem?>()) {
      return (data != null ? _ihvkgxwr.LibraryItem.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iptwwf38.PingMessage?>()) {
      return (data != null ? _iptwwf38.PingMessage.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i803mohe.Profile?>()) {
      return (data != null ? _i803mohe.Profile.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iiofgk2r.ProfileResult?>()) {
      return (data != null ? _iiofgk2r.ProfileResult.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iv0apgib.StudentClass?>()) {
      return (data != null ? _iv0apgib.StudentClass.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ie4th1ag.StudentLibrary?>()) {
      return (data != null ? _ie4th1ag.StudentLibrary.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ivmxmlsf.AccessDeniedReason?>()) {
      return (data != null ? _ivmxmlsf.AccessDeniedReason.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ihs3uvql.ContentStatus?>()) {
      return (data != null ? _ihs3uvql.ContentStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ilnr5g4x.ContentType?>()) {
      return (data != null ? _ilnr5g4x.ContentType.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i4pxzrse.ProfileStatus?>()) {
      return (data != null ? _i4pxzrse.ProfileStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iez5w9yk.UserRole?>()) {
      return (data != null ? _iez5w9yk.UserRole.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iiozc5q0.AccessDeniedException?>()) {
      return (data != null
              ? _iiozc5q0.AccessDeniedException.fromJson(data)
              : null)
          as T;
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
    if (t == List<_i80od7do.ClassSummary>) {
      return (data as List)
              .map((e) => deserialize<_i80od7do.ClassSummary>(e))
              .toList()
          as T;
    }
    try {
      return _iaic.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacc.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
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
    }
    className = _iaic.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacc.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
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
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iaic.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacc.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iaic.Protocol().registerHostProtocol('edubox', this);
    _iacc.Protocol().registerHostProtocol('edubox', this);
  }

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
      return _iaic.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacc.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
