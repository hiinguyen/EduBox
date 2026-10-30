import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

/// One hardcoded user-facing string found in a Dart source file.
class LiteralViolation {
  const LiteralViolation({
    required this.path,
    required this.line,
    required this.column,
    required this.slot,
  });

  final String path;
  final int line;
  final int column;
  final String slot;

  @override
  String toString() => '$path:$line:$column: literal in $slot';
}

/// Literals that are allowed in a text slot because they are not
/// translatable copy. Keys and asset paths are not text slots, so they never
/// reach this allowlist; test-only code lives under `test/` and is not
/// scanned. Keep this map empty unless a literal is genuinely not copy.
const Map<String, Set<String>> allowlistedLiterals = {};

/// Named arguments that display text whenever a widget or constructor
/// receives them. This covers any widget, not only the constructors listed
/// below.
const Set<String> _userFacingNames = {
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
  'semanticCounterText',
  'prefixText',
  'suffixText',
  'message',
  'title',
  'value',
  'text',
  'data',
  'content',
};

/// Constructor-specific slots in addition to [_userFacingNames].
const Map<String, Set<String>> _constructorSlots = {
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

/// Constructors whose first positional argument is displayed text.
const Set<String> _positionalTextConstructors = {
  'Text',
  'SelectableText',
  'TextSpan',
};

/// Scans [content] and returns every hardcoded user-facing string.
///
/// Both `const Text('...')` (an `InstanceCreationExpression`) and
/// `Text('...')` (a `MethodInvocation`) are inspected, as are interpolated
/// strings. The parser is chosen deliberately: it sees every call, including
/// calls inside widget builders that are never const.
List<LiteralViolation> findLiteralStrings({
  required String path,
  required String content,
  Map<String, Set<String>> allowlist = allowlistedLiterals,
}) {
  final result = parseString(content: content, throwIfDiagnostics: false);
  final visitor = _LiteralVisitor(
    path: path,
    lineInfo: result.lineInfo,
    allowlist: allowlist,
  );
  result.unit.accept(visitor);
  return visitor.violations;
}

class _LiteralVisitor extends RecursiveAstVisitor<void> {
  _LiteralVisitor({
    required this.path,
    required this.lineInfo,
    required this.allowlist,
  });

  final String path;
  final LineInfo lineInfo;
  final Map<String, Set<String>> allowlist;
  final List<LiteralViolation> violations = [];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final name = node.constructorName.type.name.lexeme;
    _inspectArguments(
      node.argumentList.arguments,
      constructor: name,
    );
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // `Text('...')` without `const` is a MethodInvocation. Ignore method
    // calls on a target (`foo.text('...')`), which are not widget
    // constructors.
    if (node.target == null) {
      _inspectArguments(
        node.argumentList.arguments,
        constructor: node.methodName.name,
      );
    }
    super.visitMethodInvocation(node);
  }

  void _inspectArguments(
    NodeList<Argument> arguments, {
    required String constructor,
  }) {
    final constructorSlots = _constructorSlots[constructor] ?? const <String>{};
    for (final argument in arguments) {
      if (argument is NamedArgument) {
        final name = argument.name.lexeme;
        if (_userFacingNames.contains(name) ||
            constructorSlots.contains(name)) {
          for (final literal in _literalOperands(
            argument.argumentExpression,
          )) {
            _report(literal, '$constructor.$name');
          }
        }
      } else if (_positionalTextConstructors.contains(constructor) &&
          argument is Expression) {
        for (final literal in _literalOperands(argument)) {
          _report(literal, '$constructor(...)');
        }
      }
    }
  }

  /// Unwraps expressions that can contain a hardcoded string: parentheses,
  /// `condition ? 'a' : 'b'`, `'a' ?? 'b'`, and casts.
  static Iterable<Expression> _literalOperands(Expression expression) sync* {
    if (expression is ParenthesizedExpression) {
      yield* _literalOperands(expression.expression);
    } else if (expression is ConditionalExpression) {
      yield* _literalOperands(expression.thenExpression);
      yield* _literalOperands(expression.elseExpression);
    } else if (expression is BinaryExpression &&
        expression.operator.type == TokenType.QUESTION_QUESTION) {
      yield* _literalOperands(expression.leftOperand);
      yield* _literalOperands(expression.rightOperand);
    } else if (expression is AsExpression) {
      yield* _literalOperands(expression.expression);
    } else if (_isStringLiteral(expression)) {
      yield expression;
    }
  }

  static bool _isStringLiteral(Expression expression) =>
      expression is StringLiteral || expression is AdjacentStrings;

  void _report(Expression expression, String slot) {
    if (_isAllowlisted(expression)) return;
    final location = lineInfo.getLocation(expression.offset);
    violations.add(
      LiteralViolation(
        path: path,
        line: location.lineNumber,
        column: location.columnNumber,
        slot: slot,
      ),
    );
  }

  bool _isAllowlisted(Expression expression) {
    final values = allowlist[path];
    if (values == null) return false;
    if (expression is StringLiteral) {
      final value = expression.stringValue;
      return value != null && values.contains(value);
    }
    return false;
  }
}
