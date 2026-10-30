import 'dart:io';

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

  group('runSeedCli run-mode gate', () {
    test(
      'refuses production and staging even when called programmatically',
      () async {
        for (final mode in ['production', 'staging']) {
          final exitCode = await runSeedCli(
            SeedArgs(runMode: mode, step: SeedStep.reset),
          );
          expect(exitCode, seedExitUsage, reason: mode);
        }
      },
    );
  });

  group('main', () {
    test(
      'exits 64 on a refused run mode and 0 on --help',
      () async {
        final production = await _runSeedCli(['--mode', 'production']);
        expect(production.exitCode, seedExitUsage);
        expect(production.stderr, contains('Usage: seed'));

        final help = await _runSeedCli(['--help']);
        expect(help.exitCode, 0);
        expect(help.stdout, contains('Usage: seed'));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}

/// Runs the real CLI in a child process so `main()`'s `exit()` is observable.
Future<ProcessResult> _runSeedCli(List<String> args) => Process.run(
  Platform.resolvedExecutable,
  ['run', 'bin/seed.dart', ...args],
  workingDirectory: Directory.current.path,
);
