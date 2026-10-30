import 'dart:io';

import 'package:args/args.dart';
import 'package:edubox_server/src/auth/auth_setup.dart';
import 'package:edubox_server/src/config/edubox_config.dart';
import 'package:edubox_server/src/generated/serverpod.dart';
import 'package:edubox_server/src/seed/seed_command.dart';
import 'package:edubox_server/src/storage/object_store.dart';

/// Exit code for a usage error (BSD `EX_USAGE`).
const int seedExitUsage = 64;

/// The run modes the seed CLI accepts. Production and staging are refused:
/// the seed wipes every EduBox and auth table.
const List<String> seedRunModes = ['development', 'test'];

/// A parsed seed command line.
class SeedArgs {
  const SeedArgs({required this.runMode, required this.step});

  final String runMode;
  final SeedStep step;
}

final ArgParser _parser = ArgParser()
  ..addOption(
    'mode',
    abbr: 'm',
    allowed: seedRunModes,
    defaultsTo: 'development',
    help: 'Serverpod run mode; selects config/<mode>.yaml and passwords.',
  )
  ..addOption(
    'step',
    allowed: [for (final step in SeedStep.values) step.cliName],
    defaultsTo: SeedStep.reset.cliName,
    help: 'The seed step to run.',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this usage.');

/// The usage text printed on a usage error.
String get seedUsage =>
    'Usage: seed [--mode development|test] [--step <step>]\n'
    '${_parser.usage}';

/// Parses the seed command line. Returns null on a usage error or `--help`.
SeedArgs? parseSeedArgs(List<String> args) {
  final ArgResults results;
  try {
    results = _parser.parse(args);
  } on FormatException {
    return null;
  }
  if (results.flag('help') || results.rest.isNotEmpty) return null;
  return SeedArgs(
    runMode: results.option('mode')!,
    step: SeedStep.tryParse(results.option('step')!)!,
  );
}

/// `docker compose run --rm seed [--step <step>]` runs
/// `./bin/seed --mode development [--step <step>]` against the development
/// database and the bucket named by `EDUBOX_STORAGE_BUCKET` (the e2e bucket).
/// Exit codes: 0 success (and `--help`), 1 failure, 64 usage error.
Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(seedUsage);
    return;
  }
  final parsed = parseSeedArgs(args);
  if (parsed == null) {
    stderr.writeln(seedUsage);
    exit(seedExitUsage);
  }
  exit(await runSeedCli(parsed));
}

/// Runs one seed step without starting the API server: Serverpod only loads
/// the config and passwords and opens the database pool lazily.
///
/// Refuses every run mode outside [seedRunModes] and returns [seedExitUsage]
/// without loading any config: the seed wipes every EduBox and auth table, so
/// the gate must not depend on the caller having used [parseSeedArgs].
Future<int> runSeedCli(
  SeedArgs args, {
  Map<String, String>? environment,
  ServerpodConfig Function(ServerpodConfig)? configOverride,
}) async {
  if (!seedRunModes.contains(args.runMode)) {
    stderr.writeln(
      'seed: refusing run mode "${args.runMode}": this command wipes every '
      'EduBox and auth table.',
    );
    return seedExitUsage;
  }
  // Serverpod's own parser drops every argument when it meets an unknown
  // one, so it only ever receives the run mode.
  final pod = Serverpod(
    ['--mode', args.runMode],
    configOverride: configOverride,
  );
  configureAuthServices(pod);
  final session = await pod.createSession(enableLogging: false);
  try {
    final config = EduboxConfig.load(
      runMode: args.runMode,
      serverDirectory: pod.serverDirectory.path,
      environment: environment,
    );
    final store = S3ObjectStore(
      config: config.storage,
      accessKey: _requirePassword(pod, 'storageAccessKey'),
      secretKey: _requirePassword(pod, 'storageSecretKey'),
    );
    await runSeedStep(session, args.step, e2eStore: store);
    stdout.writeln(
      'seed: ok:${args.step.cliName} (mode ${args.runMode}, '
      'bucket ${config.storage.bucket})',
    );
    return 0;
  } catch (error, stackTrace) {
    stderr.writeln('seed: FAILED ${args.step.cliName}: $error');
    stderr.writeln(stackTrace);
    return 1;
  } finally {
    await session.close();
    await pod.shutdown(exitProcess: false);
  }
}

String _requirePassword(Serverpod pod, String key) {
  final value = pod.getPassword(key);
  if (value == null || value.isEmpty) {
    throw StateError('Missing password "$key" in config/passwords.yaml.');
  }
  return value;
}
