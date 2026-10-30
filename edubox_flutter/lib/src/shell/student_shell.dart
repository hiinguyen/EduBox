import 'dart:async';

import 'package:edubox_client/edubox_client.dart' show StudentLibrary;
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../app/app_scope.dart';
import '../app/connectivity_state.dart';
import '../app/formatters.dart';
import '../app/loadable.dart';
import '../contract/backend_result.dart';
import '../screens/student_home/student_home_screen.dart';
import '../theme/theme_extensions.dart';
import 'account_menu.dart';
import 'offline_strip.dart';
import 'role_shell.dart';
import 'sign_out_dialog.dart';

/// The student's one library query, shared by home and library (one
/// provider, one cache), plus the "open the library" navigation.
class StudentLibraryScope extends InheritedNotifier<Loadable<StudentLibrary>> {
  const StudentLibraryScope({
    super.key,
    required Loadable<StudentLibrary> library,
    required this.openLibrary,
    required super.child,
  }) : super(notifier: library);

  final VoidCallback openLibrary;

  static StudentLibraryScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<StudentLibraryScope>();
    assert(scope != null, 'No StudentLibraryScope above this widget.');
    return scope!;
  }

  Loadable<StudentLibrary> get library => notifier!;
}

/// Student destinations, in their fixed order. Phase 1 ships two.
enum StudentDestination { home, library }

/// The student shell: generous density, rail or bottom bar by width,
/// sign-out with confirmation.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key, this.libraryBuilder});

  /// Builds the Thư viện destination; null until the library screen ships.
  final WidgetBuilder? libraryBuilder;

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  Loadable<StudentLibrary>? _library;
  late AppScope _scope;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = AppScope.of(context);
    if (_library == null) {
      final library = Loadable<StudentLibrary>(
        _scope.services.backend.library.library,
      )..addListener(_onLibrary);
      _library = library;
      _scope.connectivity.register(library.load);
      unawaited(library.load());
    }
  }

  void _onLibrary() {
    if (_library!.error is SessionExpiredError) {
      unawaited(_scope.session.expire());
    }
  }

  @override
  void dispose() {
    final library = _library!;
    _scope.connectivity.unregister(library.load);
    library
      ..removeListener(_onLibrary)
      ..dispose();
    super.dispose();
  }

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final library = _library!;
    final session = _scope.session;
    final name = session.session?.profile?.name ?? '';
    return Theme(
      data: EduDensity.student.apply(Theme.of(context)),
      child: StudentLibraryScope(
        library: library,
        openLibrary: () {
          if (widget.libraryBuilder != null) {
            _select(StudentDestination.library.index);
          }
        },
        child: ListenableBuilder(
          listenable: Listenable.merge([_scope.connectivity, library]),
          builder: (context, _) {
            final classNames = EduFormat.joinValues(
              library.value?.classes.map((c) => c.name) ?? const [],
            );
            final refreshedAt = session.sessionRefreshedAt;
            final staleLibrary =
                _index == StudentDestination.library.index &&
                library.isStale &&
                library.cachedAt != null &&
                refreshedAt != null &&
                library.cachedAt!.isBefore(refreshedAt);
            final details = [name, if (classNames.isNotEmpty) classNames];
            return RoleShell(
              selectedIndex: _index,
              onSelected: _select,
              strip: OfflineStrip(
                state: _scope.connectivity.strip,
                staleWording:
                    staleLibrary &&
                    _scope.connectivity.strip == StripState.offline,
              ),
              scope: Text(
                classNames,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              footer: RailUserRow(
                leading: InitialsDisc(initials: EduFormat.initials(name)),
                lines: details,
                onSignOut: () => showStudentSignOutDialog(context),
              ),
              accountButton: AccountMenuButton(
                tooltip: l10n.accountMenuTooltip,
                icon: InitialsDisc(initials: EduFormat.initials(name)),
                lines: details,
                onSignOut: () => showStudentSignOutDialog(context),
              ),
              destinations: [
                ShellDestination(
                  key: const Key('screen.studentHome'),
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_outlined,
                  label: l10n.navHome,
                  body: const StudentHomeScreen(),
                ),
                if (widget.libraryBuilder != null)
                  ShellDestination(
                    key: const Key('screen.studentLibrary'),
                    icon: Icons.local_library_outlined,
                    selectedIcon: Icons.local_library_outlined,
                    label: l10n.navLibrary,
                    body: Builder(builder: widget.libraryBuilder!),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
