import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Fields that are always user-facing when they hold a string literal.
const _userFacingFields = {
  'label',
  'hint',
  'tooltip',
  'semanticsLabel',
  'semanticLabel',
  'labelText',
  'hintText',
  'helperText',
  'errorText',
  'counterText',
  'prefixText',
  'suffixText',
  'message',
  'title',
};

/// Constructor-specific string slots, in addition to [_userFacingFields].
const _constructorFields = <String, Set<String>>{
  'Semantics': {'label', 'hint', 'tooltip', 'value'},
  'Tooltip': {'message'},
  'InputDecoration': {
    'labelText',
    'hintText',
    'helperText',
    'errorText',
    'counterText',
    'semanticCounterText',
    'prefixText',
    'suffixText',
  },
  'TextSpan': {'text'},
  'SelectableText': {'data'},
  'MaterialApp': {'title'},
  'AppBar': {'title'},
};

const _positionalTextConstructors = {'Text', 'SelectableText', 'TextSpan'};

void main() {
  test('no UI widget in lib/ passes a hardcoded user-facing string', () {
    final violations = <String>[];
    final root = Directory('lib');
    expect(root.existsSync(), isTrue);
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = p.normalize(entity.path);
      if (normalized.contains('${p.separator}l10n${p.separator}generated')) {
        continue;
      }
      final result = parseString(
        content: entity.readAsStringSync(),
        throwIfDiagnostics: false,
      );
      final visitor = _LiteralVisitor(
        path: normalized,
        lineInfo: result.lineInfo,
        violations: violations,
      );
      result.unit.accept(visitor);
    }

    expect(
      violations,
      isEmpty,
      reason:
          'User-facing strings must come from AppLocalizations. '
          'Offenders:\n${violations.join('\n')}',
    );
  });
}

class _LiteralVisitor extends RecursiveAstVisitor<void> {
  _LiteralVisitor({
    required this.path,
    required this.lineInfo,
    required this.violations,
  });

  final String path;
  final LineInfo lineInfo;
  final List<String> violations;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructor = node.constructorName.type.name.lexeme;
    final named = _constructorFields[constructor] ?? const <String>{};
    for (final argument in node.argumentList.arguments) {
      if (argument is NamedArgument) {
        final name = argument.name.lexeme;
        if ((_userFacingFields.contains(name) || named.contains(name)) &&
            _isLiteral(argument.argumentExpression)) {
          _report(argument.argumentExpression, '$constructor.$name');
        }
      } else if (_positionalTextConstructors.contains(constructor) &&
          argument is Expression &&
          _isLiteral(argument)) {
        _report(argument, '$constructor(...)');
      }
    }
    super.visitInstanceCreationExpression(node);
  }

  static bool _isLiteral(Expression expression) =>
      expression is StringLiteral && expression.stringValue != null;

  void _report(Expression expression, String slot) {
    final location = lineInfo.getLocation(expression.offset);
    violations.add(
      '$path:${location.lineNumber}:${location.columnNumber}: '
      'literal in $slot',
    );
  }
}
