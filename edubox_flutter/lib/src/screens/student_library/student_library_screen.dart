import 'package:edubox_client/edubox_client.dart'
    show LibraryItem, StudentLibrary;
import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../app/app_scope.dart';
import '../../app/formatters.dart';
import '../../app/loadable.dart';
import '../../contract/backend_result.dart';
import '../../features/library/catalogue.dart';
import '../../features/library/content_row.dart';
import '../../shell/block_states.dart';
import '../../shell/student_shell.dart';
import '../../theme/breakpoints.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/tokens.dart';

/// Stable keys for widget and E2E tests.
abstract final class StudentLibraryKeys {
  static const header = Key('studentLibrary.header');
  static const list = Key('studentLibrary.list');
}

/// `student-library` (docs/design/shapes/student-library.md): the
/// catalogue of approved content grouped by subject. Ink only: no dominant
/// accent, no primary action. Rows are not tappable in phase 1.
class StudentLibraryScreen extends StatelessWidget {
  const StudentLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = StudentLibraryScope.of(context).library;
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = EduPalette.of(context);
    final window = WindowClass.of(MediaQuery.sizeOf(context).width);
    final value = library.value;
    final loading = value == null && library.error == null;
    final columns =
        (window == WindowClass.expanded || window == WindowClass.large) &&
            MediaQuery.textScalerOf(context).scale(1) < 1.5
        ? 2
        : 1;
    final maxWidth = columns == 2 ? double.infinity : EduSize.readingMaxWidth;
    final padding = EdgeInsets.symmetric(horizontal: window.gutter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pinned header: the h1 and the total stay in view.
        Padding(
          key: StudentLibraryKeys.header,
          padding: padding.copyWith(
            top: window.isCompact ? EduSpace.s16 : EduSpace.s32,
            bottom: EduSpace.s16,
          ),
          child: _Capped(
            maxWidth: maxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(l10n.libraryTitle, style: text.headlineLarge),
                ),
                const SizedBox(height: EduSpace.s4),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: SkeletonBar(width: 96),
                  )
                else if (value != null)
                  Text(
                    l10n.libraryTotal(value.items.length),
                    style: text.bodyLarge!.copyWith(color: palette.muted),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            key: StudentLibraryKeys.list,
            label: l10n.libraryListSemantics,
            container: true,
            explicitChildNodes: true,
            child: ListView(
              padding: padding.copyWith(bottom: EduSpace.s32),
              children: [
                _Capped(
                  maxWidth: maxWidth,
                  child: _Body(library: library, columns: columns),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Capped extends StatelessWidget {
  const _Capped({required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Full width up to the cap, centred; never shrink-wrapped.
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.library, required this.columns});

  final Loadable<StudentLibrary> library;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = library.value;
    final error = library.error;
    final gap = EduDensity.of(context).gap;

    if (value == null && error == null) {
      return Semantics(
        label: l10n.libraryLoading,
        liveRegion: true,
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var group = 0; group < 2; group++) ...[
              if (group > 0) SizedBox(height: gap),
              const SkeletonBar(width: 140, height: 20),
              const SizedBox(height: EduSpace.s12),
              const _SkeletonPanel(),
            ],
          ],
        ),
      );
    }
    if (value == null) {
      if (error is OfflineNoCacheError) {
        return EduPanel(
          child: BlockMessage(
            tone: BlockTone.offline,
            message: l10n.libraryOfflineNoData,
          ),
        );
      }
      return EduPanel(
        child: BlockMessage(
          tone: BlockTone.error,
          message: l10n.libraryLoadError,
          action: RetryButton(
            onPressed: library.load,
            busy: library.isLoading,
          ),
        ),
      );
    }
    if (value.items.isEmpty) {
      return EduPanel(
        child: Text(
          l10n.libraryEmpty,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: EduPalette.of(context).muted,
          ),
        ),
      );
    }
    final groups = buildCatalogue(value);
    final cachedAt = library.cachedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          EduPanel(
            child: BlockMessage(
              tone: BlockTone.error,
              message: cachedAt == null
                  ? l10n.libraryLoadError
                  : l10n.libraryLoadErrorWithTime(
                      EduFormat.lastGood(
                        cachedAt,
                        AppScope.of(context).services.clock(),
                      ),
                    ),
              action: RetryButton(
                onPressed: library.load,
                busy: library.isLoading,
              ),
            ),
          ),
          SizedBox(height: gap),
        ],
        for (final (index, group) in groups.indexed) ...[
          if (index > 0) SizedBox(height: gap),
          _SubjectGroupView(group: group, columns: columns),
        ],
      ],
    );
  }
}

class _SubjectGroupView extends StatelessWidget {
  const _SubjectGroupView({required this.group, required this.columns});

  final SubjectGroup group;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final window = WindowClass.of(MediaQuery.sizeOf(context).width);
    final heading = group.subject ?? l10n.librarySubjectOther;
    final items = group.items;
    final split = (items.length / 2).ceil();
    final lists = columns == 2
        ? [items.sublist(0, split), items.sublist(split)]
        : [items];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(heading, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: EduSpace.s12),
        EduPanel(
          padding: EdgeInsets.symmetric(
            horizontal: window.isCompact ? EduSpace.s16 : EduSpace.s24,
            vertical: EduSpace.s8,
          ),
          child: lists.length == 1
              ? _Rows(items: lists.first)
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _Rows(items: lists[0])),
                      const SizedBox(width: EduSpace.s24),
                      Expanded(child: _Rows(items: lists[1])),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({required this.items});

  final List<LibraryItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        for (final (index, item) in items.indexed) ...[
          if (index > 0) const Divider(),
          ContentRow(
            item: item,
            semanticsLabel: l10n.libraryItemSemantics(
              item.title,
              contentTypeLabel(l10n, item.type),
            ),
          ),
        ],
      ],
    );
  }
}

class _SkeletonPanel extends StatelessWidget {
  const _SkeletonPanel();

  @override
  Widget build(BuildContext context) {
    final window = WindowClass.of(MediaQuery.sizeOf(context).width);
    return EduPanel(
      padding: EdgeInsets.symmetric(
        horizontal: window.isCompact ? EduSpace.s16 : EduSpace.s24,
        vertical: EduSpace.s24,
      ),
      child: Column(
        children: [
          for (var row = 0; row < 3; row++)
            SizedBox(
              height: EduDensity.of(context).rowHeight,
              child: const Row(
                children: [
                  SkeletonBar(width: 48, height: 64),
                  SizedBox(width: EduSpace.s16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(
                          widthFactor: 0.6,
                          child: SkeletonBar(width: double.infinity),
                        ),
                        SizedBox(height: EduSpace.s8),
                        FractionallySizedBox(
                          widthFactor: 0.25,
                          child: SkeletonBar(
                            width: double.infinity,
                            height: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
