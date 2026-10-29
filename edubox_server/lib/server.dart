import 'src/auth/auth_setup.dart';
import 'src/generated/serverpod.dart';

/// Starts the EduBox server.
///
/// Redis is disabled in every run mode, cloud storage is configured by the
/// backend track (see `src/storage/object_store.dart`), and authentication is
/// email/password sign-in only (see `src/auth/auth_setup.dart`).
Future<void> run(List<String> args) async {
  final pod = Serverpod(args);
  configureAuthServices(pod);
  await pod.start();
}
