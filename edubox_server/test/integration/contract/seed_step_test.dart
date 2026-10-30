import 'dart:convert';
import 'dart:io';

import 'package:edubox_server/src/seed/seed_command.dart';
import 'package:test/test.dart';

void main() {
  test('seed step CLI names are stable', () {
    expect(SeedStep.tryParse('reset'), SeedStep.reset);
    expect(SeedStep.tryParse('reconnect-library'), SeedStep.reconnectLibrary);
    expect(SeedStep.tryParse('reconnect-classes'), SeedStep.reconnectClasses);
    expect(SeedStep.tryParse('assign-role'), SeedStep.assignRole);
    expect(SeedStep.tryParse('nope'), isNull);
  });

  test('seedResetTables covers every table of the latest migration', () {
    final migrations =
        Directory('migrations')
            .listSync()
            .whereType<Directory>()
            .where(
              (directory) =>
                  File('${directory.path}/definition.json').existsSync(),
            )
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    expect(migrations, isNotEmpty);

    final definition =
        jsonDecode(
              File(
                '${migrations.last.path}/definition.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final tables = (definition['tables'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    final resetTables = seedResetTables.toSet();
    final required = {
      for (final table in tables)
        if (table['module'] == 'edubox' ||
            (table['module'] as String).startsWith('serverpod_auth_'))
          table['name'] as String,
    };

    expect(
      required.difference(resetTables),
      isEmpty,
      reason: 'Add the missing tables to seedResetTables.',
    );
    expect(
      resetTables.difference(required),
      isEmpty,
      reason:
          'seedResetTables names a table that the migration does not '
          'create (Serverpod system tables are intentionally excluded).',
    );
  });
}
