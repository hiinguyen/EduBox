import 'package:flutter/material.dart';

import 'theme_extensions.dart';
import 'tokens.dart';

/// Builds one text style. Every style sets an explicit line height and
/// `leadingDistribution: even`, so stacked Vietnamese marks never clip.
TextStyle eduTextStyle({
  required String family,
  required FontWeight weight,
  required double size,
  required double lineHeight,
  double tracking = 0,
  Color color = EduColors.ink,
}) => TextStyle(
  fontFamily: family,
  fontWeight: weight,
  fontSize: size,
  height: lineHeight / size,
  letterSpacing: tracking,
  color: color,
  leadingDistribution: TextLeadingDistribution.even,
);

/// The type scale of app-direction section 4.2.
TextTheme buildEduTextTheme() => TextTheme(
  displayLarge: eduTextStyle(
    family: EduFonts.display,
    weight: FontWeight.w600,
    size: 32,
    lineHeight: 40,
    tracking: -0.4,
  ),
  displayMedium: eduTextStyle(
    family: EduFonts.display,
    weight: FontWeight.w600,
    size: 28,
    lineHeight: 36,
    tracking: -0.3,
  ),
  displaySmall: eduTextStyle(
    family: EduFonts.display,
    weight: FontWeight.w600,
    size: 24,
    lineHeight: 32,
    tracking: -0.2,
  ),
  headlineLarge: eduTextStyle(
    family: EduFonts.display,
    weight: FontWeight.w600,
    size: 24,
    lineHeight: 32,
    tracking: -0.2,
  ),
  headlineMedium: eduTextStyle(
    family: EduFonts.display,
    weight: FontWeight.w600,
    size: 20,
    lineHeight: 28,
  ),
  headlineSmall: eduTextStyle(
    family: EduFonts.display,
    weight: FontWeight.w600,
    size: 20,
    lineHeight: 28,
  ),
  titleLarge: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w600,
    size: 18,
    lineHeight: 26,
  ),
  titleMedium: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w600,
    size: 16,
    lineHeight: 24,
  ),
  titleSmall: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w600,
    size: 14,
    lineHeight: 20,
  ),
  bodyLarge: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w400,
    size: 16,
    lineHeight: 24,
  ),
  bodyMedium: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w400,
    size: 14,
    lineHeight: 20,
  ),
  bodySmall: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w400,
    size: 12,
    lineHeight: 18,
    color: EduColors.muted,
  ),
  labelLarge: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w600,
    size: 16,
    lineHeight: 24,
  ),
  labelMedium: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w500,
    size: 12,
    lineHeight: 16,
  ),
  labelSmall: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w500,
    size: 12,
    lineHeight: 16,
  ),
);

/// The explicit colour scheme of app-direction section 4.1.
/// Never `ColorScheme.fromSeed`.
const ColorScheme eduColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: EduColors.accent,
  onPrimary: EduColors.sheet,
  primaryContainer: EduColors.accentPale,
  onPrimaryContainer: EduColors.accentInk,
  secondary: EduColors.muted,
  onSecondary: EduColors.sheet,
  secondaryContainer: EduColors.active,
  onSecondaryContainer: EduColors.ink,
  tertiary: EduColors.muted,
  onTertiary: EduColors.sheet,
  tertiaryContainer: EduColors.neutralFill,
  onTertiaryContainer: EduColors.neutralInk,
  error: EduColors.negative,
  onError: EduColors.sheet,
  errorContainer: EduColors.negativeFill,
  onErrorContainer: EduColors.negativeInk,
  surface: EduColors.paper,
  onSurface: EduColors.ink,
  onSurfaceVariant: EduColors.muted,
  surfaceContainerLowest: EduColors.sheet,
  surfaceContainerLow: EduColors.hover,
  surfaceContainer: EduColors.surfaceFallback,
  surfaceContainerHigh: EduColors.active,
  surfaceContainerHighest: EduColors.rule,
  surfaceBright: EduColors.sheet,
  surfaceDim: EduColors.surfaceDim,
  outline: EduColors.control,
  outlineVariant: EduColors.rule,
  shadow: EduColors.ink,
  scrim: EduColors.ink,
  inverseSurface: EduColors.ink,
  onInverseSurface: EduColors.paper,
  inversePrimary: EduColors.inverseAccent,
  surfaceTint: Colors.transparent,
);

RoundedRectangleBorder _radius(double r, {BorderSide side = BorderSide.none}) =>
    RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(r),
      side: side,
    );

/// The one app theme (light only in phase 1).
ThemeData buildEduTheme() {
  final text = buildEduTextTheme();
  const floatShadow = Color(0x2E191E29); // ink at 18%.
  final ruleSide = const BorderSide(
    color: EduColors.rule,
    width: EduSize.hairline,
  );
  final buttonShape = _radius(EduRadius.control);
  return ThemeData(
    useMaterial3: true,
    colorScheme: eduColorScheme,
    textTheme: text,
    scaffoldBackgroundColor: EduColors.paper,
    canvasColor: EduColors.paper,
    dividerColor: EduColors.rule,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    splashFactory: InkRipple.splashFactory,
    iconTheme: const IconThemeData(color: EduColors.muted, size: 20),
    appBarTheme: AppBarThemeData(
      backgroundColor: EduColors.paper,
      foregroundColor: EduColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: text.headlineLarge,
      iconTheme: const IconThemeData(color: EduColors.muted, size: 20),
      actionsIconTheme: const IconThemeData(color: EduColors.muted, size: 20),
    ),
    cardTheme: CardThemeData(
      color: EduColors.sheet,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: _radius(EduRadius.panel, side: ruleSide),
    ),
    dividerTheme: const DividerThemeData(
      color: EduColors.rule,
      thickness: EduSize.hairline,
      space: EduSize.hairline,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: EduColors.accent,
        foregroundColor: EduColors.sheet,
        disabledBackgroundColor: EduColors.active,
        disabledForegroundColor: EduColors.disabled,
        minimumSize: const Size(64, EduSize.tapTarget),
        shape: buttonShape,
        textStyle: text.labelLarge,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: EduSpace.s24),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: EduColors.sheet,
        foregroundColor: EduColors.ink,
        disabledForegroundColor: EduColors.disabled,
        side: const BorderSide(color: EduColors.control),
        minimumSize: const Size(64, EduSize.tapTarget),
        shape: buttonShape,
        textStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: EduSpace.s24),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: EduColors.ink,
        disabledForegroundColor: EduColors.disabled,
        minimumSize: const Size(EduSize.tapTarget, EduSize.tapTarget),
        shape: buttonShape,
        textStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: EduSpace.s12),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: EduColors.muted,
        minimumSize: const Size(EduSize.tapTarget, EduSize.tapTarget),
        iconSize: 20,
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: EduColors.sheet,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: EduSpace.s16,
        vertical: EduSpace.s16,
      ),
      errorMaxLines: 3,
      errorStyle: eduTextStyle(
        family: EduFonts.body,
        weight: FontWeight.w400,
        size: 14,
        lineHeight: 20,
        color: EduColors.negative,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EduRadius.control),
        borderSide: const BorderSide(color: EduColors.control),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EduRadius.control),
        borderSide: const BorderSide(color: EduColors.control),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EduRadius.control),
        borderSide: const BorderSide(color: EduColors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EduRadius.control),
        borderSide: const BorderSide(color: EduColors.negative, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EduRadius.control),
        borderSide: const BorderSide(color: EduColors.negative, width: 2),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: EduColors.paper,
      elevation: 0,
      indicatorColor: EduColors.active,
      indicatorShape: _radius(EduRadius.control),
      useIndicator: true,
      selectedIconTheme: const IconThemeData(color: EduColors.ink, size: 20),
      unselectedIconTheme: const IconThemeData(
        color: EduColors.muted,
        size: 20,
      ),
      selectedLabelTextStyle: text.labelMedium,
      unselectedLabelTextStyle: text.labelMedium!.copyWith(
        color: EduColors.muted,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: EduColors.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: EduColors.active,
      indicatorShape: _radius(EduRadius.control),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(color: EduColors.muted, size: 20),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: EduColors.sheet,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: floatShadow,
      barrierColor: const Color(0x66191E29), // ink at 40%.
      shape: _radius(EduRadius.panel),
      titleTextStyle: text.headlineMedium,
      contentTextStyle: text.bodyLarge,
    ),
    menuTheme: const MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(EduColors.sheet),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(6),
        shadowColor: WidgetStatePropertyAll(floatShadow),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(EduRadius.panel)),
          ),
        ),
      ),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: MenuItemButton.styleFrom(
        foregroundColor: EduColors.ink,
        minimumSize: const Size(160, EduSize.tapTarget),
        textStyle: text.bodyLarge,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: EduColors.sheet,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: floatShadow,
      shape: _radius(EduRadius.panel),
      textStyle: text.bodyLarge,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: EduColors.ink,
        borderRadius: BorderRadius.circular(EduRadius.small),
      ),
      textStyle: text.bodySmall!.copyWith(color: EduColors.paper),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: EduColors.ink,
      contentTextStyle: text.bodyMedium!.copyWith(color: EduColors.paper),
      actionTextColor: EduColors.inverseAccent,
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: EduColors.accent,
      linearTrackColor: EduColors.active,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: EduColors.accent,
      selectionColor: EduColors.accentPale,
      selectionHandleColor: EduColors.accent,
    ),
    extensions: [
      const EduPalette(),
      EduTypeExtras(
        figure: eduTextStyle(
          family: EduFonts.mono,
          weight: FontWeight.w500,
          size: 16,
          lineHeight: 24,
        ),
        figureTeacher: eduTextStyle(
          family: EduFonts.mono,
          weight: FontWeight.w500,
          size: 14,
          lineHeight: 20,
        ),
        timestamp: eduTextStyle(
          family: EduFonts.mono,
          weight: FontWeight.w400,
          size: 12,
          lineHeight: 18,
          color: EduColors.muted,
        ),
        monoBody: eduTextStyle(
          family: EduFonts.mono,
          weight: FontWeight.w400,
          size: 14,
          lineHeight: 20,
        ),
      ),
      EduDensity.student,
    ],
  );
}
