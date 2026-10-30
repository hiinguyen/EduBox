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
import 'package:edubox_server/src/generated/protocol.dart' as _is7bdeiu;
import 'package:serverpod/serverpod.dart' as _is;
import '../dto/library_item.dart' as _ilx8mv3m;
import '../dto/student_class.dart' as _i3owril6;

abstract class StudentLibrary
    implements _is.SerializableModel, _is.ProtocolSerialization {
  StudentLibrary._({
    required this.classes,
    required this.items,
  });

  factory StudentLibrary({
    required List<_i3owril6.StudentClass> classes,
    required List<_ilx8mv3m.LibraryItem> items,
  }) = _StudentLibraryImpl;

  factory StudentLibrary.fromJson(Map<String, dynamic> jsonSerialization) {
    return StudentLibrary(
      classes: _is7bdeiu.Protocol().deserialize<List<_i3owril6.StudentClass>>(
        jsonSerialization['classes'],
      ),
      items: _is7bdeiu.Protocol().deserialize<List<_ilx8mv3m.LibraryItem>>(
        jsonSerialization['items'],
      ),
    );
  }

  List<_i3owril6.StudentClass> classes;

  List<_ilx8mv3m.LibraryItem> items;

  /// Returns a shallow copy of this [StudentLibrary]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  StudentLibrary copyWith({
    List<_i3owril6.StudentClass>? classes,
    List<_ilx8mv3m.LibraryItem>? items,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StudentLibrary',
      'classes': classes.toJson(valueToJson: (v) => v.toJson()),
      'items': items.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StudentLibrary',
      'classes': classes.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _StudentLibraryImpl extends StudentLibrary {
  _StudentLibraryImpl({
    required List<_i3owril6.StudentClass> classes,
    required List<_ilx8mv3m.LibraryItem> items,
  }) : super._(
         classes: classes,
         items: items,
       );

  /// Returns a shallow copy of this [StudentLibrary]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  StudentLibrary copyWith({
    List<_i3owril6.StudentClass>? classes,
    List<_ilx8mv3m.LibraryItem>? items,
  }) {
    return StudentLibrary(
      classes: classes ?? this.classes.map((e0) => e0.copyWith()).toList(),
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
    );
  }
}
