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

abstract class StudentClass
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  StudentClass._({
    required this.id,
    required this.name,
    required this.gradeLevel,
    required this.subjects,
  });

  factory StudentClass({
    required int id,
    required String name,
    required int gradeLevel,
    required List<String> subjects,
  }) = _StudentClassImpl;

  factory StudentClass.fromJson(Map<String, dynamic> jsonSerialization) {
    return StudentClass(
      id: jsonSerialization['id'] as int,
      name: jsonSerialization['name'] as String,
      gradeLevel: jsonSerialization['gradeLevel'] as int,
      subjects: _ivwnx0wz.Protocol().deserialize<List<String>>(
        jsonSerialization['subjects'],
      ),
    );
  }

  int id;

  String name;

  int gradeLevel;

  List<String> subjects;

  /// Returns a shallow copy of this [StudentClass]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  StudentClass copyWith({
    int? id,
    String? name,
    int? gradeLevel,
    List<String>? subjects,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StudentClass',
      'id': id,
      'name': name,
      'gradeLevel': gradeLevel,
      'subjects': subjects.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StudentClass',
      'id': id,
      'name': name,
      'gradeLevel': gradeLevel,
      'subjects': subjects.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _StudentClassImpl extends StudentClass {
  _StudentClassImpl({
    required int id,
    required String name,
    required int gradeLevel,
    required List<String> subjects,
  }) : super._(
         id: id,
         name: name,
         gradeLevel: gradeLevel,
         subjects: subjects,
       );

  /// Returns a shallow copy of this [StudentClass]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  StudentClass copyWith({
    int? id,
    String? name,
    int? gradeLevel,
    List<String>? subjects,
  }) {
    return StudentClass(
      id: id ?? this.id,
      name: name ?? this.name,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      subjects: subjects ?? this.subjects.map((e0) => e0).toList(),
    );
  }
}
