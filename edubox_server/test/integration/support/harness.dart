import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_server/src/auth/auth_setup.dart';
import 'package:edubox_server/src/seed/fixture_loader.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../test_tools/serverpod_test_tools.dart';

export 'package:edubox_fixtures/edubox_fixtures.dart';
export 'package:edubox_server/src/seed/fixture_loader.dart';

/// Registers the production auth services for the current test Serverpod.
/// `withServerpod` does not run `lib/server.dart`, so every test group that
/// signs in or creates auth users calls this in `setUpAll`.
void initTestAuthServices() {
  AuthServices.set(
    tokenManagerBuilders: eduboxTokenManagerBuilders(),
    identityProviderBuilders: eduboxIdentityProviderBuilders(),
  );
}

/// Loads the phase 1 fixtures into the test database (rolled back after each
/// test). Email identities are created only for [credentialsFor].
Future<SeededFixtures> seedPhase1(
  TestSessionBuilder sessionBuilder, {
  Set<String> credentialsFor = const {},
  FixtureSet? fixtures,
}) {
  return const FixtureLoader().load(
    sessionBuilder.build(),
    fixtures ?? FixtureSet.phase1(),
    credentialsFor: credentialsFor,
  );
}

/// A session builder authenticated as the fixture account [key].
TestSessionBuilder signedInAs(
  TestSessionBuilder sessionBuilder,
  SeededFixtures seeded,
  String key,
) {
  return sessionBuilder.copyWith(
    authentication: AuthenticationOverride.authenticationInfo(
      seeded.authUserIds[key]!.uuid,
      {},
    ),
  );
}

/// A session builder with no signed-in user.
TestSessionBuilder anonymous(TestSessionBuilder sessionBuilder) =>
    sessionBuilder.copyWith(
      authentication: AuthenticationOverride.unauthenticated(),
    );

/// Every `(endpoint path, method)` the server dispatches, including module
/// endpoints (as `<module>.<endpoint>`). Read from the live dispatch table,
/// so a new method can never hide from the authorization matrix.
Set<String> dispatchedMethods() {
  final dispatch = Serverpod.instance.endpoints;
  final result = <String>{};
  for (final connector in dispatch.connectors.values) {
    for (final method in connector.methodConnectors.keys) {
      result.add('${connector.name}.$method');
    }
  }
  for (final MapEntry(key: module, value: moduleDispatch)
      in dispatch.modules.entries) {
    for (final connector in moduleDispatch.connectors.values) {
      for (final method in connector.methodConnectors.keys) {
        result.add('$module.${connector.name}.$method');
      }
    }
  }
  return result;
}

/// Calls a non-streaming method through the real dispatch path (the same
/// path an HTTP request takes), as the session built by [sessionBuilder].
Future<Object?> callThroughDispatch(
  TestSessionBuilder sessionBuilder,
  String endpointPath,
  String method, [
  Map<String, dynamic> parameters = const {},
]) async {
  final session = sessionBuilder.build();
  final pod = Serverpod.instance;
  final context = await pod.endpoints.getMethodCallContext(
    createSessionCallback: (_) => session,
    endpointPath: endpointPath,
    methodName: method,
    parameters: parameters,
    serializationManager: pod.serializationManager,
  );
  return context.method.call(session, context.arguments);
}
