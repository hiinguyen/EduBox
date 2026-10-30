import 'dart:async';
import 'dart:io';

import 'package:edubox_client/edubox_client.dart'
    show
        AccessDeniedException,
        AccessDeniedReason,
        ServerpodClientException,
        ServerpodClientNetworkException,
        ServerpodClientUnauthorized;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    show
        AuthUserBlockedException,
        EmailAccountLoginException,
        EmailAccountLoginExceptionReason,
        RefreshTokenExpiredException,
        RefreshTokenInvalidSecretException,
        RefreshTokenMalformedException,
        RefreshTokenNotFoundException;

import '../contract/backend_result.dart';

/// Maps a server or transport exception to the contract's typed error
/// (contract.md section 2.4). Never throws.
BackendError mapApiError(Object error) => switch (error) {
  BackendException(:final error) => error,
  EmailAccountLoginException(:final reason) => switch (reason) {
    EmailAccountLoginExceptionReason.invalidCredentials =>
      const WrongCredentialsError(),
    EmailAccountLoginExceptionReason.tooManyAttempts =>
      const TooManyAttemptsError(),
    _ => UnexpectedBackendError(error),
  },
  AuthUserBlockedException() => const AccountDisabledError(),
  AccessDeniedException(:final reason) => switch (reason) {
    AccessDeniedReason.notSetUp => const NotSetUpError(),
    AccessDeniedReason.wrongRole => const PermissionDeniedError(),
    AccessDeniedReason.unauthenticated => const SessionExpiredError(),
  },
  ServerpodClientUnauthorized() ||
  RefreshTokenExpiredException() ||
  RefreshTokenInvalidSecretException() ||
  RefreshTokenMalformedException() ||
  RefreshTokenNotFoundException() => const SessionExpiredError(),
  ServerpodClientNetworkException() ||
  SocketException() ||
  TimeoutException() ||
  HttpException() => const BackendUnreachableError(),
  ServerpodClientException() => UnexpectedBackendError(error),
  _ => UnexpectedBackendError(error),
};
