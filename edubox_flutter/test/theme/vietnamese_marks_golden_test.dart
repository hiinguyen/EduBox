import 'package:edubox_flutter/src/theme/edu_theme.dart';
import 'package:edubox_flutter/src/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test-only sample text (test/ is not scanned by the l10n literal test).
const _marks = 'ẬẤỖỘỄ ặỵ Đđ';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('Vietnamese stacked marks never clip at ${scale}x', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final theme = buildEduTheme();
      final t = theme.textTheme;
      final x = theme.extension<EduTypeExtras>()!;
      final styles = <TextStyle?>[
        t.displayLarge,
        t.displayMedium,
        t.headlineLarge,
        t.headlineMedium,
        t.titleLarge,
        t.titleMedium,
        t.titleSmall,
        t.bodyLarge,
        t.bodyMedium,
        t.bodySmall,
        t.labelLarge,
        t.labelMedium,
        x.figure,
        x.timestamp,
        x.monoBody,
      ];
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: RepaintBoundary(
                key: const Key('marks'),
                child: ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final style in styles) Text(_marks, style: style),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byKey(const Key('marks')),
        matchesGoldenFile('goldens/vietnamese_marks_${scale}x.png'),
      );
    });
  }
}
