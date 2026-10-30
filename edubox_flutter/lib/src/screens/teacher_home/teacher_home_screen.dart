import 'package:edubox_client/edubox_client.dart' show ClassSummary;
import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../app/app_scope.dart';
import '../../app/formatters.dart';
import '../../app/loadable.dart';
import '../../contract/backend_result.dart';
import '../../shell/block_states.dart';
import '../../theme/breakpoints.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/tokens.dart';

/// Stable keys for widget and E2E tests.
abstract final class TeacherHomeKeys {
  static const panel = Key('teacherHome.classesPanel');
  static const table = Key('teacherHome.table');
  static const stacked = Key('teacherHome.stacked');
  static const tableSkeleton = Key('teacherHome.tableSkeleton');
  static const stackedSkeleton = Key('teacherHome.stackedSkeleton');
}

/// Classes sorted by grade (numeric), then name (Vietnamese-aware).
List<ClassSummary> sortClasses(List<ClassSummary> classes) =>
    [...classes]..sort((a, b) {
      final byGrade = a.gradeLevel.compareTo(b.gradeLevel);
      return byGrade != 0 ? byGrade : compareVietnamese(a.name, b.name);
    });

/// The four columns fit only on a compact-free width at normal text scale;
/// otherwise every value carries its own unit or label on two lines.
bool _usesStackedRows(
  BuildContext context,
  double maxWidth,
  bool compact,
) {
  final scale = MediaQuery.textScalerOf(context).scale(1);
  return compact || scale >= 1.5 || maxWidth < 560;
}

/// `teacher-home` (docs/design/shapes/teacher-home.md): the "Lớp của tôi"
/// ledger (Lớp | Khối | Môn học | Học sinh). No dominant accent and no
/// primary action in phase 1. Rows are not tappable.
class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key, required this.classes});

  final Loadable<List<ClassSummary>> classes;

  @override
  Widget build(BuildContext context) {
    final window = WindowClass.of(MediaQuery.sizeOf(context).width);
    final density = EduDensity.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        window.gutter,
        density.gap,
        window.gutter,
        EduSpace.s32,
      ),
      children: [
        Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: EduSize.readingMaxWidth,
            ),
            child: _ClassesPanel(classes: classes, compact: window.isCompact),
          ),
        ),
      ],
    );
  }
}

class _ClassesPanel extends StatelessWidget {
  const _ClassesPanel({required this.classes, required this.compact});

  final Loadable<List<ClassSummary>> classes;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final value = classes.value;
    final error = classes.error;
    final extras = EduTypeExtras.of(context);
    final palette = EduPalette.of(context);

    final Widget body;
    if (value == null && error == null) {
      body = Semantics(
        label: l10n.teacherClassesLoading,
        liveRegion: true,
        container: true,
        child: _Skeleton(compact: compact),
      );
    } else if (value == null) {
      body = error is OfflineNoCacheError
          ? BlockMessage(
              tone: BlockTone.offline,
              message: l10n.teacherClassesOfflineNoData,
              messageStyle: text.bodyMedium,
            )
          : BlockMessage(
              tone: BlockTone.error,
              message: l10n.teacherClassesError,
              messageStyle: text.bodyMedium,
              action: RetryButton(
                onPressed: classes.load,
                busy: classes.isLoading,
              ),
            );
    } else if (value.isEmpty) {
      body = Text(
        l10n.teacherClassesEmpty,
        style: text.bodyMedium!.copyWith(color: palette.muted),
      );
    } else {
      final sorted = sortClasses(value);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: EduSpace.s16),
              child: BlockMessage(
                tone: BlockTone.error,
                messageStyle: text.bodyMedium,
                message: classes.cachedAt == null
                    ? l10n.teacherClassesError
                    : l10n.teacherClassesStaleError(
                        EduFormat.lastGood(
                          classes.cachedAt!,
                          AppScope.of(context).services.clock(),
                        ),
                      ),
                action: RetryButton(
                  onPressed: classes.load,
                  busy: classes.isLoading,
                ),
              ),
            ),
          Semantics(
            liveRegion: true,
            label: l10n.teacherClassesLoaded(sorted.length),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _usesStackedRows(context, constraints.maxWidth, compact)
                    ? _StackedRows(classes: sorted)
                    : _Table(classes: sorted);
              },
            ),
          ),
        ],
      );
    }

    return Card(
      key: TeacherHomeKeys.panel,
      child: Padding(
        padding: EdgeInsets.all(EduDensity.of(context).panelPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.teacherClassesTitle,
                      style: text.titleSmall,
                    ),
                  ),
                ),
                if (value != null)
                  Text(
                    l10n.teacherClassesCount(value.length),
                    style: extras.timestamp,
                  ),
              ],
            ),
            const SizedBox(height: EduSpace.s12),
            body,
          ],
        ),
      ),
    );
  }
}

/// Column flex: identity column 35-45% and never truncated.
const _flex = [8, 3, 8, 3];

class _Table extends StatelessWidget {
  const _Table({required this.classes});

  final List<ClassSummary> classes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final extras = EduTypeExtras.of(context);
    final palette = EduPalette.of(context);
    final header = text.bodySmall!.copyWith(color: palette.muted);
    return Column(
      key: TeacherHomeKeys.table,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header texts are excluded: each row label carries the column names.
        ExcludeSemantics(
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  flex: _flex[0],
                  child: Text(l10n.classColumnName, style: header),
                ),
                Expanded(
                  flex: _flex[1],
                  child: Text(l10n.classColumnGrade, style: header),
                ),
                Expanded(
                  flex: _flex[2],
                  child: Text(l10n.classColumnSubjects, style: header),
                ),
                Expanded(
                  flex: _flex[3],
                  child: Text(
                    l10n.classColumnStudents,
                    style: header,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        for (final (index, item) in classes.indexed) ...[
          if (index > 0) const Divider(),
          Semantics(
            container: true,
            excludeSemantics: true,
            label: _rowLabel(l10n, item),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: index == classes.length - 1
                    ? 0
                    : EduDensity.of(context).rowHeight,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: EduSpace.s12,
                  bottom: index == classes.length - 1 ? 0 : EduSpace.s12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: _flex[0],
                      child: Text(item.name, style: text.titleSmall),
                    ),
                    Expanded(
                      flex: _flex[1],
                      child: Text(
                        EduFormat.figure(item.gradeLevel),
                        style: extras.figureTeacher,
                      ),
                    ),
                    Expanded(
                      flex: _flex[2],
                      child: _Subjects(subjects: item.subjects, maxLines: 3),
                    ),
                    Expanded(
                      flex: _flex[3],
                      child: Text(
                        EduFormat.figure(item.studentCount),
                        style: extras.figureTeacher,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StackedRows extends StatelessWidget {
  const _StackedRows({required this.classes});

  final List<ClassSummary> classes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final extras = EduTypeExtras.of(context);
    final palette = EduPalette.of(context);
    final muted = text.bodyMedium!.copyWith(color: palette.muted);
    return Column(
      key: TeacherHomeKeys.stacked,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, item) in classes.indexed) ...[
          if (index > 0) const Divider(),
          Semantics(
            container: true,
            excludeSemantics: true,
            label: _rowLabel(l10n, item),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: index == classes.length - 1 ? 0 : 64,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: EduSpace.s12,
                  bottom: index == classes.length - 1 ? 0 : EduSpace.s12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(item.name, style: text.titleSmall),
                        ),
                        Text(
                          l10n.classStudentCount(item.studentCount),
                          style: extras.figureTeacher,
                        ),
                      ],
                    ),
                    const SizedBox(height: EduSpace.s4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.classGradeValue(item.gradeLevel),
                          style: extras.figureTeacher,
                        ),
                        const MetaDot(),
                        _Subjects(subjects: item.subjects, style: muted),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Subjects joined for display, or the grey "-" when there are none.
class _Subjects extends StatelessWidget {
  const _Subjects({required this.subjects, this.maxLines, this.style});

  final List<String> subjects;
  final int? maxLines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    if (subjects.isEmpty) {
      return Text(
        l10n.valueMissing,
        style: text.bodyMedium!.copyWith(color: EduPalette.of(context).muted),
      );
    }
    return Text(
      EduFormat.joinValues(subjects),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: style ?? text.bodyMedium,
    );
  }
}

String _rowLabel(AppLocalizations l10n, ClassSummary item) =>
    l10n.classRowSemantics(
      item.name,
      item.gradeLevel,
      item.subjects.isEmpty
          ? l10n.valueMissing
          : EduFormat.joinValues(item.subjects),
      item.studentCount,
    );

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _usesStackedRows(context, constraints.maxWidth, compact)
            ? const _StackedSkeleton()
            : const _TableSkeleton();
      },
    );
  }
}

/// The wide ledger's loading frame: the four column heads and three rows.
class _TableSkeleton extends StatelessWidget {
  const _TableSkeleton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final header = Theme.of(context).textTheme.bodySmall;
    return Column(
      key: TeacherHomeKeys.tableSkeleton,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  flex: _flex[0],
                  child: Text(l10n.classColumnName, style: header),
                ),
                Expanded(
                  flex: _flex[1],
                  child: Text(l10n.classColumnGrade, style: header),
                ),
                Expanded(
                  flex: _flex[2],
                  child: Text(l10n.classColumnSubjects, style: header),
                ),
                Expanded(
                  flex: _flex[3],
                  child: Text(
                    l10n.classColumnStudents,
                    style: header,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        for (var row = 0; row < 3; row++)
          SizedBox(
            height: EduDensity.of(context).rowHeight,
            child: Row(
              children: [
                Expanded(
                  flex: _flex[0],
                  child: const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SkeletonBar(width: 120, height: 14),
                  ),
                ),
                Expanded(
                  flex: _flex[1],
                  child: const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SkeletonBar(width: 24, height: 14),
                  ),
                ),
                Expanded(
                  flex: _flex[2],
                  child: const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SkeletonBar(width: 160, height: 14),
                  ),
                ),
                Expanded(
                  flex: _flex[3],
                  child: const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: SkeletonBar(width: 24, height: 14),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The stacked loading frame: no column heads, two bookkeeping lines per
/// row, in the same order the loaded stacked rows use.
class _StackedSkeleton extends StatelessWidget {
  const _StackedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: TeacherHomeKeys.stackedSkeleton,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var row = 0; row < 3; row++) ...[
          if (row > 0) const Divider(),
          const SizedBox(
            height: 64,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: EduSpace.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: SkeletonBar(width: 120, height: 14),
                        ),
                      ),
                      SkeletonBar(width: 64, height: 14),
                    ],
                  ),
                  SizedBox(height: EduSpace.s4),
                  Row(
                    children: [
                      SkeletonBar(width: 40, height: 12),
                      SizedBox(width: EduSpace.s8),
                      SkeletonBar(width: 160, height: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
