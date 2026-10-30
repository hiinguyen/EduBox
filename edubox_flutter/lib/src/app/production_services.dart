import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../contract/backend_config.dart';
import '../contract/network_controller.dart';
import '../data/cached_backend.dart';
import '../data/client_edubox_api.dart';
import '../local/local_store.dart';
import '../network/platform_sources.dart';
import '../network/probed_network_controller.dart';
import 'app_scope.dart';

/// The drift store file inside the app's support directory.
Future<File> defaultDatabaseFile() async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, 'edubox.sqlite'));
}

/// Production wiring: the generated client, the on-disk drift store and the
/// probed network seam. The E2E harness passes its own [network] (a
/// `ManualNetworkController`) and [databaseFile] so it can switch the seam
/// and re-create the app root over the same store.
Future<AppServices> createProductionServices(
  BackendConfig config, {
  NetworkController? network,
  File? databaseFile,
}) async {
  final file = databaseFile ?? await defaultDatabaseFile();
  final ownedNetwork = network == null
      ? await _startProbedNetwork(config)
      : null;
  final seam = network ?? ownedNetwork!;
  final backend = CachedBackend(
    api: ClientEduBoxApi.create(config),
    store: CachedDataStore(EduBoxDatabase.open(file)),
    network: seam,
  );
  return AppServices(
    backend: backend,
    network: seam,
    disposeNetwork: ownedNetwork?.dispose,
  );
}

Future<ProbedNetworkController> _startProbedNetwork(
  BackendConfig config,
) async {
  final controller = ProbedNetworkController(
    connectivity: ConnectivityPlusSource(),
    probe: HttpReachabilityProbe(config),
  );
  await controller.start();
  return controller;
}
