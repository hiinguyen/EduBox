import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/data/cached_backend.dart';
import 'package:edubox_flutter/src/local/local_store.dart';

import '../contract/contract_suite.dart';
import 'fixture_api.dart';

/// Runs the frozen contract suite against the production data layer, with a
/// fixture-backed API standing in for the server.
void main() {
  final network = ManualNetworkController();
  late FixtureEduBoxApi api;
  late CachedDataStore store;

  runBackendContractTests(
    name: 'phase 1 backend contract (CachedBackend over the fixture API)',
    createBackend: () async {
      api = FixtureEduBoxApi();
      store = CachedDataStore(EduBoxDatabase.inMemory());
      return CachedBackend(api: api, store: store, network: network);
    },
    createUnreachableBackend: () async => CachedBackend(
      api: FixtureEduBoxApi(unreachable: true),
      store: CachedDataStore(EduBoxDatabase.inMemory()),
      network: ManualNetworkController(),
    ),
    network: network,
    setRole: (accountKey, role) async => api.setRole(accountKey, role),
    clearCache: () => store.clearAll(),
  );
}
