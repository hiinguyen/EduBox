import 'package:edubox_server/src/seed/seed_command.dart';
import 'package:test/test.dart';

import '../../../bin/seed.dart';

void main() {
  group('parseSeedArgs', () {
    test('defaults to the development mode and the reset step', () {
      final args = parseSeedArgs(const []);
      expect(args, isNotNull);
      expect(args!.runMode, 'development');
      expect(args.step, SeedStep.reset);
    });

    test('accepts every step by its CLI name, in both option forms', () {
      for (final step in SeedStep.values) {
        expect(
          parseSeedArgs(['--mode', 'test', '--step', step.cliName])?.step,
          step,
          reason: step.cliName,
        );
        expect(
          parseSeedArgs(['--mode=development', '--step=${step.cliName}'])?.step,
          step,
          reason: step.cliName,
        );
      }
      expect(parseSeedArgs(['-m', 'test'])?.runMode, 'test');
    });

    test('rejects production, staging, unknown steps, stray arguments and '
        '--help as usage errors', () {
      for (final args in [
        ['--mode', 'production'],
        ['--mode', 'staging'],
        ['--step', 'nope'],
        ['--unknown'],
        ['reset'],
        ['--help'],
      ]) {
        expect(parseSeedArgs(args), isNull, reason: args.join(' '));
      }
    });

    test('the usage text names both options', () {
      expect(seedUsage, contains('--mode'));
      expect(seedUsage, contains('--step'));
      expect(seedExitUsage, 64);
    });
  });
}
