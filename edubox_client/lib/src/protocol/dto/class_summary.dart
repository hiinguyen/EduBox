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
import 'package:edubox_client/src/protocol/protocol.dart' as _ivwnx0wz;
import 'package:serverpod_client/serverpod_client.dart' as _isc;

abstract class ClassSummary
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ClassSummary._({
    required this.id,
    required this.name,
    required this.gradeLevel,
    required this.subjects,
    required this.studentCount,
  });

  factory ClassSummary({
    required int id,
    required String name,
    required int gradeLevel,
    required List<String> subjects,
    required int studentCount,
  }) = _ClassSummaryImpl;

  factory ClassSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return ClassSummary(
      id: jsonSerialization['id'] as int,
      name: jsonSerialization['name'] as String,
      gradeLevel: jsonSerialization['gradeLevel'] as int,
      subjects: _ivwnx0wz.Protocol().deserialize<List<String>>(
        jsonSerialization['subjects'],
      ),
      studentCount: jsonSerialization['studentCount'] as int,
    );
  }

  int id;

  String name;

  int gradeLevel;

  List<String> subjects;

  int studentCount;

  /// Returns a shallow copy of this [ClassSummary]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ClassSummary copyWith({
    int? id,
    String? name,
    int? gradeLevel,
    List<String>? subjects,
    int? studentCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ClassSummary',
      'id': id,
      'name': name,
      'gradeLevel': gradeLevel,
      'subjects': subjects.toJson(),
      'studentCount': studentCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ClassSummary',
      'id': id,
      'name': name,
      'gradeLevel': gradeLevel,
      'subjects': subjects.toJson(),
      'studentCount': studentCount,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _ClassSummaryImpl extends ClassSummary {
  _ClassSummaryImpl({
    required int id,
    required String name,
    required int gradeLevel,
    required List<String> subjects,
    required int studentCount,
  }) : super._(
         id: id,
         name: name,
         gradeLevel: gradeLevel,
         subjects: subjects,
         studentCount: studentCount,
       );

  /// Returns a shallow copy of this [ClassSummary]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ClassSummary copyWith({
    int? id,
    String? name,
    int? gradeLevel,
    List<String>? subjects,
    int? studentCount,
  }) {
    return ClassSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      subjects: subjects ?? this.subjects.map((e0) => e0).toList(),
      studentCount: studentCount ?? this.studentCount,
    );
  }
}
