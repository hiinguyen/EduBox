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
import '../dto/profile.dart' as _itgeo8f0;
import '../enums/profile_status.dart' as _igixpsca;

abstract class ProfileResult
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ProfileResult._({
    required this.status,
    this.profile,
    this.signedInEmail,
  });

  factory ProfileResult({
    required _igixpsca.ProfileStatus status,
    _itgeo8f0.Profile? profile,
    String? signedInEmail,
  }) = _ProfileResultImpl;

  factory ProfileResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProfileResult(
      status: _igixpsca.ProfileStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      profile: jsonSerialization['profile'] == null
          ? null
          : _ivwnx0wz.Protocol().deserialize<_itgeo8f0.Profile>(
              jsonSerialization['profile'],
            ),
      signedInEmail: jsonSerialization['signedInEmail'] as String?,
    );
  }

  _igixpsca.ProfileStatus status;

  _itgeo8f0.Profile? profile;

  String? signedInEmail;

  /// Returns a shallow copy of this [ProfileResult]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ProfileResult copyWith({
    _igixpsca.ProfileStatus? status,
    _itgeo8f0.Profile? profile,
    String? signedInEmail,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProfileResult',
      'status': status.toJson(),
      if (profile != null) 'profile': profile?.toJson(),
      if (signedInEmail != null) 'signedInEmail': signedInEmail,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ProfileResult',
      'status': status.toJson(),
      if (profile != null) 'profile': profile?.toJsonForProtocol(),
      if (signedInEmail != null) 'signedInEmail': signedInEmail,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProfileResultImpl extends ProfileResult {
  _ProfileResultImpl({
    required _igixpsca.ProfileStatus status,
    _itgeo8f0.Profile? profile,
    String? signedInEmail,
  }) : super._(
         status: status,
         profile: profile,
         signedInEmail: signedInEmail,
       );

  /// Returns a shallow copy of this [ProfileResult]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ProfileResult copyWith({
    _igixpsca.ProfileStatus? status,
    Object? profile = _Undefined,
    Object? signedInEmail = _Undefined,
  }) {
    return ProfileResult(
      status: status ?? this.status,
      profile: profile is _itgeo8f0.Profile?
          ? profile
          : this.profile?.copyWith(),
      signedInEmail: signedInEmail is String?
          ? signedInEmail
          : this.signedInEmail,
    );
  }
}
