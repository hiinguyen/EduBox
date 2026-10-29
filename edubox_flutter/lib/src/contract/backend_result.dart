/// The typed error shapes shared by every app repository.
///
/// Screens map these to l10n keys; they never inspect server exception text.
sealed class BackendError {
  const BackendError();
}

/// Email or password is wrong (or the email is unknown; never distinguish).
final class WrongCredentialsError extends BackendError {
  const WrongCredentialsError();
}

/// The auth module's sign-in rate limit is active.
final class TooManyAttemptsError extends BackendError {
  const TooManyAttemptsError();
}

/// The auth user is blocked by an administrator.
final class AccountDisabledError extends BackendError {
  const AccountDisabledError();
}

/// The server cannot be reached, or the request timed out.
final class BackendUnreachableError extends BackendError {
  const BackendUnreachableError();
}

/// The caller has no EduBox profile, or its stored role is null/unknown.
final class NotSetUpError extends BackendError {
  const NotSetUpError();
}

/// The caller's role may not perform the call.
final class PermissionDeniedError extends BackendError {
  const PermissionDeniedError();
}

/// The caller is offline and the local store has no cached value.
final class OfflineNoCacheError extends BackendError {
  const OfflineNoCacheError();
}

/// Any other failure. [cause] is for logs, never for the UI.
final class UnexpectedBackendError extends BackendError {
  const UnexpectedBackendError([this.cause]);

  final Object? cause;

  @override
  String toString() => 'UnexpectedBackendError(${cause ?? 'unknown'})';
}

/// A [BackendError] delivered through a stream, which cannot return
/// [BackendResult] per event.
class BackendException implements Exception {
  const BackendException(this.error);

  final BackendError error;

  @override
  String toString() => 'BackendException($error)';
}

/// A typed success or failure. Repositories never throw [BackendError].
sealed class BackendResult<T> {
  const BackendResult();

  bool get isOk => this is BackendOk<T>;

  T? get valueOrNull => switch (this) {
    BackendOk<T>(:final value) => value,
    BackendFailure<T>() => null,
  };

  BackendError? get errorOrNull => switch (this) {
    BackendOk<T>() => null,
    BackendFailure<T>(:final error) => error,
  };

  R fold<R>({
    required R Function(T value) ok,
    required R Function(BackendError error) failure,
  }) => switch (this) {
    BackendOk<T>(:final value) => ok(value),
    BackendFailure<T>(:final error) => failure(error),
  };
}

final class BackendOk<T> extends BackendResult<T> {
  const BackendOk(this.value);

  final T value;
}

final class BackendFailure<T> extends BackendResult<T> {
  const BackendFailure(this.error);

  final BackendError error;
}
