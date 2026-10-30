import 'package:flutter/material.dart';

import 'tokens.dart';

/// Raw palette tokens for the few custom widgets that need one (skeleton
/// bars, the mark, the offline strip). Read with `EduPalette.of(context)`.
@immutable
class EduPalette extends ThemeExtension<EduPalette> {
  const EduPalette({
    this.paper = EduColors.paper,
    this.sheet = EduColors.sheet,
    this.ink = EduColors.ink,
    this.muted = EduColors.muted,
    this.accent = EduColors.accent,
    this.active = EduColors.active,
    this.rule = EduColors.rule,
    this.control = EduColors.control,
    this.disabled = EduColors.disabled,
    this.negative = EduColors.negative,
    this.neutralFill = EduColors.neutralFill,
    this.neutralInk = EduColors.neutralInk,
  });

  final Color paper;
  final Color sheet;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color active;
  final Color rule;
  final Color control;
  final Color disabled;
  final Color negative;
  final Color neutralFill;
  final Color neutralInk;

  static EduPalette of(BuildContext context) =>
      Theme.of(context).extension<EduPalette>() ?? const EduPalette();

  @override
  EduPalette copyWith() => this;

  @override
  EduPalette lerp(EduPalette? other, double t) => other ?? this;
}

/// IBM Plex Mono styles for figures, timestamps and the signed-in email.
@immutable
class EduTypeExtras extends ThemeExtension<EduTypeExtras> {
  const EduTypeExtras({
    required this.figure,
    required this.figureTeacher,
    required this.timestamp,
    required this.monoBody,
  });

  /// Figure in a student row: Plex Mono 500, 16/24.
  final TextStyle figure;

  /// Figure in a teacher table: Plex Mono 500, 14/20.
  final TextStyle figureTeacher;

  /// Timestamp or date in a row: Plex Mono 400, 12/18.
  final TextStyle timestamp;

  /// An identifier shown as data (the signed-in email): Plex Mono 400, 14/20.
  final TextStyle monoBody;

  static EduTypeExtras of(BuildContext context) =>
      Theme.of(context).extension<EduTypeExtras>()!;

  @override
  EduTypeExtras copyWith({
    TextStyle? figure,
    TextStyle? figureTeacher,
    TextStyle? timestamp,
    TextStyle? monoBody,
  }) => EduTypeExtras(
    figure: figure ?? this.figure,
    figureTeacher: figureTeacher ?? this.figureTeacher,
    timestamp: timestamp ?? this.timestamp,
    monoBody: monoBody ?? this.monoBody,
  );

  @override
  EduTypeExtras lerp(EduTypeExtras? other, double t) => other ?? this;
}

/// Per-role density (app-direction section 6). The role shell injects one
/// with `EduDensity.apply`.
@immutable
class EduDensity extends ThemeExtension<EduDensity> {
  const EduDensity({
    required this.gap,
    required this.panelPadding,
    required this.sectionGap,
    required this.rowHeight,
    required this.buttonHeight,
  });

  /// Student and pre-auth: generous.
  static const student = EduDensity(
    gap: EduSpace.s24,
    panelPadding: EduSpace.s24,
    sectionGap: EduSpace.s48,
    rowHeight: 72,
    buttonHeight: EduSize.primaryButton,
  );

  /// Teacher: denser, table-forward.
  static const teacher = EduDensity(
    gap: EduSpace.s16,
    panelPadding: EduSpace.s16,
    sectionGap: EduSpace.s32,
    rowHeight: EduSize.tapTarget,
    buttonHeight: 40,
  );

  /// Parent: minimal, student spacing.
  static const parent = EduDensity(
    gap: EduSpace.s24,
    panelPadding: EduSpace.s24,
    sectionGap: EduSpace.s48,
    rowHeight: 64,
    buttonHeight: EduSize.tapTarget,
  );

  final double gap;
  final double panelPadding;
  final double sectionGap;
  final double rowHeight;
  final double buttonHeight;

  static EduDensity of(BuildContext context) =>
      Theme.of(context).extension<EduDensity>() ?? student;

  /// Returns [base] with this density replacing any other density extension.
  ThemeData apply(ThemeData base) => base.copyWith(
    extensions: [
      ...base.extensions.values.where((e) => e is! EduDensity),
      this,
    ],
  );

  @override
  EduDensity copyWith({
    double? gap,
    double? panelPadding,
    double? sectionGap,
    double? rowHeight,
    double? buttonHeight,
  }) => EduDensity(
    gap: gap ?? this.gap,
    panelPadding: panelPadding ?? this.panelPadding,
    sectionGap: sectionGap ?? this.sectionGap,
    rowHeight: rowHeight ?? this.rowHeight,
    buttonHeight: buttonHeight ?? this.buttonHeight,
  );

  @override
  EduDensity lerp(EduDensity? other, double t) => other ?? this;
}
