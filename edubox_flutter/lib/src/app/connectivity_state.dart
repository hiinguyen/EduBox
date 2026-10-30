import 'dart:async';

import 'package:flutter/foundation.dart';

import '../contract/network_controller.dart';

/// What the shell's 40dp strip shows.
enum StripState {
  /// Online and idle: no strip.
  hidden,

  /// `networkOffline` (or `networkOfflineStale` where a screen asks for it).
  offline,

  /// `networkReconnecting`: the seam is reconnecting, or it just came back
  /// online and the visible screens are re-reading.
  reconnecting,
}

/// Bridges [NetworkController] to the screens.
///
/// Screens register a reload callback; on every
/// `offline|reconnecting -> online` transition all registered reloads run
/// and the strip shows `networkReconnecting` until they finish, then
/// collapses. Screens never refresh from their own timer.
class ConnectivityState extends ChangeNotifier {
  ConnectivityState(this.network) : _last = network.status {
    network.addListener(_onNetwork);
  }

  final NetworkController network;
  final Set<Future<void> Function()> _reloads = {};
  NetworkStatus _last;
  int _running = 0;
  bool _disposed = false;

  bool get isOnline => network.status == NetworkStatus.online;

  StripState get strip {
    switch (network.status) {
      case NetworkStatus.offline:
        return StripState.offline;
      case NetworkStatus.reconnecting:
        return StripState.reconnecting;
      case NetworkStatus.online:
        return _running > 0 ? StripState.reconnecting : StripState.hidden;
    }
  }

  /// Registers [reload] to run after every reconnect.
  void register(Future<void> Function() reload) => _reloads.add(reload);

  void unregister(Future<void> Function() reload) => _reloads.remove(reload);

  void _onNetwork() {
    final now = network.status;
    final cameBack = now == NetworkStatus.online && _last != now;
    _last = now;
    notifyListeners();
    if (cameBack) unawaited(_reloadAll());
  }

  Future<void> _reloadAll() async {
    _running++;
    notifyListeners();
    try {
      await Future.wait([for (final reload in _reloads.toList()) reload()]);
    } finally {
      _running--;
      // A reload may finish after the app root was disposed.
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    network.removeListener(_onNetwork);
    super.dispose();
  }
}
