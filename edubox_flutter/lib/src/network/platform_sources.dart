import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../contract/backend_config.dart';
import 'probed_network_controller.dart';

/// The server's base URL without trailing slashes, so
/// `--dart-define=EDUBOX_SERVER_URL=http://10.0.2.2:8080/` and the default
/// `http://10.0.2.2:8080` give the same routes.
String serverRootUrl(BackendConfig config) =>
    config.serverUrl.replaceFirst(RegExp(r'/+$'), '');

/// [ConnectivitySource] over `connectivity_plus`.
class ConnectivityPlusSource implements ConnectivitySource {
  ConnectivityPlusSource([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _anyUp(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  @override
  Future<bool> hasNetwork() async =>
      _anyUp(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get changes => _connectivity.onConnectivityChanged.map(_anyUp);
}

/// [ReachabilityProbe] that GETs the server's `/readyz` (the same route the
/// compose healthcheck uses). Any status other than 200, a timeout or a
/// socket error is "unreachable".
class HttpReachabilityProbe implements ReachabilityProbe {
  HttpReachabilityProbe(
    this.config, {
    http.Client? client,
    this.timeout = const Duration(seconds: 3),
  }) : _client = client ?? http.Client();

  final BackendConfig config;
  final Duration timeout;
  final http.Client _client;

  Uri get readyUri => Uri.parse('${serverRootUrl(config)}/readyz');

  @override
  Future<bool> isReachable() async {
    try {
      final response = await _client.get(readyUri).timeout(timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  void close() => _client.close();
}
