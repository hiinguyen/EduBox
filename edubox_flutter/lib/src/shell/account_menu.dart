import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/theme_extensions.dart';
import '../theme/tokens.dart';

/// An icon button (tooltip = accessible name) that opens a menu with a
/// non-interactive header ([lines]: name, then muted details), a rule, and
/// one "Đăng xuất" item.
class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.lines,
    required this.onSignOut,
    this.busy = false,
  });

  final String tooltip;
  final Widget icon;
  final List<String> lines;
  final VoidCallback onSignOut;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = EduPalette.of(context);
    return MenuAnchor(
      menuChildren: [
        if (lines.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EduSpace.s16,
              EduSpace.s12,
              EduSpace.s16,
              EduSpace.s12,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lines.first, style: text.titleMedium),
                  for (final line in lines.skip(1))
                    Text(
                      line,
                      style: text.bodyMedium!.copyWith(color: palette.muted),
                    ),
                ],
              ),
            ),
          ),
        if (lines.isNotEmpty) const Divider(),
        MenuItemButton(
          key: const Key('shell.menuSignOut'),
          leadingIcon: const Icon(Icons.logout_outlined, size: 18),
          onPressed: busy ? null : onSignOut,
          child: Text(busy ? l10n.signOutBusy : l10n.signOut),
        ),
      ],
      builder: (context, controller, _) => IconButton(
        key: const Key('shell.accountMenu'),
        tooltip: tooltip,
        icon: icon,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// A full-circle initials disc (people are the only circles).
class InitialsDisc extends StatelessWidget {
  const InitialsDisc({super.key, required this.initials, this.size = 32});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = EduPalette.of(context);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.active,
          shape: BoxShape.circle,
        ),
        child: Text(
          initials,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: palette.ink,
          ),
        ),
      ),
    );
  }
}

/// The extended rail's bottom user row: [leading], name and detail lines,
/// then a visible "Đăng xuất" text button (48dp).
class RailUserRow extends StatelessWidget {
  const RailUserRow({
    super.key,
    required this.lines,
    required this.onSignOut,
    this.leading,
    this.busy = false,
    this.firstLineIsName = true,
  });

  final Widget? leading;
  final List<String> lines;
  final VoidCallback onSignOut;
  final bool busy;

  /// False when the first line is not a name (the teacher's email row),
  /// so every line is muted body text.
  final bool firstLineIsName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = EduPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: EduSpace.s8),
            ],
            Expanded(
              // One node for the identity lines ("name\nclass").
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lines.isNotEmpty)
                      Text(
                        lines.first,
                        style: firstLineIsName
                            ? text.titleSmall
                            : text.bodyMedium!.copyWith(color: palette.muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    for (final line in lines.skip(1))
                      Text(
                        line,
                        style: text.bodyMedium!.copyWith(color: palette.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: EduSpace.s8),
        TextButton.icon(
          key: const Key('shell.railSignOut'),
          onPressed: busy ? null : onSignOut,
          icon: const Icon(Icons.logout_outlined, size: 18),
          label: Text(busy ? l10n.signOutBusy : l10n.signOut),
        ),
      ],
    );
  }
}
