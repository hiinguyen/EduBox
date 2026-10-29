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
}
