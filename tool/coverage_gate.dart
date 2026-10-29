import 'dart:io';

/// Phase 1 coverage gate (roadmap exit criterion 14).
///
/// Reads an lcov file produced by `dart test --coverage` and enforces 80%
/// line coverage for each existing gated source directory. Directories that
/// do not exist yet are skipped, as the roadmap requires.
void main(List<String> args) {
  final path = args.isEmpty ? 'coverage/lcov.info' : args.first;
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('coverage gate: missing $path');
    exitCode = 2;
    return;
  }

  const gates = <String, String>{
    'authorization': 'lib/src/authz/',
    'grading': 'lib/src/grading/',
    'rate-limit': 'lib/src/ratelimit/',
    'lockout': 'lib/src/lockout/',
  };

  final lines = <String, Map<int, int>>{};
  String? current;
  for (final raw in file.readAsLinesSync()) {
    if (raw.startsWith('SF:')) {
      var source = raw.substring(3).replaceAll('\\', '/');
      final lib = source.indexOf('/lib/');
      if (lib >= 0) source = source.substring(lib + 1);
      current = source;
      lines.putIfAbsent(current, () => {});
    } else if (raw.startsWith('DA:') && current != null) {
      final parts = raw.substring(3).split(',');
      if (parts.length >= 2) {
        final line = int.tryParse(parts[0]);
        final count = int.tryParse(parts[1]);
        if (line != null && count != null) lines[current]![line] = count;
      }
    }
  }

  var failed = false;
  var gated = 0;
  for (final MapEntry(key: name, value: prefix) in gates.entries) {
    final records = lines.entries.where(
      (entry) => entry.key.startsWith(prefix),
    );
    if (records.isEmpty) {
      stdout.writeln('coverage gate: $name skipped (no source directory)');
      continue;
    }
    gated++;
    var found = 0;
    var hit = 0;
    for (final record in records) {
      for (final count in record.value.values) {
        found++;
        if (count > 0) hit++;
      }
    }
    final percent = found == 0 ? 100.0 : hit * 100 / found;
    final ok = percent >= 80;
    stdout.writeln(
      'coverage gate: $name ${percent.toStringAsFixed(1)}% '
      '($hit/$found lines) ${ok ? 'PASS' : 'FAIL'}',
    );
    if (!ok) failed = true;
  }

  if (gated == 0) {
    stdout.writeln('coverage gate: no gated directories exist yet');
  }
  if (failed) {
    stderr.writeln('coverage gate: at least one module is below 80%');
    exitCode = 1;
  }
}
