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
    'the scanner catches every widget-call form, including nested expressions '
    'and + concatenation',
    () {
      const source = r'''
import 'package:flutter/material.dart';

void plant(BuildContext context, bool isOn, String? name) {
  Text('Xin chào');
  const Text('Xin chào');
  const Text('Chào $name');
  Text(isOn ? 'Bật' : 'Tắt');
  Text((isOn ? 'Bật' : null) ?? 'Tắt');
  Text(('Chào' as String));
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
  Text('Chào ' + name!);
  Text(name! + ' ơi' + '!');
  Text(AppLocalizations.of(context)!.retry);
}
''';
      final violations = findLiteralStrings(
        path: 'lib/planted.dart',
        content: source,
      );
      expect(
        violations.map((violation) => violation.slot).toList(),
        [
          'Text(...)',
          'Text(...)',
          'Text(...)',
          'Text(...)',
          'Text(...)',
          'Text(...)',
          'Text(...)',
          'Text(...)',
          'Semantics.label',
          'Semantics.hint',
          'Tooltip.message',
          'Text(...)',
          'InputDecoration.labelText',
          'InputDecoration.errorText',
          'Text(...)',
          'SnackBarAction.label',
          'Text(...)',
          'TextSpan.text',
          'SelectableText(...)',
          'Text(...)',
          'Text(...)',
          'Text(...)',
        ],
      );
      expect(
        violations.map((violation) => '${violation.line}:${violation.column}'),
        [
          '4:8',
          '5:14',
          '6:14',
          '7:15',
          '7:23',
          '8:16',
          '8:33',
          '9:9',
          '11:12',
          '12:11',
          '13:29',
          '13:48',
          '15:30',
          '15:50',
          '16:26',
          '16:67',
          '17:22',
          '18:18',
          '19:18',
          '20:8',
          '21:16',
          '21:24',
        ],
      );
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
