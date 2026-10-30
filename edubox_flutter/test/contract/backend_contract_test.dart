import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/fake/fake_backend.dart';

import 'contract_suite.dart';

void main() {
  final network = ManualNetworkController();
  FakeBackend? current;

  runBackendContractTests(
    name: 'phase 1 backend contract (fake)',
    createBackend: () async => current = FakeBackend(network: network),
    createUnreachableBackend: () async {
      final fake = FakeBackend();
      fake.signInError = const BackendUnreachableError();
      fake.profileError = const BackendUnreachableError();
      fake.classesError = const BackendUnreachableError();
      fake.libraryError = const BackendUnreachableError();
      fake.parentError = const BackendUnreachableError();
      fake.pingError = const BackendUnreachableError();
      return fake;
    },
    network: network,
    setRole: (accountKey, role) async => current!.setRole(accountKey, role),
    clearCache: () async => current!.clearCache(),
  );
}
