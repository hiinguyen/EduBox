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
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../enums/content_type.dart' as _iqkq9d0y;

abstract class LibraryItem
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LibraryItem._({
    required this.id,
    required this.type,
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.createdAt,
  });

  factory LibraryItem({
    required int id,
    required _iqkq9d0y.ContentType type,
    required String title,
    required String subject,
    required int gradeLevel,
    required DateTime createdAt,
  }) = _LibraryItemImpl;

  factory LibraryItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return LibraryItem(
      id: jsonSerialization['id'] as int,
      type: _iqkq9d0y.ContentType.fromJson(
        (jsonSerialization['type'] as String),
      ),
      title: jsonSerialization['title'] as String,
      subject: jsonSerialization['subject'] as String,
      gradeLevel: jsonSerialization['gradeLevel'] as int,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int id;

  _iqkq9d0y.ContentType type;

  String title;

  String subject;

  int gradeLevel;

  DateTime createdAt;

  /// Returns a shallow copy of this [LibraryItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LibraryItem copyWith({
    int? id,
    _iqkq9d0y.ContentType? type,
    String? title,
    String? subject,
    int? gradeLevel,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LibraryItem',
      'id': id,
      'type': type.toJson(),
      'title': title,
      'subject': subject,
      'gradeLevel': gradeLevel,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LibraryItem',
      'id': id,
      'type': type.toJson(),
      'title': title,
      'subject': subject,
      'gradeLevel': gradeLevel,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _LibraryItemImpl extends LibraryItem {
  _LibraryItemImpl({
    required int id,
    required _iqkq9d0y.ContentType type,
    required String title,
    required String subject,
    required int gradeLevel,
    required DateTime createdAt,
  }) : super._(
         id: id,
         type: type,
         title: title,
         subject: subject,
         gradeLevel: gradeLevel,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [LibraryItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LibraryItem copyWith({
    int? id,
    _iqkq9d0y.ContentType? type,
    String? title,
    String? subject,
    int? gradeLevel,
    DateTime? createdAt,
  }) {
    return LibraryItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
