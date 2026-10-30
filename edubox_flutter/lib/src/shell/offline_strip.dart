import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../app/connectivity_state.dart';
import '../theme/theme_extensions.dart';
import '../theme/tokens.dart';

/// The app-wide 40dp strip at the top of the canvas (app-direction
/// section 8). Neutral fill, never warning-grey, never a padlock; not
/// dismissible while offline; collapses when the reconnect refresh ends.
class OfflineStrip extends StatelessWidget {
  const OfflineStrip({
    super.key,
    required this.state,
    this.staleWording = false,
  });

  final StripState state;

  /// Teacher-home and student-library use `networkOfflineStale` when the
  /// shown snapshot is older than the last profile refresh.
  final bool staleWording;

  @override
  Widget build(BuildContext context) {
    if (state == StripState.hidden) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final palette = EduPalette.of(context);
    final offline = state == StripState.offline;
    final message = offline
        ? (staleWording ? l10n.networkOfflineStale : l10n.networkOffline)
        : l10n.networkReconnecting;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: const Key('shell.offlineStrip'),
        constraints: const BoxConstraints(minHeight: EduSize.offlineStrip),
        color: palette.neutralFill,
        padding: const EdgeInsets.symmetric(
          horizontal: EduSpace.s16,
          vertical: EduSpace.s8,
        ),
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                offline ? Icons.cloud_off_outlined : Icons.sync,
                size: EduSize.statusGlyph,
                color: palette.muted,
              ),
            ),
            const SizedBox(width: EduSpace.s8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(color: palette.neutralInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
