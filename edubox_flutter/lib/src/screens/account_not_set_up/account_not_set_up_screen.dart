import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../app/app_scope.dart';
import '../../app/formatters.dart';
import '../../contract/backend_result.dart';
import '../../shell/auth_panel.dart';
import '../../shell/block_states.dart';
import '../../shell/edu_mark.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/tokens.dart';

/// Stable keys for widget and E2E tests.
abstract final class AccountNotSetUpKeys {
  static const screen = Key('screen.accountNotSetUp');
  static const checkAgain = Key('accountNotSetUp.checkAgain');
  static const signOut = Key('accountNotSetUp.signOut');
  static const status = Key('accountNotSetUp.status');
}

enum _Result { none, stillNotSetUp, offline, failed }

/// `account-not-set-up` (docs/design/shapes/account-not-set-up.md).
class AccountNotSetUpScreen extends StatefulWidget {
  const AccountNotSetUpScreen({super.key});

  @override
  State<AccountNotSetUpScreen> createState() => _AccountNotSetUpScreenState();
}

class _AccountNotSetUpScreenState extends State<AccountNotSetUpScreen> {
  bool _checking = false;
  bool _signingOut = false;
  _Result _result = _Result.none;
  DateTime? _checkedAt;

  Future<void> _checkAgain() async {
    final scope = AppScope.of(context);
    setState(() {
      _checking = true;
      _result = _Result.none; // Clear the previous line first.
    });
    final result = await scope.services.backend.auth.refreshProfile();
    if (!mounted) return;
    switch (result) {
      case BackendOk(:final value, :final cachedAt):
        if (value.isReady) {
          // Stay busy until the route swaps to the role home.
          scope.session.accept(value, refreshedAt: cachedAt);
          return;
        }
        setState(() {
          _checking = false;
          _result = _Result.stillNotSetUp;
          _checkedAt = scope.services.clock();
        });
      case BackendFailure(error: SessionExpiredError()):
        await scope.session.expire();
      case BackendFailure(error: BackendUnreachableError()):
        setState(() {
          _checking = false;
          _result = _Result.offline;
        });
      case BackendFailure():
        setState(() {
          _checking = false;
          _result = _Result.failed;
        });
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    final error = await AppScope.of(context).session.signOut();
    if (mounted && error != null) setState(() => _signingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = EduPalette.of(context);
    final email = AppScope.of(context).session.session?.signedInEmail ?? '';
    final busy = _checking || _signingOut;
    return AuthPanelScaffold(
      key: AccountNotSetUpKeys.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: EduLockup(),
          ),
          const SizedBox(height: EduSpace.s24),
          Semantics(
            header: true,
            child: Text(l10n.accountNotSetUp, style: text.headlineLarge),
          ),
          const SizedBox(height: EduSpace.s12),
          Text(l10n.accountNotSetUpBody, style: text.bodyLarge),
          const SizedBox(height: EduSpace.s16),
          Text(l10n.accountNotSetUpContact, style: text.bodyLarge),
          const SizedBox(height: EduSpace.s24),
          Semantics(
            container: true,
            label: l10n.accountSignedInAsSemantics(email),
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.accountSignedInAs, style: text.bodySmall),
                Text(
                  email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: EduTypeExtras.of(context).monoBody,
                ),
              ],
            ),
          ),
          const SizedBox(height: EduSpace.s24),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: EduSpace.s24),
            child: _StatusLine(result: _result, checkedAt: _checkedAt),
          ),
          const SizedBox(height: EduSpace.s16),
          SizedBox(
            height: EduSize.primaryButton,
            child: OutlinedButton(
              key: AccountNotSetUpKeys.checkAgain,
              onPressed: busy ? null : _checkAgain,
              child: _checking
                  ? BusyLabel(label: l10n.accountChecking, color: palette.ink)
                  : Text(l10n.accountCheckAgain),
            ),
          ),
          const SizedBox(height: EduSpace.s12),
          SizedBox(
            height: EduSize.primaryButton,
            child: FilledButton(
              key: AccountNotSetUpKeys.signOut,
              onPressed: busy ? null : _signOut,
              child: _signingOut
                  ? BusyLabel(label: l10n.signOutBusy)
                  : Text(l10n.signOut),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.result, required this.checkedAt});

  final _Result result;
  final DateTime? checkedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = EduPalette.of(context);
    final Widget child = switch (result) {
      _Result.none => const SizedBox.shrink(),
      _Result.stillNotSetUp => Wrap(
        spacing: EduSpace.s8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            l10n.accountStillNotSetUp,
            style: text.bodyLarge!.copyWith(color: palette.muted),
          ),
          Text(
            l10n.accountCheckedAt(EduFormat.time(checkedAt!)),
            style: EduTypeExtras.of(context).timestamp,
          ),
        ],
      ),
      _Result.offline => BlockMessage(
        tone: BlockTone.error,
        message: l10n.accountCheckFailedOffline,
      ),
      _Result.failed => BlockMessage(
        tone: BlockTone.error,
        message: l10n.studentHomeProfileError,
      ),
    };
    return Semantics(
      key: AccountNotSetUpKeys.status,
      liveRegion: true,
      container: true,
      child: child,
    );
  }
}
