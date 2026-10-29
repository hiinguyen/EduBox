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
import '../enums/user_role.dart' as _ifev4lwy;

abstract class Profile
    implements _is.SerializableModel, _is.ProtocolSerialization {
  Profile._({
    required this.userId,
    required this.role,
    required this.name,
    required this.email,
    this.linkedStudentName,
  });

  factory Profile({
    required int userId,
    required _ifev4lwy.UserRole role,
    required String name,
    required String email,
    String? linkedStudentName,
  }) = _ProfileImpl;

  factory Profile.fromJson(Map<String, dynamic> jsonSerialization) {
    return Profile(
      userId: jsonSerialization['userId'] as int,
      role: _ifev4lwy.UserRole.fromJson((jsonSerialization['role'] as String)),
      name: jsonSerialization['name'] as String,
      email: jsonSerialization['email'] as String,
      linkedStudentName: jsonSerialization['linkedStudentName'] as String?,
    );
  }

  int userId;

  _ifev4lwy.UserRole role;

  String name;

  String email;

  String? linkedStudentName;

  /// Returns a shallow copy of this [Profile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Profile copyWith({
    int? userId,
    _ifev4lwy.UserRole? role,
    String? name,
    String? email,
    String? linkedStudentName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Profile',
      'userId': userId,
      'role': role.toJson(),
      'name': name,
      'email': email,
      if (linkedStudentName != null) 'linkedStudentName': linkedStudentName,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Profile',
      'userId': userId,
      'role': role.toJson(),
      'name': name,
      'email': email,
      if (linkedStudentName != null) 'linkedStudentName': linkedStudentName,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProfileImpl extends Profile {
  _ProfileImpl({
    required int userId,
    required _ifev4lwy.UserRole role,
    required String name,
    required String email,
    String? linkedStudentName,
  }) : super._(
         userId: userId,
         role: role,
         name: name,
         email: email,
         linkedStudentName: linkedStudentName,
       );

  /// Returns a shallow copy of this [Profile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Profile copyWith({
    int? userId,
    _ifev4lwy.UserRole? role,
    String? name,
    String? email,
    Object? linkedStudentName = _Undefined,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      linkedStudentName: linkedStudentName is String?
          ? linkedStudentName
          : this.linkedStudentName,
    );
  }
}
