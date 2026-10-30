import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../app/app_scope.dart';
import '../../contract/backend_result.dart';
import '../../contract/session.dart';
import '../../shell/auth_panel.dart';
import '../../shell/block_states.dart';
import '../../shell/edu_mark.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/tokens.dart';

/// Stable keys for widget and E2E tests (sign-in brief section 7).
abstract final class SignInKeys {
  static const screen = Key('screen.signIn');
  static const email = Key('signIn.email');
  static const password = Key('signIn.password');
  static const togglePassword = Key('signIn.togglePassword');
  static const submit = Key('signIn.submit');
  static const status = Key('signIn.status');
  static const retry = Key('signIn.retry');
}

/// What the status slot between the password field and the button shows.
enum _Status { none, wrongCredentials, unreachable, tooMany, disabled, unknown }

/// `sign-in` (docs/design/shapes/sign-in.md).
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  /// The brief's submit timeout; it falls through to backend unreachable.
  static const submitTimeout = Duration(seconds: 15);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with WidgetsBindingObserver {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _submitting = false;
  bool _obscure = true;
  bool _validated = false;
  _Status _status = _Status.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _email.addListener(_onEdit);
    _password.addListener(_onEdit);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Password visibility resets when the app goes to the background.
    if (state != AppLifecycleState.resumed && !_obscure) {
      setState(() => _obscure = true);
    }
  }

  void _onEdit() {
    // Wrong-credentials clears on the next edit; field errors re-validate
    // live once they have been shown.
    if (_status == _Status.wrongCredentials || _validated) {
      setState(() {
        if (_status == _Status.wrongCredentials) _status = _Status.none;
      });
    }
  }

  String? _emailError(AppLocalizations l10n) {
    if (!_validated) return null;
    final value = _email.text.trim();
    if (value.isEmpty) return l10n.emailRequired;
    final at = value.indexOf('@');
    if (at <= 0 || at == value.length - 1) return l10n.emailInvalid;
    return null;
  }

  String? _passwordError(AppLocalizations l10n) {
    if (!_validated) return null;
    return _password.text.isEmpty ? l10n.passwordRequired : null;
  }

  /// A field decoration whose error is the brief's 18dp `error_outline`
  /// glyph plus the sentence. The sentence is also passed to the field's
  /// semantics as a hint by [build]; wrong credentials use an empty error
  /// widget for the 2dp border only, with no per-field text.
  InputDecoration _fieldDecoration({
    required String? error,
    required bool wrong,
    Widget? suffixIcon,
  }) {
    final message = wrong ? null : error;
    return InputDecoration(
      constraints: const BoxConstraints(minHeight: EduSize.primaryButton),
      error: wrong
          ? const SizedBox.shrink()
          : (message == null ? null : _FieldError(message)),
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _validated = true;
      _status = _Status.none;
    });
    final emailError = _emailError(l10n);
    final passwordError = _passwordError(l10n);
    if (emailError != null || passwordError != null) {
      (emailError != null ? _emailFocus : _passwordFocus).requestFocus();
      _announce(emailError ?? passwordError!);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    _announce(l10n.signInSubmitting);
    final scope = AppScope.of(context);
    final result = await _withTimeout(
      scope.services.backend.auth.signIn(
        email: _email.text.trim(),
        password: _password.text,
      ),
    );
    if (!mounted) return;
    _handle(result);
  }

  /// Retry after "unreachable": if sign-in already succeeded and only the
  /// role read failed, re-run the role read without re-authenticating.
  Future<void> _retry() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _status = _Status.none;
    });
    final auth = AppScope.of(context).services.backend.auth;
    var result = await _withTimeout(auth.refreshProfile());
    if (result case BackendFailure(error: SessionExpiredError())) {
      result = await _withTimeout(
        auth.signIn(email: _email.text.trim(), password: _password.text),
      );
    }
    if (!mounted) return;
    _handle(result);
  }

  Future<BackendResult<AuthSession>> _withTimeout(
    Future<BackendResult<AuthSession>> call,
  ) => call.timeout(
    SignInScreen.submitTimeout,
    onTimeout: () => const BackendFailure(BackendUnreachableError()),
  );

  void _handle(BackendResult<AuthSession> result) {
    final l10n = AppLocalizations.of(context);
    switch (result) {
      case BackendOk(:final value, :final cachedAt):
        TextInput.finishAutofillContext();
        AppScope.of(context).session.accept(value, refreshedAt: cachedAt);
        return;
      case BackendFailure(:final error):
        final status = switch (error) {
          WrongCredentialsError() => _Status.wrongCredentials,
          BackendUnreachableError() => _Status.unreachable,
          TooManyAttemptsError() => _Status.tooMany,
          AccountDisabledError() => _Status.disabled,
          _ => _Status.unknown,
        };
        // Clear first: the edit listener must not wipe the new status.
        if (status == _Status.wrongCredentials) _password.clear();
        setState(() {
          _submitting = false;
          _status = status;
        });
        if (status == _Status.wrongCredentials) _passwordFocus.requestFocus();
        _announce(_statusText(l10n, status));
    }
  }

  String _statusText(AppLocalizations l10n, _Status status) => switch (status) {
    _Status.none => '',
    _Status.wrongCredentials => l10n.signInWrongCredentials,
    _Status.unreachable => l10n.backendUnreachable,
    _Status.tooMany => l10n.signInTooManyAttempts,
    _Status.disabled => l10n.signInAccountDisabled,
    _Status.unknown => l10n.signInUnknownError,
  };

  void _announce(String message) {
    if (message.isEmpty) return;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        TextDirection.ltr,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final wrong = _status == _Status.wrongCredentials;
    final emailError = _emailError(l10n);
    final passwordError = _passwordError(l10n);
    return AuthPanelScaffold(
      key: SignInKeys.screen,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: EduLockup(),
            ),
            const SizedBox(height: EduSpace.s24),
            Semantics(
              header: true,
              child: Text(l10n.signInTitle, style: text.headlineLarge),
            ),
            const SizedBox(height: EduSpace.s24),
            _FieldLabel(l10n.emailLabel),
            const SizedBox(height: EduSpace.s8),
            Semantics(
              label: l10n.emailLabel,
              hint: wrong ? null : emailError,
              child: TextField(
                key: SignInKeys.email,
                controller: _email,
                focusNode: _emailFocus,
                readOnly: _submitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.email],
                style: text.bodyLarge,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
                decoration: _fieldDecoration(
                  error: emailError,
                  wrong: wrong,
                ),
              ),
            ),
            const SizedBox(height: EduSpace.s16),
            _FieldLabel(l10n.passwordLabel),
            const SizedBox(height: EduSpace.s8),
            Semantics(
              label: l10n.passwordLabel,
              hint: wrong ? null : passwordError,
              child: TextField(
                key: SignInKeys.password,
                controller: _password,
                focusNode: _passwordFocus,
                readOnly: _submitting,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.password],
                style: text.bodyLarge,
                onSubmitted: (_) => _submit(),
                decoration: _fieldDecoration(
                  error: passwordError,
                  wrong: wrong,
                  suffixIcon: IconButton(
                    key: SignInKeys.togglePassword,
                    tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
                    isSelected: !_obscure,
                    icon: const Icon(Icons.visibility_outlined),
                    selectedIcon: const Icon(Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
            ),
            _StatusSlot(
              status: _status,
              message: _statusText(l10n, _status),
              onRetry: _retry,
            ),
            const SizedBox(height: EduSpace.s24),
            SizedBox(
              height: EduSize.primaryButton,
              child: FilledButton(
                key: SignInKeys.submit,
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  // Busy keeps the accent fill; the changed word is the why.
                  disabledBackgroundColor: EduPalette.of(context).accent,
                  disabledForegroundColor: EduPalette.of(context).sheet,
                ),
                child: _submitting
                    ? BusyLabel(
                        label: l10n.signInSubmitting,
                        color: EduPalette.of(context).sheet,
                      )
                    : Text(l10n.signInButton),
              ),
            ),
            const SizedBox(height: EduSpace.s16),
            Text(
              l10n.signInHelp,
              style: text.bodyMedium!.copyWith(
                color: EduPalette.of(context).muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A label above its field; excluded from semantics because the field
/// carries the same label (one name, not two).
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _StatusSlot extends StatelessWidget {
  const _StatusSlot({
    required this.status,
    required this.message,
    required this.onRetry,
  });

  final _Status status;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (status == _Status.none) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final palette = EduPalette.of(context);
    final text = Theme.of(context).textTheme;
    final unreachable = status == _Status.unreachable;
    final retryable = unreachable || status == _Status.unknown;
    return Padding(
      key: SignInKeys.status,
      padding: const EdgeInsets.only(top: EduSpace.s16),
      child: BlockMessage(
        message: message,
        hint: unreachable ? l10n.backendUnreachableHint : null,
        tone: unreachable ? BlockTone.offline : BlockTone.error,
        messageStyle: text.bodyLarge!.copyWith(
          color: unreachable ? palette.ink : palette.negative,
        ),
        action: retryable
            ? RetryButton(
                buttonKey: SignInKeys.retry,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}

/// A field-level error: the 18dp `error_outline` glyph then the sentence at
/// 14/20 in the negative family (sign-in brief section 5).
class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = EduPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: ExcludeSemantics(
            child: Icon(
              Icons.error_outline,
              size: EduSize.statusGlyph,
              color: palette.negative,
            ),
          ),
        ),
        const SizedBox(width: EduSpace.s8),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: palette.negative),
          ),
        ),
      ],
    );
  }
}
