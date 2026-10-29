@Tags(['integration'])
library;

import 'package:edubox_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/harness.dart';
import '../test_tools/serverpod_test_tools.dart';
import 'authorization_matrix.dart';

void main() {
  withServerpod('Authorization matrix', (sessionBuilder, endpoints) {
    setUpAll(initTestAuthServices);

    test('every dispatched method is in exactly one matrix list', () {
      final edubox = eduboxMethodMatrix.keys.toSet();
      final lists = [
        edubox,
        moduleUnauthenticatedExceptions.keys.toSet(),
        frameworkUnauthenticatedExceptions.keys.toSet(),
        moduleDeniedUnauthenticated,
      ];
      final listed = <String>{};
      for (final list in lists) {
        expect(listed.intersection(list), isEmpty, reason: 'listed twice');
        listed.addAll(list);
      }

      final dispatched = dispatchedMethods();
      expect(
        dispatched.difference(listed),
        isEmpty,
        reason: 'Dispatched methods missing from the authorization matrix',
      );
      expect(
        listed.difference(dispatched),
        isEmpty,
        reason: 'Matrix rows for methods the server no longer dispatches',
      );
    });

    test('every EduBox method denies at least the anonymous caller', () {
      for (final MapEntry(:key, :value) in eduboxMethodMatrix.entries) {
        expect(
          value.allowed,
          isNot(contains(MatrixCaller.anonymous)),
          reason: key,
        );
        expect(value.allowed, isNotEmpty, reason: key);
      }
    });

    for (final MapEntry(key: methodKey, value: rule)
        in eduboxMethodMatrix.entries) {
      group(methodKey, () {
        late SeededFixtures seeded;
        setUp(() async => seeded = await seedPhase1(sessionBuilder));

        TestSessionBuilder as(MatrixCaller caller) => caller.fixtureKey == null
            ? anonymous(sessionBuilder)
            : signedInAs(sessionBuilder, seeded, caller.fixtureKey!);

        for (final caller in MatrixCaller.values) {
          if (rule.allowed.contains(caller)) {
            test('allows ${caller.name}', () async {
              await expectLater(rule.invoke(endpoints, as(caller)), completes);
            });
          } else {
            test('denies ${caller.name}', () async {
              await expectLater(
                rule.invoke(endpoints, as(caller)),
                throwsA(_expectedDenial(caller)),
              );
            });
          }
        }

        if (!rule.isStream) {
          final [endpoint, method] = methodKey.split('.');
          test('denies anonymous through the HTTP dispatch path', () async {
            await expectLater(
              callThroughDispatch(anonymous(sessionBuilder), endpoint, method),
              throwsA(isA<NotAuthorizedException>()),
            );
          });
        }
      });
    }
  });
}

Matcher _expectedDenial(MatrixCaller caller) => switch (caller) {
  MatrixCaller.anonymous => isA<ServerpodUnauthenticatedException>(),
  MatrixCaller.noProfile ||
  MatrixCaller.nullRole => isA<AccessDeniedException>().having(
    (e) => e.reason,
    'reason',
    AccessDeniedReason.notSetUp,
  ),
  _ => isA<AccessDeniedException>().having(
    (e) => e.reason,
    'reason',
    AccessDeniedReason.wrongRole,
  ),
};
