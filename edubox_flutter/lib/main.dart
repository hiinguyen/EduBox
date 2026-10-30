import 'package:flutter/material.dart';

import 'src/app/edubox_app.dart';
import 'src/app/production_services.dart';
import 'src/contract/backend_config.dart';
import 'src/theme/font_licenses.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  runApp(
    EduBoxBootstrap(
      createServices: () =>
          createProductionServices(BackendConfig.fromEnvironment()),
    ),
  );
}
