import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/theme_extensions.dart';
import '../theme/tokens.dart';

/// A flat skeleton bar at the real size of the value it replaces. No
/// shimmer. Excluded from semantics: the block announces one loading label.
class SkeletonBar extends StatelessWidget {
  const SkeletonBar({super.key, required this.width, this.height = 16});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: EduPalette.of(context).active,
          borderRadius: BorderRadius.circular(EduRadius.small),
        ),
      ),
    );
  }
}

/// The tone of an in-block message.
enum BlockTone {
  /// A failed request: negative `error_outline` glyph.
  error,

  /// Offline, not a fault: muted `cloud_off_outlined` glyph.
  offline,

  /// A plain sentence with no glyph (empty states, no linked child).
  plain,
}

/// One sentence (plus optional hint and action) inside the block that it
/// describes. Never full screen. A polite live region.
class BlockMessage extends StatelessWidget {
  const BlockMessage({
    super.key,
    required this.message,
    this.tone = BlockTone.plain,
    this.hint,
    this.action,
    this.messageStyle,
  });

  final String message;
  final BlockTone tone;
  final String? hint;
  final Widget? action;
  final TextStyle? messageStyle;

  @override
  Widget build(BuildContext context) {
    final palette = EduPalette.of(context);
    final text = Theme.of(context).textTheme;
    final glyph = switch (tone) {
      BlockTone.error => Icon(
        Icons.error_outline,
        size: EduSize.statusGlyph,
        color: palette.negative,
      ),
      BlockTone.offline => Icon(
        Icons.cloud_off_outlined,
        size: EduSize.statusGlyph,
        color: palette.muted,
      ),
      BlockTone.plain => null,
    };
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (glyph != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: ExcludeSemantics(child: glyph),
            ),
            const SizedBox(width: EduSpace.s8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: messageStyle ?? text.bodyLarge),
                if (hint != null) ...[
                  const SizedBox(height: EduSpace.s4),
                  Text(
                    hint!,
                    style: text.bodyMedium!.copyWith(color: palette.muted),
                  ),
                ],
                if (action != null) ...[
                  const SizedBox(height: EduSpace.s8),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// An 18dp, 2dp-stroke spinner beside a changed label, for busy buttons.
/// The only place a spinner is allowed.
class BusyLabel extends StatelessWidget {
  const BusyLabel({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: EduSize.statusGlyph,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: color ?? DefaultTextStyle.of(context).style.color,
          ),
        ),
        const SizedBox(width: EduSpace.s8),
        Flexible(child: Text(label)),
      ],
    );
  }
}

/// The ink "Thử lại" text button; while [busy] it reads "Đang thử lại…"
/// with the in-button spinner and is disabled.
class RetryButton extends StatelessWidget {
  const RetryButton({super.key, required this.onPressed, this.busy = false});

  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextButton(
      key: const Key('block.retry'),
      onPressed: busy ? null : onPressed,
      child: busy ? BusyLabel(label: l10n.retrying) : Text(l10n.retry),
    );
  }
}

/// A `sheet` panel: radius 8, 1dp `rule` edge, no shadow.
class EduPanel extends StatelessWidget {
  const EduPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? EdgeInsets.all(EduDensity.of(context).panelPadding),
        child: child,
      ),
    );
  }
}

/// A 3dp dot between two values on one meta line ("Sách · Toán"), so no
/// separator text is ever hardcoded.
class MetaDot extends StatelessWidget {
  const MetaDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EduSpace.s8),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: EduPalette.of(context).muted,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
