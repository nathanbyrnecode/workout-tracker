import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/privacy_policy.dart';
import 'package:gym_tracker_app/widgets/app_background.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';

/// Shown when signed out: the logo, the headline and the sign-in buttons.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isSigningIn = false;

  Future<void> _openPrivacyPolicy() async {
    final opened = await openPrivacyPolicy();

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the privacy policy.'),
        ),
      );
    }
  }

  Future<void> _signIn(Future<void> Function() signIn) async {
    if (_isSigningIn) {
      return;
    }

    setState(() => _isSigningIn = true);
    try {
      await signIn();
    } catch (error, stackTrace) {
      log(
        'Login was unsuccessful.',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Login was unsuccessful. Check your connection and try again.',
              ),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final auth = ref.read(userAuthenticationProvider.notifier);
    // Sign in with Apple is offered on iOS only.
    final showApple =
        !kIsWeb && Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      backgroundColor: t.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackground(),
          if (_isSigningIn)
            Center(child: CircularProgressIndicator(color: t.accentText))
          else
            SafeArea(
              // The design places the buttons 44 above the bottom edge.
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 42, 24, 44),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(t.radii.button),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: Transform.scale(
                            scale: 1.12,
                            child: Image.asset(
                              'assets/icon/icon.png',
                              fit: BoxFit.cover,
                              semanticLabel: 'FittenUp',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'WELCOME',
                      style: AppTypography.labelLarge
                          .copyWith(color: t.accentText),
                    ),
                    SizedBox(height: t.spacing.gap14),
                    const Text(
                      'Track your workouts. Crush your goals.',
                      style: AppTypography.headline,
                    ),
                    const Spacer(),
                    if (showApple) ...[
                      AppButton(
                        label: 'Sign in with Apple',
                        style: AppButtonStyle.inverse,
                        onPressed: () => _signIn(auth.signInWithApple),
                      ),
                      SizedBox(height: t.spacing.gap10),
                    ],
                    AppButton(
                      label: 'Sign in with Google',
                      style: AppButtonStyle.card,
                      onPressed: () => _signIn(auth.signInWithGoogle),
                    ),
                    SizedBox(height: t.spacing.gap22),
                    Center(
                      child: InkWell(
                        onTap: _openPrivacyPolicy,
                        borderRadius: BorderRadius.circular(t.radii.chip),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Text(
                            'Privacy Policy',
                            style: AppTypography.bodySmall
                                .copyWith(color: t.muted),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
