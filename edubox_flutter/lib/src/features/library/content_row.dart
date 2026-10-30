import 'package:edubox_client/edubox_client.dart' show ContentType, LibraryItem;
import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../shell/block_states.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/tokens.dart';

/// The visible type word: "Sách", "Video", "Bài tập".
String contentTypeLabel(AppLocalizations l10n, ContentType type) =>
    switch (type) {
      ContentType.ebook => l10n.contentTypeEbook,
      ContentType.video => l10n.contentTypeVideo,
      ContentType.exercise => l10n.contentTypeExercise,
    };

IconData _typeGlyph(ContentType type) => switch (type) {
  ContentType.ebook => Icons.menu_book_outlined,
  ContentType.video => Icons.play_circle_outline,
  ContentType.exercise => Icons.edit_note_outlined,
};

/// One catalogue row, shared by student-home and student-library: a
/// 48x64 cover slot (decorative glyph until phase 2 covers), the title
/// (up to 2 lines, 3 at 1.5x text) and a muted meta line. Not tappable in
/// phase 1: no ripple, no chevron, no focus stop. One semantics node.
class ContentRow extends StatelessWidget {
  const ContentRow({
    super.key,
    required this.item,
    required this.semanticsLabel,
    this.subject,
  });

  final LibraryItem item;

  /// `contentRowSemantics` on the home, `libraryItemSemantics` in the
  /// library.
  final String semanticsLabel;

  /// Shown after the type word on the home ("Sách · Toán"); null in the
  /// library, where the subject is the group heading.
  final String? subject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = EduPalette.of(context);
    final text = Theme.of(context).textTheme;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final meta = text.bodyMedium!.copyWith(color: palette.muted);
    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: EduDensity.of(context).rowHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: EduSpace.s4),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 64,
                decoration: BoxDecoration(
                  color: palette.sheet,
                  border: Border.all(color: palette.rule),
                  borderRadius: BorderRadius.circular(EduRadius.small),
                ),
                child: Icon(
                  _typeGlyph(item.type),
                  size: 24,
                  color: palette.muted,
                ),
              ),
              const SizedBox(width: EduSpace.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: scale >= 1.5 ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium,
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(contentTypeLabel(l10n, item.type), style: meta),
                        if (subject != null && subject!.isNotEmpty) ...[
                          const MetaDot(),
                          Text(subject!, style: meta),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
