import 'package:flutter/material.dart';

import '../theme/breakpoints.dart';
import '../theme/theme_extensions.dart';
import '../theme/tokens.dart';
import 'edu_mark.dart';

/// Stable keys for widget and E2E tests.
abstract final class RoleShellKeys {
  /// The extended rail's active destination pill, by destination index.
  static Key destinationPill(int index) => Key('shell.destinationPill.$index');
}

/// The shell's fixed keys.
const _railKey = Key('shell.rail');

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
    if (window.hasExtendedRail) return _extendedRail(context);
    return NavigationRail(
      key: _railKey,
      minWidth: EduSize.railCollapsed,
      labelType: NavigationRailLabelType.all,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      leading: const Padding(
        padding: EdgeInsets.only(
          top: EduSpace.s16,
          bottom: EduSpace.s24,
        ),
        child: EduMarkGlyph(),
      ),
      trailingAtBottom: true,
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: EduSpace.s16),
        child: title == null ? accountButton : const SizedBox.shrink(),
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

  /// The large-class 240dp rail: destinations are icon + label rows, and
  /// the selected row's label sits inside the neutral `active` pill.
  Widget _extendedRail(BuildContext context) {
    return SizedBox(
      key: _railKey,
      width: EduSize.railExtended,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EduSpace.s24,
              EduSpace.s16,
              EduSpace.s24,
              EduSpace.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EduLockup(),
                const SizedBox(height: EduSpace.s16),
                scope,
              ],
            ),
          ),
          for (final (index, destination) in destinations.indexed)
            _ExtendedDestination(
              destination: destination,
              selected: index == selectedIndex,
              pillKey: RoleShellKeys.destinationPill(index),
              onTap: () => onSelected(index),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EduSpace.s24,
              0,
              EduSpace.s24,
              EduSpace.s16,
            ),
            child: footer,
          ),
        ],
      ),
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

/// One extended-rail destination: a 48dp row whose selected state is the
/// neutral `active` pill around the icon and its label.
class _ExtendedDestination extends StatelessWidget {
  const _ExtendedDestination({
    required this.destination,
    required this.selected,
    required this.pillKey,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final Key pillKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = EduPalette.of(context);
    final text = Theme.of(context).textTheme;
    final color = selected ? palette.ink : palette.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EduSpace.s16,
        vertical: 2,
      ),
      child: Semantics(
        selected: selected,
        button: true,
        child: SizedBox(
          height: EduSize.tapTarget,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(EduRadius.control),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AnimatedContainer(
                  key: pillKey,
                  duration: EduMotion.fast,
                  height: 40,
                  padding: const EdgeInsets.symmetric(
                    horizontal: EduSpace.s12,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? palette.active : Colors.transparent,
                    borderRadius: BorderRadius.circular(EduRadius.control),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? destination.selectedIcon : destination.icon,
                        size: 20,
                        color: color,
                      ),
                      const SizedBox(width: EduSpace.s12),
                      Text(
                        destination.label,
                        style: text.labelMedium!.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
