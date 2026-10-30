import 'dart:async';

import 'package:edubox_flutter/src/contract/backend_config.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/network/platform_sources.dart';
import 'package:edubox_flutter/src/network/probed_network_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeConnectivity implements ConnectivitySource {
  _FakeConnectivity(this.up);

  bool up;
  bool throwOnCheck = false;
  final controller = StreamController<bool>.broadcast();

  @override
  Future<bool> hasNetwork() async {
    if (throwOnCheck) throw StateError('platform channel failed');
    return up;
  }

  @override
  Stream<bool> get changes => controller.stream;

  Future<void> emit(bool value) async {
    up = value;
    controller.add(value);
    await pumpEventQueue();
  }
}

class _FakeProbe implements ReachabilityProbe {
  _FakeProbe(this.reachable);

  bool reachable;
  bool throws = false;
  int calls = 0;
  Completer<void>? gate;

  @override
  Future<bool> isReachable() async {
    calls++;
    final g = gate;
    if (g != null) await g.future;
    if (throws) throw StateError('probe exploded');
    return reachable;
  }
}

void main() {
  group('ProbedNetworkController', _controllerTests);
  group('HttpReachabilityProbe', _probeTests);
}

void _controllerTests() {
  late _FakeConnectivity connectivity;
  late _FakeProbe probe;
  late ProbedNetworkController controller;
  late List<NetworkStatus> seen;

  Future<void> build({required bool up, required bool reachable}) async {
    connectivity = _FakeConnectivity(up);
    probe = _FakeProbe(reachable);
    controller = ProbedNetworkController(
      connectivity: connectivity,
      probe: probe,
      probeInterval: Duration.zero,
    );
    seen = [];
    controller.changes.listen(seen.add);
    await controller.start();
    await pumpEventQueue();
    seen.clear();
  }

  tearDown(() => controller.dispose());

  test('network up and server answering is online', () async {
    await build(up: true, reachable: true);
    expect(controller.status, NetworkStatus.online);
    expect(controller.isOnline, isTrue);
  });

  test('no network is offline without probing', () async {
    await build(up: false, reachable: true);
    expect(controller.status, NetworkStatus.offline);
    expect(probe.calls, 0);
  });

  test('network connected but server unreachable is offline', () async {
    await build(up: true, reachable: false);
    expect(controller.status, NetworkStatus.offline);
  });

  test('losing the network goes offline at once', () async {
    await build(up: true, reachable: true);
    await connectivity.emit(false);
    expect(controller.status, NetworkStatus.offline);
    expect(seen, [NetworkStatus.offline]);
  });

  test('regaining the network passes through reconnecting to online', () async {
    await build(up: false, reachable: true);
    probe.gate = Completer<void>();
    connectivity.controller.add(true);
    await pumpEventQueue();
    expect(controller.status, NetworkStatus.reconnecting);
    probe.gate!.complete();
    await pumpEventQueue();
    expect(controller.status, NetworkStatus.online);
    expect(seen, [NetworkStatus.reconnecting, NetworkStatus.online]);
  });

  test(
    'regaining the network with the server still down stays offline',
    () async {
      await build(up: false, reachable: false);
      await connectivity.emit(true);
      expect(controller.status, NetworkStatus.offline);
      expect(seen, [NetworkStatus.reconnecting, NetworkStatus.offline]);
    },
  );

  test('recovers to online when the probe succeeds again', () async {
    await build(up: true, reachable: false);
    expect(controller.status, NetworkStatus.offline);
    probe.reachable = true;
    await controller.probeNow();
    expect(controller.status, NetworkStatus.online);
  });

  test('a throwing probe is offline and never escapes', () async {
    await build(up: true, reachable: true);
    probe.throws = true;
    await expectLater(controller.probeNow(), completes);
    expect(controller.status, NetworkStatus.offline);
  });

  test('a throwing connectivity check or stream is offline', () async {
    connectivity = _FakeConnectivity(true)..throwOnCheck = true;
    probe = _FakeProbe(true);
    controller = ProbedNetworkController(
      connectivity: connectivity,
      probe: probe,
      probeInterval: Duration.zero,
    );
    await controller.start();
    expect(controller.status, NetworkStatus.offline);
    connectivity.controller.addError(StateError('stream failed'));
    await pumpEventQueue();
    expect(controller.status, NetworkStatus.offline);
  });

  test('listeners are notified on each transition', () async {
    await build(up: true, reachable: true);
    var notified = 0;
    controller.addListener(() => notified++);
    await connectivity.emit(false);
    await connectivity.emit(true);
    expect(notified, 3);
  });
}

void _probeTests() {
  const config = BackendConfig(serverUrl: 'http://10.0.2.2:8080');

  test('200 on /readyz is reachable', () async {
    Uri? asked;
    final probe = HttpReachabilityProbe(
      config,
      client: MockClient((request) async {
        asked = request.url;
        return http.Response('ok', 200);
      }),
    );
    expect(await probe.isReachable(), isTrue);
    expect(asked.toString(), 'http://10.0.2.2:8080/readyz');
  });

  test('a trailing slash in the server URL is ignored', () async {
    Uri? asked;
    final probe = HttpReachabilityProbe(
      const BackendConfig(serverUrl: 'http://10.0.2.2:8080/'),
      client: MockClient((request) async {
        asked = request.url;
        return http.Response('ok', 200);
      }),
    );
    expect(await probe.isReachable(), isTrue);
    expect(asked.toString(), 'http://10.0.2.2:8080/readyz');
  });

  test('a non-200 answer is unreachable', () async {
    final probe = HttpReachabilityProbe(
      config,
      client: MockClient((_) async => http.Response('starting', 503)),
    );
    expect(await probe.isReachable(), isFalse);
  });

  test('a socket error or timeout is unreachable, never thrown', () async {
    final failing = HttpReachabilityProbe(
      config,
      client: MockClient((_) async => throw http.ClientException('refused')),
    );
    expect(await failing.isReachable(), isFalse);
    final slow = HttpReachabilityProbe(
      config,
      timeout: const Duration(milliseconds: 10),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response('ok', 200);
      }),
    );
    expect(await slow.isReachable(), isFalse);
  });
}
