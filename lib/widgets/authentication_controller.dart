import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/screens/welcome/welcome_screen.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/widgets/app_background.dart';

class AuthenticatorController extends ConsumerStatefulWidget {
  const AuthenticatorController({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AuthenticatorControllerState();
}

class _AuthenticatorControllerState
    extends ConsumerState<AuthenticatorController> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(userAuthenticationProvider.notifier).restoreSession();

      log('Silent auth check');
    });
  }

  @override
  Widget build(BuildContext context) {
    final signedInStatus = ref.watch(userAuthenticationProvider).isSignedIn;

    return switch (signedInStatus) {
      AuthStatus.unknown => Scaffold(
          backgroundColor: context.tokens.bg,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const AppBackground(),
              Center(
                child: CircularProgressIndicator(
                  color: context.tokens.accentText,
                ),
              ),
            ],
          ),
        ),
      AuthStatus.signedIn => widget.child,
      AuthStatus.signedOut => const WelcomeScreen(),
    };
  }
}
