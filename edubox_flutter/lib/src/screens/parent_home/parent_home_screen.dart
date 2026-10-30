import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../app/app_scope.dart';
import '../../app/loadable.dart';
import '../../contract/backend_result.dart';
import '../../contract/session.dart';
import '../../shell/account_menu.dart';
import '../../shell/block_states.dart';
import '../../shell/edu_mark.dart';
import '../../shell/offline_strip.dart';
import '../../theme/breakpoints.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/tokens.dart';

/// Stable keys for widget and E2E tests.
abstract final class ParentHomeKeys {
  static const screen = Key('screen.parentHome');
  static const panel = Key('parentHome.panel');
  static const name = Key('parentHome.name');
}

/// `parent-home` (docs/design/shapes/parent-home.md) with its minimal
/// shell: a 64dp app bar (lockup, overflow with "Đăng xuất"), the strip,
/// and one record panel: the "Học sinh" label above the linked child's
/// name. No rail, no accent, no forward-looking copy.
class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  Loadable<ParentHomeData>? _home;
  late AppScope _scope;
  bool _signingOut = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = AppScope.of(context);
    if (_home == null) {
      final home = Loadable<ParentHomeData>(
        _scope.services.backend.parent.home,
      )..addListener(_onHome);
      _home = home;
      _scope.connectivity.register(home.load);
      unawaited(home.load());
    }
  }

  void _onHome() {
    if (_home!.error is SessionExpiredError) {
      unawaited(_scope.session.expire());
    }
  }

  @override
  void dispose() {
    final home = _home!;
    _scope.connectivity.unregister(home.load);
    home
      ..removeListener(_onHome)
      ..dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    final error = await _scope.session.signOut();
    if (!mounted || error == null) return;
    setState(() => _signingOut = false);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.signOutFailed),
        action: SnackBarAction(label: l10n.retry, onPressed: _signOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final home = _home!;
    final window = WindowClass.of(MediaQuery.sizeOf(context).width);
    return Theme(
      data: EduDensity.parent.apply(Theme.of(context)),
      child: Scaffold(
        key: ParentHomeKeys.screen,
        appBar: AppBar(
          toolbarHeight: 64,
          automaticallyImplyLeading: false,
          titleSpacing: window.gutter,
          title: const EduLockup(),
          actions: [
            AccountMenuButton(
              tooltip: l10n.parentMenuTooltip,
              icon: const Icon(Icons.more_vert),
              lines: const [],
              busy: _signingOut,
              onSignOut: _signOut,
            ),
            const SizedBox(width: EduSpace.s8),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([_scope.connectivity, home]),
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OfflineStrip(state: _scope.connectivity.strip),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      window.gutter,
                      EduSpace.s24,
                      window.gutter,
                      EduSpace.s32,
                    ),
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: EduSize.readingMaxWidth,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: _RecordPanel(home: home),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordPanel extends StatelessWidget {
  const _RecordPanel({required this.home});

  final Loadable<ParentHomeData> home;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = EduPalette.of(context);
    final value = home.value;
    final error = home.error;
    final retry = Padding(
      padding: const EdgeInsets.only(top: EduSpace.s8),
      child: RetryButton(onPressed: home.load, busy: home.isLoading),
    );

    final Widget body;
    if (value != null && value.hasLinkedChild) {
      // A cached name stays on screen even when a later read fails.
      final name = value.linkedStudentName!.trim();
      body = Semantics(
        key: ParentHomeKeys.name,
        header: true,
        container: true,
        label: l10n.parentHomeStudentSemantics(name),
        excludeSemantics: true,
        child: Text(name, style: text.headlineLarge),
      );
    } else if (home.isLoading || (value == null && error == null)) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: SkeletonBar(width: 240, height: 24),
      );
    } else if (value != null) {
      body = BlockMessage(message: l10n.parentHomeNoChild, action: retry);
    } else if (error is OfflineNoCacheError) {
      body = BlockMessage(
        tone: BlockTone.offline,
        message: l10n.parentHomeOfflineNoData,
        action: retry,
      );
    } else {
      body = BlockMessage(
        tone: BlockTone.error,
        message: l10n.parentHomeLoadError,
        action: retry,
      );
    }

    final showLabel = !(value != null && value.hasLinkedChild);
    return Card(
      key: ParentHomeKeys.panel,
      child: Padding(
        padding: EdgeInsets.all(EduDensity.of(context).panelPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The label is merged into the name's semantics when a name
            // shows, so it is excluded there to avoid reading it twice.
            ExcludeSemantics(
              excluding: !showLabel,
              child: Semantics(
                container: true,
                child: Text(
                  l10n.parentHomeStudentLabel,
                  // 500, not 400: an 8-letter muted label at 400 leaves too
                  // few solid pixels for textContrastGuideline's sampling.
                  style: text.bodyMedium!.copyWith(
                    color: palette.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: EduSpace.s8),
            body,
          ],
        ),
      ),
    );
  }
}
