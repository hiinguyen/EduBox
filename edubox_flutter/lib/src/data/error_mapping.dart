import 'dart:async';
import 'dart:io';

import 'package:edubox_client/edubox_client.dart'
    show
        AccessDeniedException,
        AccessDeniedReason,
        MethodStreamException,
        OpenMethodStreamException,
        OpenMethodStreamResponseType,
        ServerpodClientException,
        ServerpodClientForbidden,
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
  OpenMethodStreamException(:final responseType) => switch (responseType) {
    OpenMethodStreamResponseType.authenticationFailed =>
      const SessionExpiredError(),
    OpenMethodStreamResponseType.authorizationDeclined =>
      const PermissionDeniedError(),
    _ => UnexpectedBackendError(error),
  },
  // Every other MethodStreamException is a broken transport: the WebSocket
  // failed to connect, timed out, closed, or stopped listening.
  MethodStreamException() => const BackendUnreachableError(),
  ServerpodClientUnauthorized() ||
  RefreshTokenExpiredException() ||
  RefreshTokenInvalidSecretException() ||
  RefreshTokenMalformedException() ||
  RefreshTokenNotFoundException() => const SessionExpiredError(),
  ServerpodClientForbidden() => const PermissionDeniedError(),
  ServerpodClientNetworkException() ||
  SocketException() ||
  TimeoutException() ||
  HttpException() => const BackendUnreachableError(),
  ServerpodClientException() => UnexpectedBackendError(error),
  _ => UnexpectedBackendError(error),
};
