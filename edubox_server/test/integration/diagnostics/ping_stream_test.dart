@Tags(['integration'])
library;

import 'package:edubox_server/src/diagnostics/diagnostics_endpoint.dart';
import 'package:edubox_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/harness.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('diagnostics.pingStream', (sessionBuilder, endpoints) {
    setUpAll(initTestAuthServices);

    test(
      'streams three messages with the caller\'s role, then closes',
      () async {
        final seeded = await seedPhase1(sessionBuilder);
        for (final (key, role) in [
          (FixtureKeys.studentAn, UserRole.student),
          (FixtureKeys.teacherLan, UserRole.teacher),
          (FixtureKeys.parentBinh, UserRole.parent),
        ]) {
          final messages = await endpoints.diagnostics
              .pingStream(signedInAs(sessionBuilder, seeded, key))
              .toList();
          expect(messages, hasLength(DiagnosticsEndpoint.pingCount));
          expect(messages.map((m) => m.sequence), [1, 2, 3]);
          expect(messages.every((m) => m.role == role), isTrue, reason: key);
          expect(messages.every((m) => m.total == 3), isTrue);
        }
      },
    );

    test('messages arrive one by one, not as one batch', () async {
      final seeded = await seedPhase1(sessionBuilder);
      final arrivals = <DateTime>[];
      await endpoints.diagnostics
          .pingStream(signedInAs(sessionBuilder, seeded, FixtureKeys.studentAn))
          .forEach((_) => arrivals.add(DateTime.now()));
      expect(
        arrivals.last.difference(arrivals.first),
        greaterThanOrEqualTo(DiagnosticsEndpoint.pingInterval),
      );
    });
  });
}
