import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/data/email_auth.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/widgets/app_bottom_sheet.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';
import 'package:gym_tracker_app/widgets/app_text_field.dart';
import 'package:gym_tracker_app/widgets/app_text_link.dart';
import 'package:gym_tracker_app/widgets/field_label.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Signs in, creates an account or resets a password with an email address.
/// The sheet closes once the user is signed in; [onOpenPrivacyPolicy] is
/// offered when creating an account. "Forgot password?" is shown only with
/// [allowPasswordReset].
Future<void> showEmailAuthSheet({
  required BuildContext context,
  required VoidCallback onOpenPrivacyPolicy,
  bool allowPasswordReset = emailPasswordResetEnabled,
}) {
  return showAppSheet<void>(
    context: context,
    children: (sheetContext) => [
      EmailAuthForm(
        onOpenPrivacyPolicy: onOpenPrivacyPolicy,
        allowPasswordReset: allowPasswordReset,
      ),
    ],
  );
}

enum _Step { signIn, createAccount, confirmEmail, requestReset, resetPassword }

/// How long "Send again" waits after a code is sent.
const resendCooldown = Duration(seconds: 60);

class EmailAuthForm extends ConsumerStatefulWidget {
  const EmailAuthForm({
    super.key,
    required this.onOpenPrivacyPolicy,
    this.allowPasswordReset = emailPasswordResetEnabled,
  });

  final VoidCallback onOpenPrivacyPolicy;
  final bool allowPasswordReset;

  @override
  ConsumerState<EmailAuthForm> createState() => _EmailAuthFormState();
}

class _EmailAuthFormState extends ConsumerState<EmailAuthForm> {
  // Read once: the reset session is dropped in dispose, after ref is gone.
  late final UserAuthenticationNotifier _auth;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();

  _Step _step = _Step.signIn;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  /// Set when the code step was reached by signing in to an unconfirmed
  /// account rather than by creating one.
  bool _wasUnconfirmed = false;
  int _resendSecondsLeft = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _auth = ref.read(userAuthenticationProvider.notifier);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    if (_step == _Step.resetPassword) {
      unawaited(_auth.cancelPasswordReset());
    }
    for (final controller in [_email, _password, _name, _code, _newPassword]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _goTo(_Step step) {
    if (_step == _Step.resetPassword && step != _Step.resetPassword) {
      unawaited(_auth.cancelPasswordReset());
    }
    setState(() {
      _step = step;
      _error = null;
      _code.clear();
    });
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = resendCooldown.inSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _resendSecondsLeft--);
      if (_resendSecondsLeft <= 0) {
        timer.cancel();
      }
    });
  }

  String _messageFor(EmailAuthResult result) => switch (result) {
        EmailAuthResult.invalidCredentials => 'Email or password is incorrect.',
        EmailAuthResult.accountExists =>
          'This email already has an account. Sign in with it instead, or '
              'with Apple or Google if you used one of those.',
        EmailAuthResult.invalidCode =>
          'That code is wrong or has expired. Check it, or send a new one.',
        EmailAuthResult.weakPassword =>
          'Choose a different password. That one is too easy to guess or '
              'has appeared in a data breach.',
        EmailAuthResult.rateLimited =>
          'Too many attempts. Wait a minute and try again.',
        _ => 'Something went wrong. Check your connection and try again.',
      };

  /// Runs [action], closes the sheet once signed in, and otherwise hands the
  /// result to [onResult] or shows its message.
  Future<void> _run(
    Future<EmailAuthResult> Function() action, {
    void Function(EmailAuthResult result)? onResult,
  }) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await action();
    if (!mounted) {
      return;
    }
    if (result == EmailAuthResult.signedIn) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _busy = false);
    if (onResult != null) {
      onResult(result);
    } else {
      setState(() => _error = _messageFor(result));
    }
  }

  void _signIn() => _run(
        () => _auth.signInWithEmail(
          email: _email.text,
          password: _password.text,
        ),
        onResult: (result) {
          if (result == EmailAuthResult.emailNotConfirmed) {
            _wasUnconfirmed = true;
            _goTo(_Step.confirmEmail);
            _startResendCooldown();
          } else {
            setState(() => _error = _messageFor(result));
          }
        },
      );

  void _createAccount() => _run(
        () => _auth.signUpWithEmail(
          email: _email.text,
          password: _password.text,
          firstName: _name.text,
        ),
        onResult: (result) {
          if (result == EmailAuthResult.codeSent) {
            _wasUnconfirmed = false;
            _goTo(_Step.confirmEmail);
            _startResendCooldown();
          } else {
            setState(() => _error = _messageFor(result));
          }
        },
      );

  void _confirm() => _run(
        () => _auth.confirmEmail(email: _email.text, code: _code.text),
      );

  void _requestReset() => _run(
        () => _auth.sendPasswordReset(email: _email.text),
        onResult: (result) {
          if (result == EmailAuthResult.codeSent) {
            _goTo(_Step.resetPassword);
            _startResendCooldown();
          } else {
            setState(() => _error = _messageFor(result));
          }
        },
      );

  void _resetPassword() => _run(
        () => _auth.resetPassword(
          email: _email.text,
          code: _code.text,
          newPassword: _newPassword.text,
        ),
      );

  void _resend() => _run(
        () => _step == _Step.resetPassword
            ? _auth.sendPasswordReset(email: _email.text)
            : _auth.resendConfirmation(email: _email.text),
        onResult: (result) {
          if (result == EmailAuthResult.codeSent) {
            _startResendCooldown();
          } else {
            setState(() => _error = _messageFor(result));
          }
        },
      );

  bool get _canSubmit {
    if (_busy) {
      return false;
    }
    final email = isValidEmail(_email.text);
    return switch (_step) {
      _Step.signIn => email && _password.text.isNotEmpty,
      _Step.createAccount => email && isValidPassword(_password.text),
      _Step.confirmEmail => isValidEmailCode(_code.text),
      _Step.requestReset => email,
      _Step.resetPassword =>
        isValidEmailCode(_code.text) && isValidPassword(_newPassword.text),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final address = normaliseEmail(_email.text);

    final (title, body) = switch (_step) {
      _Step.signIn => ('Sign in with email', null),
      _Step.createAccount => ('Create an account', null),
      _Step.confirmEmail => (
          'Check your email',
          _wasUnconfirmed
              ? 'Your email is not confirmed yet. Enter the '
                  '$emailCodeLength-digit code we just sent to $address.'
              : 'Enter the $emailCodeLength-digit code we sent to $address. '
                  'If you already have an account with this address, no code '
                  'is sent: sign in or reset your password instead.',
        ),
      _Step.requestReset => (
          'Reset password',
          "Enter your email and we'll send you a $emailCodeLength-digit code.",
        ),
      _Step.resetPassword => (
          'Reset password',
          "If $address has an account, we've sent it a "
              '$emailCodeLength-digit code.',
        ),
    };

    final (submitLabel, busyLabel, submit) = switch (_step) {
      _Step.signIn => ('Sign in', 'Signing in…', _signIn),
      _Step.createAccount => (
          'Create account',
          'Creating account…',
          _createAccount
        ),
      _Step.confirmEmail => ('Confirm', 'Confirming…', _confirm),
      _Step.requestReset => ('Send code', 'Sending…', _requestReset),
      _Step.resetPassword => (
          'Set password and sign in',
          'Saving…',
          _resetPassword
        ),
    };

    void submitIfReady() {
      if (_canSubmit) {
        submit();
      }
    }

    final fields = switch (_step) {
      _Step.signIn => [
          _emailField(autofocus: true),
          _passwordField(
            _password,
            label: 'PASSWORD',
            newPassword: false,
            onSubmitted: submitIfReady,
          ),
        ],
      _Step.createAccount => [
          _LabelledField(
            label: 'FIRST NAME',
            note: 'OPTIONAL',
            child: AppTextField(
              controller: _name,
              placeholder: 'What should we call you?',
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.givenName],
              maxLength: 50,
            ),
          ),
          _emailField(),
          _passwordField(
            _password,
            label: 'PASSWORD',
            newPassword: true,
            onSubmitted: submitIfReady,
          ),
        ],
      _Step.confirmEmail => [_codeField(onSubmitted: submitIfReady)],
      _Step.requestReset => [
          _emailField(autofocus: true, onSubmitted: submitIfReady),
        ],
      _Step.resetPassword => [
          _codeField(next: true),
          _passwordField(
            _newPassword,
            label: 'NEW PASSWORD',
            newPassword: true,
            onSubmitted: submitIfReady,
          ),
        ],
    };

    final resendLabel = _resendSecondsLeft > 0
        ? 'Send again in ${_resendSecondsLeft}s'
        : 'Send again';
    final canResend = _resendSecondsLeft <= 0;

    final links = switch (_step) {
      _Step.signIn => [
          _link('Create an account', () => _goTo(_Step.createAccount)),
          if (widget.allowPasswordReset)
            _link('Forgot password?', () => _goTo(_Step.requestReset)),
        ],
      _Step.createAccount => [
          _link('I already have an account', () => _goTo(_Step.signIn)),
          _link('Privacy Policy', widget.onOpenPrivacyPolicy),
        ],
      _Step.confirmEmail || _Step.resetPassword => [
          _link(resendLabel, canResend ? _resend : null),
          _link('Back to sign in', () => _goTo(_Step.signIn)),
        ],
      _Step.requestReset => [
          _link('Back to sign in', () => _goTo(_Step.signIn)),
        ],
    };

    return AutofillGroup(
      // A new group per step, so each step's fields autofocus and autofill
      // on their own.
      key: ValueKey(_step),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: t.spacing.gap18,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Text(title, style: AppTypography.sheetTitle),
              if (body != null)
                Text(
                  body,
                  style:
                      AppTypography.body.copyWith(color: t.muted, height: 1.45),
                ),
            ],
          ),
          ...fields,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: t.spacing.gap8,
            children: [
              if (_error != null)
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: t.danger),
                ),
              // Rebuilds as the fields change, to enable and disable itself.
              ListenableBuilder(
                listenable: Listenable.merge(
                  [_email, _password, _code, _newPassword],
                ),
                builder: (context, child) => AppButton(
                  label: _busy ? busyLabel : submitLabel,
                  onPressed: _canSubmit ? submit : null,
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: t.spacing.gap8,
                children: links,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Links are disabled while a step runs, so its result cannot land on a
  /// different step.
  Widget _link(String label, VoidCallback? onTap) => AppTextLink(
        label: label,
        onTap: _busy ? null : onTap,
        color: context.tokens.accentText,
        style: AppTypography.link,
        verticalPadding: 10,
      );

  Widget _emailField({bool autofocus = false, VoidCallback? onSubmitted}) {
    return _LabelledField(
      label: 'EMAIL',
      child: AppTextField(
        controller: _email,
        placeholder: 'you@example.com',
        autofocus: autofocus,
        keyboardType: TextInputType.emailAddress,
        textCapitalization: TextCapitalization.none,
        textInputAction:
            onSubmitted == null ? TextInputAction.next : TextInputAction.done,
        autofillHints: const [AutofillHints.email],
        autocorrect: false,
        onSubmitted: onSubmitted == null ? null : (_) => onSubmitted(),
      ),
    );
  }

  Widget _passwordField(
    TextEditingController controller, {
    required String label,
    required bool newPassword,
    required VoidCallback onSubmitted,
  }) {
    final t = context.tokens;
    return _LabelledField(
      label: label,
      note: newPassword ? '$minPasswordLength+ CHARACTERS' : null,
      child: AppTextField(
        controller: controller,
        placeholder: newPassword ? 'Choose a password' : 'Password',
        obscureText: !_showPassword,
        textCapitalization: TextCapitalization.none,
        autofillHints: [
          newPassword ? AutofillHints.newPassword : AutofillHints.password,
        ],
        autocorrect: false,
        onSubmitted: (_) => onSubmitted(),
        trailing: IconButton(
          onPressed: () => setState(() => _showPassword = !_showPassword),
          tooltip: _showPassword ? 'Hide password' : 'Show password',
          icon: Icon(
            _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
            size: 20,
            color: t.muted,
          ),
        ),
      ),
    );
  }

  Widget _codeField({bool next = false, VoidCallback? onSubmitted}) {
    return _LabelledField(
      label: 'CODE',
      child: AppTextField(
        controller: _code,
        placeholder: '$emailCodeLength-digit code',
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: next ? TextInputAction.next : TextInputAction.done,
        autofillHints: const [AutofillHints.oneTimeCode],
        autocorrect: false,
        digitsOnly: true,
        maxLength: emailCodeLength,
        onSubmitted: onSubmitted == null ? null : (_) => onSubmitted(),
      ),
    );
  }
}

class _LabelledField extends StatelessWidget {
  const _LabelledField({required this.label, this.note, required this.child});

  final String label;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.tokens.spacing.gap8,
      children: [FieldLabel(label, note: note), child],
    );
  }
}
