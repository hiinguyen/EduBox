import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../app/app_scope.dart';
import '../shell/block_states.dart';
import '../theme/theme_extensions.dart';
import '../theme/tokens.dart';

/// Students only: confirm sign-out, with the offline warning (a cached
/// session signed out offline cannot sign in again until there is a
/// connection). Teacher, parent and account-not-set-up sign out at once.
Future<void> showStudentSignOutDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _StudentSignOutDialog(),
);

class _StudentSignOutDialog extends StatefulWidget {
  const _StudentSignOutDialog();

  @override
  State<_StudentSignOutDialog> createState() => _StudentSignOutDialogState();
}

class _StudentSignOutDialogState extends State<_StudentSignOutDialog> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final error = await AppScope.of(context).session.signOut();
    // On success the app root closes this dialog when the stage changes.
    if (mounted && error != null) {
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    final palette = EduPalette.of(context);
    final offline = !scope.connectivity.isOnline;
    return AlertDialog(
      key: const Key('signOut.dialog'),
      title: Text(l10n.signOutConfirmTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.signOutConfirmBody),
            if (offline) ...[
              const SizedBox(height: EduSpace.s12),
              Text(l10n.signOutOfflineWarning),
            ],
            if (_failed) ...[
              const SizedBox(height: EduSpace.s12),
              BlockMessage(tone: BlockTone.error, message: l10n.signOutFailed),
            ],
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          key: const Key('signOut.cancel'),
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('signOut.confirm'),
          // Ink fill: the screen's one accent is already "Mở thư viện".
          style: FilledButton.styleFrom(
            backgroundColor: palette.ink,
            foregroundColor: palette.sheet,
            disabledBackgroundColor: palette.ink,
            disabledForegroundColor: palette.sheet,
          ),
          onPressed: _busy ? null : _confirm,
          child: _busy
              ? BusyLabel(label: l10n.signOutBusy, color: palette.sheet)
              : Text(l10n.signOut),
        ),
      ],
    );
  }
}
