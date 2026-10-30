import 'dart:async';

import 'package:flutter/foundation.dart';

import '../contract/network_controller.dart';

/// Whether the device has any network interface up (Wi-Fi, mobile,
/// Ethernet). It says nothing about whether the EduBox server answers.
abstract interface class ConnectivitySource {
  Future<bool> hasNetwork();

  /// Emits on every interface change: true when any interface is up.
  Stream<bool> get changes;
}

/// Asks the EduBox server whether it answers. Must never throw: a failure
/// is `false`.
abstract interface class ReachabilityProbe {
  Future<bool> isReachable();
}

/// The production [NetworkController] (contract.md section 3.5).
///
/// It combines connectivity events with a server reachability probe:
/// - no interface up: [NetworkStatus.offline];
/// - interface up but the server does not answer: [NetworkStatus.offline];
/// - interface regained: [NetworkStatus.reconnecting] while the probe runs,
///   then online or offline by the probe result;
/// - a successful probe while offline recovers to online.
///
/// [probeInterval] re-probes on a timer so a server that comes back (or goes
/// away) is noticed without a connectivity event. Probe and stream failures
/// surface as offline and are never rethrown.
class ProbedNetworkController extends ChangeNotifier
    implements NetworkController {
  ProbedNetworkController({
    required this.connectivity,
    required this.probe,
    this.probeInterval = const Duration(seconds: 15),
  });

  final ConnectivitySource connectivity;
  final ReachabilityProbe probe;
  final Duration probeInterval;

  final StreamController<NetworkStatus> _changes =
      StreamController<NetworkStatus>.broadcast();
  StreamSubscription<bool>? _connectivitySub;
  Timer? _timer;
  bool _hasNetwork = false;
  bool _disposed = false;
  NetworkStatus _status = NetworkStatus.offline;

  @override
  NetworkStatus get status => _status;

  @override
  bool get isOnline => _status == NetworkStatus.online;

  @override
  Stream<NetworkStatus> get changes => _changes.stream;

  /// Reads the first state and starts listening. Call once.
  Future<void> start() async {
    _connectivitySub = connectivity.changes.listen(
      (up) => unawaited(_onConnectivity(up)),
      onError: (Object _) => _set(NetworkStatus.offline),
    );
    _hasNetwork = await _safeHasNetwork();
    await probeNow();
    if (probeInterval > Duration.zero) {
      _timer = Timer.periodic(probeInterval, (_) => unawaited(probeNow()));
    }
  }

  /// Probes the server now and updates [status]. Never throws.
  Future<void> probeNow() async {
    if (!_hasNetwork) {
      _set(NetworkStatus.offline);
      return;
    }
    final reachable = await _safeProbe();
    if (_disposed) return;
    if (!_hasNetwork) {
      _set(NetworkStatus.offline);
      return;
    }
    _set(reachable ? NetworkStatus.online : NetworkStatus.offline);
  }

  Future<void> _onConnectivity(bool up) async {
    final wasUp = _hasNetwork;
    _hasNetwork = up;
    if (!up) {
      _set(NetworkStatus.offline);
      return;
    }
    if (!wasUp || _status != NetworkStatus.online) {
      _set(NetworkStatus.reconnecting);
    }
    await probeNow();
  }

  Future<bool> _safeHasNetwork() async {
    try {
      return await connectivity.hasNetwork();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _safeProbe() async {
    try {
      return await probe.isReachable();
    } catch (_) {
      return false;
    }
  }

  void _set(NetworkStatus value) {
    if (_disposed || value == _status) return;
    _status = value;
    _changes.add(value);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_connectivitySub?.cancel());
    unawaited(_changes.close());
    super.dispose();
  }
}
