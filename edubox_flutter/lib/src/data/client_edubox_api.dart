import 'package:edubox_client/edubox_client.dart'
    show Client, ClassSummary, PingMessage, ProfileResult, StudentLibrary;
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart'
    show FlutterAuthSessionManager, FlutterAuthSessionManagerExtension;
import 'package:serverpod_flutter/serverpod_flutter.dart'
    show FlutterConnectivityMonitor;

import '../contract/backend_config.dart';
import '../network/platform_sources.dart' show serverRootUrl;
import 'edubox_api.dart';

/// [EduBoxApi] over the generated Serverpod client and the auth module's
/// Flutter session manager (secure storage). Used by `main.dart` and the
/// on-device integration tests; host unit tests use a fake instead because
/// `flutter test` has no secure-storage plugin.
class ClientEduBoxApi implements EduBoxApi {
  ClientEduBoxApi._(this.client, this.sessionManager);

  /// The sign-in brief's 15 s submit timeout maps to the client timeout.
  static const connectionTimeout = Duration(seconds: 15);

  factory ClientEduBoxApi.create(BackendConfig config) {
    final client = Client(
      '${serverRootUrl(config)}/',
      connectionTimeout: connectionTimeout,
    )..connectivityMonitor = FlutterConnectivityMonitor();
    final sessionManager = FlutterAuthSessionManager();
    client.authSessionManager = sessionManager;
    return ClientEduBoxApi._(client, sessionManager);
  }

  final Client client;
  final FlutterAuthSessionManager sessionManager;

  @override
  Future<void> login({required String email, required String password}) async {
    final success = await client.emailIdp.login(
      email: email,
      password: password,
    );
    await sessionManager.updateSignedInUser(success);
  }

  @override
  Future<bool> restoreStoredAuth() async {
    await sessionManager.restore();
    return sessionManager.isAuthenticated;
  }

  @override
  Future<ProfileResult> profileMe() => client.profile.me();

  @override
  Future<List<ClassSummary>> classesMine() => client.classes.mine();

  @override
  Future<StudentLibrary> contentLibrary() => client.content.library();

  @override
  Stream<PingMessage> pingStream() => client.diagnostics.pingStream();

  @override
  Future<void> signOut() async {
    // signOutDevice clears the stored session in a finally block, so the
    // device is signed out locally even when the server call fails.
    await sessionManager.signOutDevice();
  }

  @override
  Future<void> clearStoredAuth() => sessionManager.updateSignedInUser(null);

  @override
  Future<void> close() async => client.close();
}
