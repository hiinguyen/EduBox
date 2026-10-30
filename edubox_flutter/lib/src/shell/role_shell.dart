import 'package:flutter/material.dart';

import '../theme/breakpoints.dart';
import '../theme/theme_extensions.dart';
import '../theme/tokens.dart';
import 'edu_mark.dart';

/// One navigation destination. Register a destination only in the phase
/// that ships its screen: no disabled or "coming soon" items.
class ShellDestination {
  const ShellDestination({
    required this.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.body,
  });

  final Key key;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget body;
}

/// The destination-driven shell shared by the student and teacher roles
/// (app-direction section 6; width decides, never orientation):
///
/// - large (>= 1200): extended 240dp rail on `paper`: lockup, [scope],
///   destinations, and [footer] at the bottom.
///   Arithmetic: 1280 = 240 rail + 32 + 976 content + 32.
/// - medium/expanded (600-1199): 88dp rail with the mark only.
///   Arithmetic: 800 = 88 rail + 24 + 664 content + 24.
/// - compact (< 600): an app bar, and a bottom `NavigationBar` only when
///   there are two or more destinations.
///
/// The active destination is the neutral `active` pill; no accent in the
/// navigation. Each destination keeps its state in an [IndexedStack].
class RoleShell extends StatelessWidget {
  const RoleShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.scope,
    required this.footer,
    required this.accountButton,
    required this.strip,
    this.title,
  });

  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Under the lockup in the extended rail (the class, or the teacher).
  final Widget scope;

  /// The extended rail's bottom user row with its visible sign-out.
  final Widget footer;

  /// The account menu button used below the large window class.
  final Widget accountButton;

  /// The offline / reconnecting strip, at the top of the canvas.
  final Widget strip;

  /// When set, an app bar with this h1 shows at every width and holds
  /// [accountButton] below the large class (teacher). When null, only the
  /// compact class gets an app bar, with the lockup (student).
  final String? title;

  @override
  Widget build(BuildContext context) {
    final window = WindowClass.of(MediaQuery.sizeOf(context).width);
    final body = IndexedStack(
      index: selectedIndex,
      children: [
        for (final destination in destinations)
          KeyedSubtree(key: destination.key, child: destination.body),
      ],
    );
    final appBar = _appBar(context, window);
    // With a rail, the app bar sits over the canvas only; the rail runs the
    // full height. On compact it is the Scaffold's app bar.
    final canvas = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (window.hasRail && appBar != null)
          SizedBox(height: appBar.preferredSize.height, child: appBar),
        strip,
        Expanded(child: body),
      ],
    );
    return Scaffold(
      appBar: window.hasRail ? null : appBar,
      bottomNavigationBar: window.isCompact && destinations.length >= 2
          ? _bottomBar(context)
          : null,
      body: SafeArea(
        child: window.hasRail
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _rail(context, window),
                  Expanded(child: canvas),
                ],
              )
            : canvas,
      ),
    );
  }

  PreferredSizeWidget? _appBar(BuildContext context, WindowClass window) {
    final showAccount = !window.hasExtendedRail;
    if (title != null) {
      return AppBar(
        toolbarHeight: 56,
        // The h1 shares the canvas's left edge with the first panel.
        titleSpacing: window.isCompact ? null : window.gutter,
        titleTextStyle: Theme.of(context).textTheme.headlineMedium,
        leading: window.isCompact
            ? const Padding(
                padding: EdgeInsets.all(EduSpace.s16),
                child: EduMarkGlyph(),
              )
            : null,
        automaticallyImplyLeading: false,
        title: Semantics(header: true, child: Text(title!)),
        actions: [
          if (showAccount) accountButton,
          const SizedBox(width: EduSpace.s8),
        ],
      );
    }
    if (!window.isCompact) return null;
    return AppBar(
      toolbarHeight: 56,
      automaticallyImplyLeading: false,
      title: const EduLockup(),
      actions: [
        accountButton,
        const SizedBox(width: EduSpace.s8),
      ],
    );
  }

  Widget _rail(BuildContext context, WindowClass window) {
    final extended = window.hasExtendedRail;
    return NavigationRail(
      extended: extended,
      minExtendedWidth: EduSize.railExtended,
      minWidth: EduSize.railCollapsed,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      leading: Padding(
        padding: const EdgeInsets.only(
          top: EduSpace.s16,
          bottom: EduSpace.s24,
        ),
        child: extended
            ? SizedBox(
                width: EduSize.railExtended - 2 * EduSpace.s24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EduLockup(),
                    const SizedBox(height: EduSpace.s16),
                    scope,
                  ],
                ),
              )
            : const EduMarkGlyph(),
      ),
      trailingAtBottom: true,
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: EduSpace.s16),
        child: extended
            ? SizedBox(
                width: EduSize.railExtended - 2 * EduSpace.s24,
                child: footer,
              )
            : (title == null ? accountButton : const SizedBox.shrink()),
      ),
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.label),
          ),
      ],
    );
  }

  Widget _bottomBar(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: EduPalette.of(context).rule)),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
