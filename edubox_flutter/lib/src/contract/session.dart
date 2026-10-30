import 'package:edubox_client/edubox_client.dart';

/// The signed-in identity plus the server-resolved EduBox profile.
///
/// Role resolution is [role]; a caller with no profile, a null role, or an
/// unknown stored role has [isReady] false and lands on account-not-set-up.
class AuthSession {
  const AuthSession({
    required this.signedInEmail,
    required this.profileResult,
  });

  final String signedInEmail;
  final ProfileResult profileResult;

  Profile? get profile => profileResult.profile;

  ProfileStatus get status => profileResult.status;

  UserRole? get role => profile?.role;

  String? get linkedStudentName => profile?.linkedStudentName;

  bool get isReady =>
      profileResult.status == ProfileStatus.ready &&
      profileResult.profile != null;

  bool get isNotSetUp => !isReady;
}

/// The parent home's phase 1 data: only the linked child's display name.
class ParentHomeData {
  const ParentHomeData({required this.linkedStudentName});

  final String? linkedStudentName;

  bool get hasLinkedChild =>
      linkedStudentName != null && linkedStudentName!.trim().isNotEmpty;
}
