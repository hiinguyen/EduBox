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

abstract class PingMessage
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PingMessage._({
    required this.sequence,
    required this.total,
    required this.role,
    required this.sentAt,
  });

  factory PingMessage({
    required int sequence,
    required int total,
    required _ifev4lwy.UserRole role,
    required DateTime sentAt,
  }) = _PingMessageImpl;

  factory PingMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return PingMessage(
      sequence: jsonSerialization['sequence'] as int,
      total: jsonSerialization['total'] as int,
      role: _ifev4lwy.UserRole.fromJson((jsonSerialization['role'] as String)),
      sentAt: _is.DateTimeJsonExtension.fromJson(jsonSerialization['sentAt']),
    );
  }

  int sequence;

  int total;

  _ifev4lwy.UserRole role;

  DateTime sentAt;

  /// Returns a shallow copy of this [PingMessage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PingMessage copyWith({
    int? sequence,
    int? total,
    _ifev4lwy.UserRole? role,
    DateTime? sentAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PingMessage',
      'sequence': sequence,
      'total': total,
      'role': role.toJson(),
      'sentAt': sentAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PingMessage',
      'sequence': sequence,
      'total': total,
      'role': role.toJson(),
      'sentAt': sentAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _PingMessageImpl extends PingMessage {
  _PingMessageImpl({
    required int sequence,
    required int total,
    required _ifev4lwy.UserRole role,
    required DateTime sentAt,
  }) : super._(
         sequence: sequence,
         total: total,
         role: role,
         sentAt: sentAt,
       );

  /// Returns a shallow copy of this [PingMessage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PingMessage copyWith({
    int? sequence,
    int? total,
    _ifev4lwy.UserRole? role,
    DateTime? sentAt,
  }) {
    return PingMessage(
      sequence: sequence ?? this.sequence,
      total: total ?? this.total,
      role: role ?? this.role,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}
