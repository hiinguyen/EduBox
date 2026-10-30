import 'package:edubox_client/edubox_client.dart' show StudentLibrary;
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
abstract final class StudentHomeKeys {
  static const greeting = Key('studentHome.greeting');
  static const panel = Key('studentHome.libraryPanel');
  static const openLibrary = Key('studentHome.openLibrary');
}

/// `student-home` (docs/design/shapes/student-home.md): greeting, class
/// and date, then "Mới thêm vào thư viện" with the newest 4 approved items,
/// the total and "Mở thư viện" (the screen's one accent).
class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final libraryScope = StudentLibraryScope.of(context);
    final library = libraryScope.library;
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = EduPalette.of(context);
    final window = WindowClass.of(MediaQuery.sizeOf(context).width);

    final profileFailed =
        !library.hasValue &&
        (library.error is NotSetUpError ||
            library.error is PermissionDeniedError);
    final given = EduFormat.givenName(
      scope.session.session?.profile?.name ?? '',
    );
    final greeting = profileFailed || given.isEmpty
        ? l10n.studentHomeGreetingNoName
        : l10n.studentHomeGreeting(given);
    final date = EduFormat.weekdayDate(scope.services.clock());
    final classNames = EduFormat.joinValues(
      library.value?.classes.map((c) => c.name) ?? const [],
    );
    final dateLine = classNames.isEmpty
        ? l10n.studentHomeDateOnly(date)
        : l10n.studentHomeDateLine(classNames, date);
    final loadingNames = !library.hasValue && library.error == null;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        window.gutter,
        window.isCompact ? EduSpace.s16 : EduSpace.s32,
        window.gutter,
        EduSpace.s32,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: EduSize.readingMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // One heading node: the greeting and the class/date line
                // merge into it (no composed label string).
                MergeSemantics(
                  key: StudentHomeKeys.greeting,
                  child: Semantics(
                    header: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting, style: text.displayMedium),
                        const SizedBox(height: EduSpace.s4),
                        if (loadingNames)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: SkeletonBar(width: 220),
                          )
                        else
                          Text(
                            dateLine,
                            style: text.bodyLarge!.copyWith(
                              color: palette.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: EduSpace.s24),
                _LibraryPanel(
                  library: library,
                  onOpenLibrary: libraryScope.openLibrary,
                  compact: window.isCompact,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LibraryPanel extends StatelessWidget {
  const _LibraryPanel({
    required this.library,
    required this.onOpenLibrary,
    required this.compact,
  });

  final Loadable<StudentLibrary> library;
  final VoidCallback onOpenLibrary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final value = library.value;
    final error = library.error;
    final noClass = value != null && value.classes.isEmpty;
    final showButton = !noClass;

    final Widget body;
    if (value == null && error == null) {
      body = Semantics(
        label: l10n.studentHomeLoadingLibrary,
        liveRegion: true,
        container: true,
        child: Column(
          children: [for (var i = 0; i < 4; i++) const _SkeletonRow()],
        ),
      );
    } else if (value == null) {
      body = BlockMessage(
        tone: BlockTone.error,
        message: switch (error) {
          OfflineNoCacheError() => l10n.studentHomeLibraryOfflineNoCache,
          NotSetUpError() ||
          PermissionDeniedError() => l10n.studentHomeProfileError,
          _ => l10n.studentHomeLibraryError,
        },
        action: RetryButton(
          onPressed: library.load,
          busy: library.isLoading,
        ),
      );
    } else if (noClass) {
      body = BlockMessage(
        message: l10n.studentNoClass,
        hint: l10n.studentNoClassHint,
      );
    } else if (value.items.isEmpty) {
      body = BlockMessage(
        message: l10n.libraryEmpty,
        hint: l10n.libraryEmptyHint,
      );
    } else {
      final newest = newestItems(value);
      body = Column(
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: EduSpace.s16),
              child: BlockMessage(
                tone: BlockTone.error,
                message: l10n.studentHomeLibraryError,
                hint: library.cachedAt == null
                    ? null
                    : l10n.lastUpdatedAt(
                        EduFormat.lastGood(
                          library.cachedAt!,
                          AppScope.of(context).services.clock(),
                        ),
                      ),
                action: RetryButton(
                  onPressed: library.load,
                  busy: library.isLoading,
                ),
              ),
            ),
          for (final (index, item) in newest.indexed) ...[
            if (index > 0) const Divider(),
            ContentRow(
              item: item,
              subject: item.subject,
              semanticsLabel: l10n.contentRowSemantics(
                item.title,
                contentTypeLabel(l10n, item.type),
                item.subject,
              ),
            ),
          ],
        ],
      );
    }

    return Card(
      key: StudentHomeKeys.panel,
      child: Padding(
        padding: EdgeInsets.all(EduDensity.of(context).panelPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.studentHomeLibraryTitle, style: text.titleLarge),
            if (value != null && !noClass && value.items.isNotEmpty)
              Text(
                l10n.studentHomeLibraryCount(value.items.length),
                style: text.bodySmall,
              )
            else if (value == null && error == null)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: SkeletonBar(width: 140, height: 12),
              ),
            const SizedBox(height: EduSpace.s16),
            body,
            if (showButton) ...[
              const SizedBox(height: EduSpace.s24),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  height: EduSize.primaryButton,
                  width: compact ? double.infinity : null,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 160),
                    child: FilledButton(
                      key: StudentHomeKeys.openLibrary,
                      onPressed: onOpenLibrary,
                      child: Text(l10n.studentHomeOpenLibrary),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                SkeletonBar(width: 220),
                SizedBox(height: EduSpace.s8),
                SkeletonBar(width: 96, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
