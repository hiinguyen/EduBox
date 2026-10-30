import 'package:edubox_flutter/src/theme/breakpoints.dart';
import 'package:edubox_flutter/src/theme/edu_theme.dart';
import 'package:edubox_flutter/src/theme/font_licenses.dart';
import 'package:edubox_flutter/src/theme/theme_extensions.dart';
import 'package:edubox_flutter/src/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final theme = buildEduTheme();

  test('colour scheme is the explicit ledger palette, never a seed', () {
    final scheme = theme.colorScheme;
    expect(scheme.primary, EduColors.accent);
    expect(scheme.primary, const Color(0xFF1F4C8F));
    expect(scheme.surface, const Color(0xFFF4F5F8));
    expect(scheme.onSurface, const Color(0xFF191E29));
    expect(scheme.onSurfaceVariant, const Color(0xFF4E5666));
    expect(scheme.surfaceContainerLowest, const Color(0xFFFFFFFF));
    expect(scheme.secondaryContainer, const Color(0xFFE6E9EF));
    expect(scheme.outline, const Color(0xFF7D8594));
    expect(scheme.outlineVariant, const Color(0xFFDFE3EA));
    expect(scheme.error, const Color(0xFFB3261E));
    expect(scheme.surfaceTint, Colors.transparent);
    expect(theme.scaffoldBackgroundColor, EduColors.paper);
  });

  test('every text role sets family, explicit height and even leading', () {
    final roles = <String, TextStyle?>{
      'displayLarge': theme.textTheme.displayLarge,
      'displayMedium': theme.textTheme.displayMedium,
      'headlineLarge': theme.textTheme.headlineLarge,
      'headlineMedium': theme.textTheme.headlineMedium,
      'titleLarge': theme.textTheme.titleLarge,
      'titleMedium': theme.textTheme.titleMedium,
      'titleSmall': theme.textTheme.titleSmall,
      'bodyLarge': theme.textTheme.bodyLarge,
      'bodyMedium': theme.textTheme.bodyMedium,
      'bodySmall': theme.textTheme.bodySmall,
      'labelLarge': theme.textTheme.labelLarge,
      'labelMedium': theme.textTheme.labelMedium,
      'labelSmall': theme.textTheme.labelSmall,
    };
    for (final MapEntry(:key, :value) in roles.entries) {
      expect(value, isNotNull, reason: key);
      expect(value!.fontFamily, isNotNull, reason: key);
      expect(value.height, isNotNull, reason: key);
      expect(
        value.height! * value.fontSize!,
        greaterThanOrEqualTo(16),
        reason: key,
      );
      expect(value.height!, greaterThanOrEqualTo(1.24), reason: key);
      expect(
        value.leadingDistribution,
        TextLeadingDistribution.even,
        reason: key,
      );
      expect(value.fontSize!, greaterThanOrEqualTo(12), reason: key);
    }
    expect(theme.textTheme.displayMedium!.fontFamily, EduFonts.display);
    expect(theme.textTheme.displayMedium!.fontSize, 28);
    expect(theme.textTheme.headlineLarge!.fontSize, 24);
    expect(theme.textTheme.bodyLarge!.fontFamily, EduFonts.body);
    expect(theme.textTheme.bodyLarge!.fontSize, 16);
  });

  test('surfaces are flat and radii are 8 / 6 / 4 only', () {
    expect(theme.cardTheme.elevation, 0);
    expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
    expect(cardShape.borderRadius, BorderRadius.circular(8));
    expect(cardShape.side.color, EduColors.rule);
    expect(theme.appBarTheme.elevation, 0);
    expect(theme.appBarTheme.scrolledUnderElevation, 0);
    expect(theme.dialogTheme.elevation, 6);
    final filledShape =
        theme.filledButtonTheme.style!.shape!.resolve({})!
            as RoundedRectangleBorder;
    expect(filledShape.borderRadius, BorderRadius.circular(6));
  });

  test('extensions are present with the student density by default', () {
    expect(theme.extension<EduPalette>(), isNotNull);
    expect(theme.extension<EduTypeExtras>()!.figure.fontFamily, EduFonts.mono);
    expect(theme.extension<EduDensity>(), EduDensity.student);
    final teacher = EduDensity.teacher.apply(theme);
    expect(teacher.extension<EduDensity>(), EduDensity.teacher);
    expect(teacher.extension<EduPalette>(), isNotNull);
  });

  test('window classes follow width, never orientation', () {
    expect(WindowClass.of(411), WindowClass.compact);
    expect(WindowClass.of(599.9), WindowClass.compact);
    expect(WindowClass.of(600), WindowClass.medium);
    expect(WindowClass.of(800), WindowClass.medium);
    expect(WindowClass.of(960), WindowClass.expanded);
    expect(WindowClass.of(1280), WindowClass.large);
  });

  test('font and licence assets are bundled', () async {
    for (final asset in [
      'assets/fonts/Bitter-SemiBold.ttf',
      'assets/fonts/BeVietnamPro-Regular.ttf',
      'assets/fonts/BeVietnamPro-Medium.ttf',
      'assets/fonts/BeVietnamPro-SemiBold.ttf',
      'assets/fonts/IBMPlexMono-Regular.ttf',
      'assets/fonts/IBMPlexMono-Medium.ttf',
      ...eduFontLicenseAssets.values,
    ]) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(1000), reason: asset);
    }
  });
}
