import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../shell/auth_panel.dart';
import '../../shell/block_states.dart';
import '../../shell/edu_mark.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/tokens.dart';

/// Shown once while the stored session and role resolve: the mark and
/// "Đang mở EduBox…" in `muted`. Never a bare spinner.
class AppOpeningScreen extends StatelessWidget {
  const AppOpeningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const Key('screen.appOpening'),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EduLockup(),
              const SizedBox(height: EduSpace.s16),
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.appOpening,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: EduPalette.of(context).muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// App-start session or role resolution failed: the panel-only variant of
/// backend unreachable (mark, message, hint, "Thử lại"; no form).
class AppStartFailedScreen extends StatefulWidget {
  const AppStartFailedScreen({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  State<AppStartFailedScreen> createState() => _AppStartFailedScreenState();
}

class _AppStartFailedScreenState extends State<AppStartFailedScreen> {
  bool _busy = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    await widget.onRetry();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = EduPalette.of(context);
    return AuthPanelScaffold(
      key: const Key('screen.appStartFailed'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const EduLockup(),
          const SizedBox(height: EduSpace.s24),
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Icon(
                    Icons.cloud_off_outlined,
                    size: EduSize.statusGlyph,
                    color: palette.muted,
                  ),
                ),
                const SizedBox(width: EduSpace.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.backendUnreachable,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: EduSpace.s4),
                      Text(
                        l10n.backendUnreachableHint,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium!.copyWith(color: palette.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: EduSpace.s8),
          RetryButton(onPressed: _retry, busy: _busy),
        ],
      ),
    );
  }
}
