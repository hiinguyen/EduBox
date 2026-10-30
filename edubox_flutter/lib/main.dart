import 'package:flutter/material.dart';

import 'src/app/edubox_app.dart';
import 'src/app/production_services.dart';
import 'src/contract/backend_config.dart';
import 'src/theme/font_licenses.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  final services = await createProductionServices(
    BackendConfig.fromEnvironment(),
  );
  runApp(EduBoxApp(services: services));
}
