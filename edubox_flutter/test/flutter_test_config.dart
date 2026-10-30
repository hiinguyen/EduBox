import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled fonts (and Material Icons) before every test file, so
/// widget tests measure real Vietnamese glyphs and goldens show real type.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFont('Bitter', ['assets/fonts/Bitter-SemiBold.ttf']);
  await _loadFont('BeVietnamPro', [
    'assets/fonts/BeVietnamPro-Regular.ttf',
    'assets/fonts/BeVietnamPro-Medium.ttf',
    'assets/fonts/BeVietnamPro-SemiBold.ttf',
  ]);
  await _loadFont('IBMPlexMono', [
    'assets/fonts/IBMPlexMono-Regular.ttf',
    'assets/fonts/IBMPlexMono-Medium.ttf',
  ]);
  await _loadFont('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']);
  await testMain();
}

Future<void> _loadFont(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}
