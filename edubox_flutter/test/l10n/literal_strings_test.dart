import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'literal_string_scanner.dart';

void main() {
  test('no UI widget in lib/ passes a hardcoded user-facing string', () {
    final violations = <LiteralViolation>[];
    final root = Directory('lib');
    expect(root.existsSync(), isTrue);
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = p.normalize(entity.path);
      if (normalized.contains('${p.separator}l10n${p.separator}generated')) {
        continue;
      }
      violations.addAll(
        findLiteralStrings(
          path: normalized,
          content: entity.readAsStringSync(),
        ),
      );
    }

    expect(
      violations,
      isEmpty,
      reason:
          'User-facing strings must come from AppLocalizations. '
          'Offenders:\n${violations.join('\n')}',
    );
  });

  test(
    'the scanner catches every widget-call form, including interpolation',
    () {
      const source = r'''
import 'package:flutter/material.dart';

void plant(BuildContext context) {
  Text('Xin chào');
  const Text('Xin chào');
  const Text('Chào $name');
  Semantics(
    label: 'Nhãn',
    hint: 'Gợi ý',
    child: Tooltip(message: 'Mẹo', child: Text('Con')),
  );
  InputDecoration(labelText: 'Email', errorText: 'Sai');
  SnackBar(content: Text('Đã lưu'), action: SnackBarAction(label: 'Hoàn tác', onPressed: () {}));
  AppBar(title: Text('Trang'));
  TextSpan(text: 'Đoạn');
  SelectableText('Chọn');
  Text(AppLocalizations.of(context)!.retry);
}
''';
      final violations = findLiteralStrings(
        path: 'lib/planted.dart',
        content: source,
      );
      final slots = violations.map((violation) => violation.slot).toList();
      expect(slots, contains('Text(...)'));
      expect(slots, contains('Semantics.label'));
      expect(slots, contains('Semantics.hint'));
      expect(slots, contains('Tooltip.message'));
      expect(slots, contains('InputDecoration.labelText'));
      expect(slots, contains('InputDecoration.errorText'));
      expect(slots, contains('SnackBarAction.label'));
      expect(slots, contains('TextSpan.text'));
      expect(slots, contains('SelectableText(...)'));
      // The interpolated `Chào $name` and the nested literal `Con` too.
      expect(violations.length, greaterThanOrEqualTo(12));
    },
  );

  test(
    'the scanner passes an l10n lookup and honours an explicit allowlist',
    () {
      const l10nSource = r'''
import 'package:flutter/material.dart';

Widget ok(BuildContext context) =>
    Text(AppLocalizations.of(context)!.studentHomeGreeting('An'));
''';
      expect(
        findLiteralStrings(path: 'lib/ok.dart', content: l10nSource),
        isEmpty,
      );

      const allowlistedSource = "Widget ok() => const Text('EduBox');";
      expect(
        findLiteralStrings(
          path: 'lib/allowed.dart',
          content: allowlistedSource,
          allowlist: const {
            'lib/allowed.dart': {'EduBox'},
          },
        ),
        isEmpty,
      );
    },
  );
}
