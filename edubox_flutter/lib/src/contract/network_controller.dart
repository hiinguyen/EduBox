import 'dart:async';

import 'package:flutter/foundation.dart';

/// The three states the shell renders.
enum NetworkStatus { online, offline, reconnecting }

/// The app-wide network seam.
///
/// Production combines connectivity events with a server reachability probe;
/// the shell's offline strip and every offline UI state read this. Tests and
/// the fake backend drive [ManualNetworkController] directly.
abstract interface class NetworkController implements Listenable {
  NetworkStatus get status;

  bool get isOnline => status == NetworkStatus.online;

  /// Emits the new status after each transition.
  Stream<NetworkStatus> get changes;
}

/// A directly switchable seam for tests and screen previews.
class ManualNetworkController extends ChangeNotifier
    implements NetworkController {
  ManualNetworkController([NetworkStatus status = NetworkStatus.online])
    : _status = status;

  final StreamController<NetworkStatus> _changes =
      StreamController<NetworkStatus>.broadcast();

  NetworkStatus _status;

  @override
  NetworkStatus get status => _status;

  @override
  bool get isOnline => _status == NetworkStatus.online;

  @override
  Stream<NetworkStatus> get changes => _changes.stream;

  void setStatus(NetworkStatus value) {
    if (value == _status) return;
    _status = value;
    _changes.add(value);
    notifyListeners();
  }

  void goOnline() => setStatus(NetworkStatus.online);

  void goOffline() => setStatus(NetworkStatus.offline);

  void goReconnecting() => setStatus(NetworkStatus.reconnecting);

  @override
  void dispose() {
    _changes.close();
    super.dispose();
  }
}
