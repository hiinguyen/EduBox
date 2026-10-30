import 'dart:async';

import 'package:edubox_client/edubox_client.dart' show ClassSummary;
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../app/app_scope.dart';
import '../app/connectivity_state.dart';
import '../app/loadable.dart';
import '../contract/backend_result.dart';
import '../screens/teacher_home/teacher_home_screen.dart';
import '../theme/theme_extensions.dart';
import 'account_menu.dart';
import 'offline_strip.dart';
import 'role_shell.dart';

/// The teacher shell: denser, table-forward. Phase 1 has one destination
/// (Tổng quan); the rail renders from 600dp up even with one item so the
/// canvas keeps its width when phase 2 adds "Nội dung". Sign-out is
/// immediate (no confirmation).
class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  Loadable<List<ClassSummary>>? _classes;
  late AppScope _scope;
  bool _signingOut = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = AppScope.of(context);
    if (_classes == null) {
      final classes = Loadable<List<ClassSummary>>(
        _scope.services.backend.classes.mine,
      )..addListener(_onClasses);
      _classes = classes;
      _scope.connectivity.register(classes.load);
      unawaited(classes.load());
    }
  }

  void _onClasses() {
    if (_classes!.error is SessionExpiredError) {
      unawaited(_scope.session.expire());
    }
  }

  @override
  void dispose() {
    final classes = _classes!;
    _scope.connectivity.unregister(classes.load);
    classes
      ..removeListener(_onClasses)
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
    final classes = _classes!;
    final session = _scope.session;
    final profile = session.session?.profile;
    final name = profile?.name ?? '';
    final email = session.session?.signedInEmail ?? '';
    final text = Theme.of(context).textTheme;
    return Theme(
      data: EduDensity.teacher.apply(Theme.of(context)),
      child: ListenableBuilder(
        listenable: Listenable.merge([_scope.connectivity, classes]),
        builder: (context, _) {
          final refreshedAt = session.sessionRefreshedAt;
          final stale =
              classes.isStale &&
              classes.cachedAt != null &&
              refreshedAt != null &&
              classes.cachedAt!.isBefore(refreshedAt);
          return RoleShell(
            title: l10n.navTeacherOverview,
            selectedIndex: 0,
            onSelected: (_) {},
            strip: OfflineStrip(
              state: _scope.connectivity.strip,
              staleWording:
                  stale && _scope.connectivity.strip == StripState.offline,
            ),
            scope: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? email : name, style: text.titleSmall),
                Text(
                  l10n.teacherRoleLabel,
                  style: text.bodyMedium!.copyWith(
                    color: EduPalette.of(context).muted,
                  ),
                ),
              ],
            ),
            footer: RailUserRow(
              lines: [email],
              firstLineIsName: false,
              busy: _signingOut,
              onSignOut: _signOut,
            ),
            accountButton: AccountMenuButton(
              tooltip: l10n.accountMenuTooltip,
              icon: const Icon(Icons.more_vert),
              lines: [if (name.isNotEmpty) name, email],
              busy: _signingOut,
              onSignOut: _signOut,
            ),
            destinations: [
              ShellDestination(
                key: const Key('screen.teacherHome'),
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard_outlined,
                label: l10n.navTeacherOverview,
                body: TeacherHomeScreen(classes: classes),
              ),
            ],
          );
        },
      ),
    );
  }
}
