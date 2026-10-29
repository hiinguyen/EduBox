import 'repositories.dart';

/// The single seam every contract test and feature screen depends on.
///
/// The fake implements it now; the real generated-client binding plugs in at
/// phase 5 without changing a screen or a test.
abstract interface class EduBoxBackend {
  AuthRepository get auth;
  ProfileRepository get profile;
  ClassesRepository get classes;
  LibraryRepository get library;
  ParentRepository get parent;
  DiagnosticsRepository get diagnostics;

  Future<void> dispose();
}
