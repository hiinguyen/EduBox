import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/theme_extensions.dart';
import '../theme/tokens.dart';

/// The 24dp index-card glyph: a 2dp outline card, radius 4, with a raised
/// tab on its top-left third, in the accent (app-direction section 1.2).
class EduMarkGlyph extends StatelessWidget {
  const EduMarkGlyph({super.key, this.size = EduSize.mark});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(EduPalette.of(context).accent),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 24;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * unit;
    final fill = Paint()..color = color;
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(2 * unit, 7 * unit, 20 * unit, 14 * unit),
      Radius.circular(4 * unit),
    );
    canvas.drawRRect(card, stroke);
    final tab = RRect.fromRectAndCorners(
      Rect.fromLTWH(2 * unit, 3 * unit, 8 * unit, 5 * unit),
      topLeft: Radius.circular(2 * unit),
      topRight: Radius.circular(2 * unit),
    );
    canvas.drawRRect(tab, fill);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.color != color;
}

/// The glyph plus the "EduBox" wordmark (Bitter 600, 20sp, ink), read by
/// screen readers as one image labelled `appMarkSemantics`.
class EduLockup extends StatelessWidget {
  const EduLockup({super.key, this.showWordmark = true});

  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.headlineMedium;
    return Semantics(
      container: true,
      label: l10n.appMarkSemantics,
      image: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EduMarkGlyph(),
          if (showWordmark) ...[
            const SizedBox(width: EduSpace.s8),
            Text(l10n.appName, style: style),
          ],
        ],
      ),
    );
  }
}
