import 'dart:async';
import 'dart:io';

import 'package:edubox_client/edubox_client.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/data/error_mapping.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    show
        AuthUserBlockedException,
        EmailAccountLoginException,
        EmailAccountLoginExceptionReason;

void main() {
  test('sign-in exceptions map to the sign-in error shapes', () {
    expect(
      mapApiError(
        EmailAccountLoginException(
          reason: EmailAccountLoginExceptionReason.invalidCredentials,
        ),
      ),
      isA<WrongCredentialsError>(),
    );
    expect(
      mapApiError(
        EmailAccountLoginException(
          reason: EmailAccountLoginExceptionReason.tooManyAttempts,
        ),
      ),
      isA<TooManyAttemptsError>(),
    );
    expect(
      mapApiError(
        EmailAccountLoginException(
          reason: EmailAccountLoginExceptionReason.unknown,
        ),
      ),
      isA<UnexpectedBackendError>(),
    );
    expect(
      mapApiError(AuthUserBlockedException()),
      isA<AccountDisabledError>(),
    );
  });

  test('access denials map by reason', () {
    expect(
      mapApiError(AccessDeniedException(reason: AccessDeniedReason.notSetUp)),
      isA<NotSetUpError>(),
    );
    expect(
      mapApiError(AccessDeniedException(reason: AccessDeniedReason.wrongRole)),
      isA<PermissionDeniedError>(),
    );
    expect(
      mapApiError(
        AccessDeniedException(reason: AccessDeniedReason.unauthenticated),
      ),
      isA<SessionExpiredError>(),
    );
    expect(
      mapApiError(ServerpodClientUnauthorized()),
      isA<SessionExpiredError>(),
    );
  });

  test('transport failures are backendUnreachable', () {
    expect(
      mapApiError(const ServerpodClientNetworkException('refused')),
      isA<BackendUnreachableError>(),
    );
    expect(
      mapApiError(const SocketException('refused')),
      isA<BackendUnreachableError>(),
    );
    expect(
      mapApiError(TimeoutException('slow')),
      isA<BackendUnreachableError>(),
    );
  });

  test('anything else is unexpected and keeps its cause for logs', () {
    final error = mapApiError(StateError('boom'));
    expect(error, isA<UnexpectedBackendError>());
    expect((error as UnexpectedBackendError).cause, isA<StateError>());
    expect(
      mapApiError(ServerpodClientInternalServerError()),
      isA<UnexpectedBackendError>(),
    );
    expect(
      mapApiError(const BackendException(NotSetUpError())),
      isA<NotSetUpError>(),
    );
  });
}
