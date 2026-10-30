import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The OFL licence files bundled with the three font families.
const Map<String, String> eduFontLicenseAssets = {
  'Bitter': 'assets/fonts/licenses/Bitter-OFL.txt',
  'Be Vietnam Pro': 'assets/fonts/licenses/BeVietnamPro-OFL.txt',
  'IBM Plex Mono': 'assets/fonts/licenses/IBMPlexMono-OFL.txt',
};

/// Registers each bundled font's OFL text with the licence page.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in eduFontLicenseAssets.entries) {
      final text = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}
