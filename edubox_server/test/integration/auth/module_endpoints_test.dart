@Tags(['integration'])
library;

import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../support/harness.dart';
import '../test_tools/serverpod_test_tools.dart';

/// The auth-module and framework rows of the authorization matrix: each
/// method on an exception list is proven harmless without a session, and each
/// method on the denied list is proven to deny.
void main() {
  withServerpod('Auth module and framework methods', (
    sessionBuilder,
    endpoints,
  ) {
    setUpAll(initTestAuthServices);

    late SeededFixtures seeded;
    setUp(() async => seeded = await seedPhase1(sessionBuilder));

    Future<int> authUserCount() => AuthUser.db.count(sessionBuilder.build());

    group('status (unauthenticated exception list)', () {
      test('isSignedIn answers false without a session', () async {
        final result = await callThroughDispatch(
          anonymous(sessionBuilder),
          'serverpod_auth_core.status',
          'isSignedIn',
        );
        expect(result, isFalse);
      });

      test(
        'signOutDevice and signOutAllDevices change no auth state',
        () async {
          final session = sessionBuilder.build();
          final authUsers = await AuthUser.db.count(session);
          final sessions = await ServerSideSession.db.count(session);
          final refreshTokens = await RefreshToken.db.count(session);
          for (final method in ['signOutDevice', 'signOutAllDevices']) {
            await callThroughDispatch(
              anonymous(sessionBuilder),
              'serverpod_auth_core.status',
              method,
            );
          }
          expect(await AuthUser.db.count(session), authUsers);
          expect(await ServerSideSession.db.count(session), sessions);
          expect(await RefreshToken.db.count(session), refreshTokens);
        },
      );
    });

    test('userProfileInfo.get denies an unauthenticated caller', () async {
      await expectLater(
        callThroughDispatch(
          anonymous(sessionBuilder),
          'serverpod_auth_core.userProfileInfo',
          'get',
        ),
        throwsA(isA<NotAuthorizedException>()),
      );
    });

    test('jwtRefresh rejects an invalid refresh token', () async {
      await expectLater(
        endpoints.jwtRefresh.refreshAccessToken(
          anonymous(sessionBuilder),
          refreshToken: 'not-a-refresh-token',
        ),
        throwsA(anything),
      );
      expect(await authUserCount(), seeded.authUserIds.length);
    });

    group('serverpod_cloud_storage raw routes over HTTP', () {
      late HttpClient http;
      setUp(() => http = HttpClient());
      tearDown(() => http.close(force: true));

      Future<int> status(String method, Map<String, String> query) async {
        final uri = Uri(
          scheme: 'http',
          host: 'localhost',
          port: Serverpod.instance.server.port,
          path: '/serverpod_cloud_storage',
          queryParameters: {'method': method, ...query},
        );
        final request = method == 'upload'
            ? await http.postUrl(uri)
            : await http.getUrl(uri);
        final response = await request.close();
        await response.drain<void>();
        return response.statusCode;
      }

      test(
        'file serves nothing (EduBox never writes public storage)',
        () async {
          expect(await status('file', {'path': 'any.pdf'}), isNot(200));
        },
      );

      test('temporaryFile rejects an unissued key', () async {
        final code = await status('temporaryFile', {
          'storageId': 'private',
          'path': 'any.pdf',
          'key': 'forged',
        });
        expect(code, isNot(200));
      });

      test('upload rejects an unissued key', () async {
        final code = await status('upload', {
          'storageId': 'public',
          'path': 'any.pdf',
          'key': 'forged',
        });
        expect(code, isNot(200));
      });
    });
  });
}
