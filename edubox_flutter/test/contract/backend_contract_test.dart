import 'package:edubox_flutter/src/fake/fake_backend.dart';

import 'contract_suite.dart';

void main() {
  runBackendContractTests(
    name: 'phase 1 backend contract (fake)',
    createBackend: () async => FakeBackend(),
  );
}
