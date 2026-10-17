import 'dart:convert';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gym_tracker_app/data/email_auth.dart';
import 'package:gym_tracker_app/data/supabase_client_provider.dart';
import 'package:gym_tracker_app/state/current_tab_state.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/manual_workouts_state.dart';
import 'package:gym_tracker_app/state/notifications_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'user_authentication_state.g.dart';

enum AuthStatus {
  unknown,
  signedIn,
  signedOut,
}

enum _IdentityProvider {
  apple,
  google,
  email,
}

/// How an email sign-in step ended, so the sheet can say the right thing
/// without reading exceptions.
enum EmailAuthResult {
  signedIn,

  /// A 6-digit code is on its way. Also reported when the address already
  /// has an account, which Supabase does not reveal.
  codeSent,
  invalidCredentials,

  /// The password was right but the address was never confirmed. A new code
  /// has been sent.
  emailNotConfirmed,
  invalidCode,
  weakPassword,
  rateLimited,
  failed,
}

typedef UserAuthenticationStateData = ({
  AuthStatus isSignedIn,
  String? firstName,
});

const UserAuthenticationStateData initialUserAuthenticationStateData =
    (isSignedIn: AuthStatus.unknown, firstName: null);

@Riverpod(keepAlive: true)
class UserAuthenticationNotifier extends _$UserAuthenticationNotifier {
  late final GoogleSignIn _googleSignIn;

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  @override
  UserAuthenticationStateData build() {
    _googleSignIn = GoogleSignIn.instance;
    return initialUserAuthenticationStateData;
  }

  void _setState({
    AuthStatus? isSignedIn,
    String? firstName,
  }) {
    state = (
      isSignedIn: isSignedIn ?? state.isSignedIn,
      firstName: firstName ?? state.firstName,
    );
  }

  Future<void> _completeSignIn({String? firstName}) async {
    // Start recovery before exposing the home screen and its workout actions.
    final recovery =
        ref.read(currentWorkoutProvider.notifier).restoreActiveWorkout();
    _setState(
      isSignedIn: AuthStatus.signedIn,
      firstName: firstName,
    );
    await Future.wait([
      recovery,
      ref.read(pastWorkoutsProvider.notifier).getWorkoutsFromRemote(),
      ref.read(manualWorkoutsProvider.notifier).getManualWorkoutsFromRemote(),
    ]);
  }

  void _resetSignedOutState() {
    ref.read(currentWorkoutProvider.notifier).resetState();
    ref.read(pastWorkoutsProvider.notifier).resetState();
    ref.read(manualWorkoutsProvider.notifier).resetState();
    ref.read(currentTabProvider.notifier).resetState();
    ref.read(notificationsProvider.notifier).resetState();
    state = (
      isSignedIn: AuthStatus.signedOut,
      firstName: initialUserAuthenticationStateData.firstName,
    );
  }

  bool _hasIdentityProvider(_IdentityProvider provider) {
    final user = _client.auth.currentUser;
    final providers = user?.appMetadata['providers'];
    final providerName = provider.name;

    return user?.identities
                ?.any((identity) => identity.provider == providerName) ==
            true ||
        user?.appMetadata['provider'] == providerName ||
        providers is List && providers.contains(providerName);
  }

  Set<_IdentityProvider> _currentIdentityProviders() {
    return _IdentityProvider.values.where(_hasIdentityProvider).toSet();
  }

  String _identityProviderName(_IdentityProvider provider) {
    return switch (provider) {
      _IdentityProvider.apple => 'Apple',
      _IdentityProvider.google => 'Google',
      _IdentityProvider.email => 'email',
    };
  }

  void _logSuccessfulSignOut(Set<_IdentityProvider> providers) {
    if (providers.isEmpty) {
      log('Successfully signed out of the Supabase account.');
      return;
    }

    for (final provider in providers) {
      log(
        'Successfully signed out of the '
        '${_identityProviderName(provider)} account.',
      );
    }
  }

  void _logSuccessfulAccountDeletion(Set<_IdentityProvider> providers) {
    if (providers.isEmpty) {
      log('Successfully deleted the Supabase account data.');
      return;
    }

    for (final provider in providers) {
      log(
        'Successfully deleted the '
        '${_identityProviderName(provider)} account data.',
      );
    }
  }

  Future<void> _storeAppleDeletionCredential(
    String authorizationCode,
  ) async {
    final response = await _client.functions.invoke(
      'store-apple-token',
      body: {'authorizationCode': authorizationCode},
    );
    final responseData = response.data;
    final storageConfirmed = response.status == 200 &&
        responseData is Map<String, dynamic> &&
        responseData['stored'] == true;

    if (!storageConfirmed) {
      throw StateError(
        'Supabase did not confirm Apple authorization storage.',
      );
    }
  }

  Future<void> _clearSessionAfterFailedSignIn() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (error, stackTrace) {
      log(
        'Failed to clear the Supabase session after an unsuccessful login.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String? _firstNameOf(User? user) {
    final fullName = (user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name']) as String?;
    return fullName?.split(' ').first;
  }

  Future<void> restoreSession() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      await _completeSignIn(firstName: _firstNameOf(user));
      return;
    }

    await signInWithGoogle(silentOnly: true);
  }

  Future<void> signInWithGoogle({bool silentOnly = false}) async {
    try {
      GoogleSignInAccount? googleUser;
      if (silentOnly) {
        googleUser = await _googleSignIn.attemptLightweightAuthentication();
      }
      if (googleUser == null && !silentOnly) {
        googleUser = await _googleSignIn.authenticate();
      }

      if (googleUser == null) {
        _resetSignedOutState();
        return;
      }

      final scopes = ['email', 'profile'];

      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(scopes) ??
              await googleUser.authorizationClient.authorizeScopes(scopes);
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('No ID token found.');
      }
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );

      if (response.session == null || response.user == null) {
        throw const AuthException(
          'Supabase did not return a session after Google login.',
        );
      }

      log('Successfully signed in with Google and authenticated with Supabase.');
      await _completeSignIn(
        firstName:
            (response.user?.userMetadata?['name'] as String?)?.split(' ').first,
      );
    } on GoogleSignInException catch (error, stackTrace) {
      _resetSignedOutState();
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return;
      }

      log(
        'Google sign in failed.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!silentOnly) {
        rethrow;
      }
    } catch (error, stackTrace) {
      log(
        'Google sign in failed.',
        error: error,
        stackTrace: stackTrace,
      );
      _resetSignedOutState();
      if (!silentOnly) {
        rethrow;
      }
    }
  }

  Future<void> signInWithApple() async {
    try {
      final rawNonce = _client.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;

      if (idToken == null) {
        throw const AuthException(
          'Could not find an ID token in the Apple credential.',
        );
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (response.session == null || response.user == null) {
        throw const AuthException(
          'Supabase did not return a session after Apple login.',
        );
      }

      await _storeAppleDeletionCredential(credential.authorizationCode);

      final givenName = credential.givenName?.trim();
      final familyName = credential.familyName?.trim();
      final fullName = [givenName, familyName]
          .whereType<String>()
          .where((name) => name.isNotEmpty)
          .join(' ');

      if (fullName.isNotEmpty) {
        await _client.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': fullName,
              if (givenName?.isNotEmpty ?? false) 'given_name': givenName,
              if (familyName?.isNotEmpty ?? false) 'family_name': familyName,
            },
          ),
        );
      }

      log('Successfully signed in with Apple and authenticated with Supabase.');
      await _completeSignIn(
        firstName: givenName ??
            (response.user?.userMetadata?['full_name'] as String?)
                ?.split(' ')
                .first,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      _resetSignedOutState();
      if (error.code == AuthorizationErrorCode.canceled) {
        return;
      }

      log('Apple sign in failed.', error: error);
      rethrow;
    } catch (error, stackTrace) {
      log(
        'Apple sign in failed.',
        error: error,
        stackTrace: stackTrace,
      );
      await _clearSessionAfterFailedSignIn();
      _resetSignedOutState();
      rethrow;
    }
  }

  EmailAuthResult _resultFor(AuthException error) {
    if (error.statusCode == '429') {
      return EmailAuthResult.rateLimited;
    }
    return switch (error.code) {
      'invalid_credentials' => EmailAuthResult.invalidCredentials,
      'email_not_confirmed' => EmailAuthResult.emailNotConfirmed,
      'otp_expired' => EmailAuthResult.invalidCode,
      'weak_password' => EmailAuthResult.weakPassword,
      'over_email_send_rate_limit' ||
      'over_request_rate_limit' =>
        EmailAuthResult.rateLimited,
      _ => EmailAuthResult.failed,
    };
  }

  /// Runs one step of an email flow, turning failures into a result, and
  /// finishes signing in when the step ends with a session.
  Future<EmailAuthResult> _emailStep(
    String description,
    Future<EmailAuthResult> Function() step,
  ) async {
    EmailAuthResult result;
    try {
      result = await step();
    } on AuthException catch (error, stackTrace) {
      log('Email $description failed.', error: error, stackTrace: stackTrace);
      result = _resultFor(error);
    } catch (error, stackTrace) {
      log('Email $description failed.', error: error, stackTrace: stackTrace);
      result = EmailAuthResult.failed;
    }

    if (result == EmailAuthResult.signedIn) {
      log('Successfully signed in with email and authenticated with Supabase.');
      await _completeSignIn(firstName: _firstNameOf(_client.auth.currentUser));
    }
    return result;
  }

  Future<EmailAuthResult> signInWithEmail({
    required String email,
    required String password,
  }) {
    final address = normaliseEmail(email);
    return _emailStep('sign in', () async {
      try {
        await _client.auth.signInWithPassword(
          email: address,
          password: password,
        );
        return EmailAuthResult.signedIn;
      } on AuthException catch (error) {
        if (error.code != 'email_not_confirmed') {
          rethrow;
        }
        // The first code may have expired, so send another.
        await _client.auth.resend(type: OtpType.signup, email: address);
        return EmailAuthResult.emailNotConfirmed;
      }
    });
  }

  /// Creates an account and sends a confirmation code. Supabase reports
  /// success for an address that already has an account and sends nothing,
  /// so the result never reveals who is registered.
  Future<EmailAuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? firstName,
  }) {
    final name = firstName?.trim() ?? '';
    return _emailStep('sign up', () async {
      final response = await _client.auth.signUp(
        email: normaliseEmail(email),
        password: password,
        data: {if (name.isNotEmpty) 'full_name': name},
      );
      // With "Confirm email" off in the dashboard, sign-up signs straight in.
      return response.session == null
          ? EmailAuthResult.codeSent
          : EmailAuthResult.signedIn;
    });
  }

  Future<EmailAuthResult> confirmEmail({
    required String email,
    required String code,
  }) {
    return _emailStep('confirmation', () async {
      final response = await _client.auth.verifyOTP(
        type: OtpType.signup,
        email: normaliseEmail(email),
        token: code.trim(),
      );
      return response.session == null
          ? EmailAuthResult.failed
          : EmailAuthResult.signedIn;
    });
  }

  Future<EmailAuthResult> resendConfirmation({required String email}) {
    return _emailStep('confirmation resend', () async {
      await _client.auth.resend(
        type: OtpType.signup,
        email: normaliseEmail(email),
      );
      return EmailAuthResult.codeSent;
    });
  }

  /// Sends a reset code. Supabase reports success for unknown addresses too.
  Future<EmailAuthResult> sendPasswordReset({required String email}) {
    return _emailStep('password reset request', () async {
      await _client.auth.resetPasswordForEmail(normaliseEmail(email));
      return EmailAuthResult.codeSent;
    });
  }

  /// Checks the reset code, sets the new password and signs in.
  ///
  /// The code gives a session before the password is set. If setting it
  /// fails, that session is kept so a retry with a different password skips
  /// the code, which can only be used once. [cancelPasswordReset] drops it.
  Future<EmailAuthResult> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    final address = normaliseEmail(email);
    return _emailStep('password reset', () async {
      if (_client.auth.currentUser?.email != address) {
        final response = await _client.auth.verifyOTP(
          type: OtpType.recovery,
          email: address,
          token: code.trim(),
        );
        if (response.session == null) {
          return EmailAuthResult.failed;
        }
      }
      try {
        await _client.auth.updateUser(UserAttributes(password: newPassword));
      } on AuthException catch (error) {
        // They chose the password they already had; the code proved it is
        // their account, so sign in with it.
        if (error.code != 'same_password') {
          rethrow;
        }
      }
      return EmailAuthResult.signedIn;
    });
  }

  /// Drops the session left by a reset code whose new password was never
  /// set, so it does not sign the user in on the next launch.
  Future<void> cancelPasswordReset() async {
    if (state.isSignedIn == AuthStatus.signedIn ||
        _client.auth.currentUser == null) {
      return;
    }
    await _clearSessionAfterFailedSignIn();
  }

  Future<void> signOut() async {
    final identityProviders = _currentIdentityProviders();

    try {
      await _googleSignIn.signOut();
    } finally {
      try {
        await _client.auth.signOut();
        _logSuccessfulSignOut(identityProviders);
      } finally {
        _resetSignedOutState();
      }
    }
  }

  Future<void> deleteAccount() async {
    final identityProviders = _currentIdentityProviders();
    final hasAppleIdentity =
        identityProviders.contains(_IdentityProvider.apple);
    final hasGoogleIdentity =
        identityProviders.contains(_IdentityProvider.google);

    if (hasAppleIdentity) {
      await _deleteAppleAccount();
    } else {
      await _deleteSupabaseAccount(requireAppleRevocation: false);
    }
    _logSuccessfulAccountDeletion(identityProviders);

    if (hasGoogleIdentity) {
      await _deleteGoogleAccount();
    }

    try {
      await _client.auth.signOut(scope: SignOutScope.local);
      _logSuccessfulSignOut(identityProviders);
    } finally {
      _resetSignedOutState();
    }
  }

  Future<void> _deleteAppleAccount() async {
    await _deleteSupabaseAccount(requireAppleRevocation: true);
  }

  Future<void> _deleteSupabaseAccount({
    required bool requireAppleRevocation,
  }) async {
    final response = await _client.functions.invoke(
      'delete-account',
    );
    final responseData = response.data;
    final deletionConfirmed = response.status == 200 &&
        responseData is Map<String, dynamic> &&
        responseData['deleted'] == true &&
        (!requireAppleRevocation ||
            responseData['appleAuthorizationRevoked'] == true);

    if (!deletionConfirmed) {
      final errorMessage =
          responseData is Map<String, dynamic> ? responseData['error'] : null;
      throw StateError(
        errorMessage is String
            ? errorMessage
            : 'Supabase did not confirm account deletion.',
      );
    }
  }

  Future<void> _deleteGoogleAccount() async {
    try {
      await _googleSignIn.disconnect();
    } catch (error, stackTrace) {
      log(
        'The Google authorization could not be disconnected.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void resetState() => state = initialUserAuthenticationStateData;
}
