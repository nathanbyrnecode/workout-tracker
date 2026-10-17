import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/supabase_client_provider.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/manual_workouts_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fakes.dart';

const _email = 'lee@example.com';

Map<String, dynamic> _user({Map<String, dynamic> metadata = const {}}) => {
      'id': 'user-a',
      'aud': 'authenticated',
      'email': _email,
      'app_metadata': {
        'provider': 'email',
        'providers': ['email'],
      },
      'user_metadata': metadata,
      'created_at': '2026-01-01T00:00:00Z',
    };

Map<String, dynamic> _session({Map<String, dynamic> metadata = const {}}) => {
      'access_token': 'access-token',
      'token_type': 'bearer',
      'expires_in': 3600,
      'expires_at':
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
      'refresh_token': 'refresh-token',
      'user': _user(metadata: metadata),
    };

http.Response _json(Object data, [int status = 200]) => http.Response(
      jsonEncode(data),
      status,
      headers: {'content-type': 'application/json'},
    );

http.Response _error(String code, int status) =>
    _json({'error_code': code, 'code': code, 'msg': code}, status);

class _MemoryStorage extends GotrueAsyncStorage {
  final _items = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _items[key];

  @override
  Future<void> removeItem({required String key}) async => _items.remove(key);

  @override
  Future<void> setItem({required String key, required String value}) async =>
      _items[key] = value;
}

void main() {
  late SupabaseClient client;
  late ProviderContainer container;
  late List<http.Request> requests;

  /// Answers by endpoint, such as `POST token` or `PUT user`.
  late Map<String, http.Response Function()> routes;

  UserAuthenticationNotifier notifier() =>
      container.read(userAuthenticationProvider.notifier);
  UserAuthenticationStateData state() =>
      container.read(userAuthenticationProvider);
  List<String> hits() => [
        for (final request in requests)
          '${request.method} ${request.url.pathSegments.last}',
      ];
  Map<String, dynamic> bodyOf(String endpoint) => jsonDecode(requests
      .firstWhere((r) => '${r.method} ${r.url.pathSegments.last}' == endpoint)
      .body) as Map<String, dynamic>;

  setUp(() {
    requests = [];
    routes = {'POST logout': () => http.Response('', 204)};
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      // The app's client uses PKCE, which stores a verifier for email flows.
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        pkceAsyncStorage: _MemoryStorage(),
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        final route =
            routes['${request.method} ${request.url.pathSegments.last}'];
        if (route == null) {
          throw http.ClientException('No route for ${request.url}');
        }
        final response = route();
        return http.Response.bytes(response.bodyBytes, response.statusCode,
            headers: response.headers, request: request);
      }),
    );
    container = ProviderContainer(overrides: [
      supabaseClientProvider.overrideWithValue(client),
      currentWorkoutProvider.overrideWith(() => FakeWorkoutNotifier()),
      pastWorkoutsProvider.overrideWith(() => FakePastWorkoutsNotifier()),
      manualWorkoutsProvider.overrideWith(() => FakeManualWorkoutsNotifier()),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await client.dispose();
  });

  group('sign in', () {
    test('signs in with a tidied address and takes the stored first name',
        () async {
      routes['POST token'] =
          () => _json(_session(metadata: {'full_name': 'Lee Smith'}));

      final result = await notifier().signInWithEmail(
        email: ' Lee@Example.com ',
        password: 'correct horse',
      );

      expect(result, EmailAuthResult.signedIn);
      expect(state().isSignedIn, AuthStatus.signedIn);
      expect(state().firstName, 'Lee');
      expect(requests.single.url.queryParameters['grant_type'], 'password');
      expect(bodyOf('POST token'), containsPair('email', _email));
      expect(bodyOf('POST token'), containsPair('password', 'correct horse'));
    });

    test('reports wrong details without signing in', () async {
      routes['POST token'] = () => _error('invalid_credentials', 400);

      final result = await notifier().signInWithEmail(
        email: _email,
        password: 'wrong password',
      );

      expect(result, EmailAuthResult.invalidCredentials);
      expect(state().isSignedIn, isNot(AuthStatus.signedIn));
    });

    test('sends a fresh code when the address was never confirmed', () async {
      routes['POST token'] = () => _error('email_not_confirmed', 400);
      routes['POST resend'] = () => _json({});

      final result = await notifier().signInWithEmail(
        email: _email,
        password: 'correct horse',
      );

      expect(result, EmailAuthResult.emailNotConfirmed);
      expect(hits(), ['POST token', 'POST resend']);
      expect(bodyOf('POST resend'), containsPair('type', 'signup'));
      expect(bodyOf('POST resend'), containsPair('email', _email));
      expect(state().isSignedIn, isNot(AuthStatus.signedIn));
    });

    test('reports rate limits and network failures', () async {
      routes['POST token'] = () => _error('over_request_rate_limit', 429);
      expect(
        await notifier().signInWithEmail(email: _email, password: 'whatever!'),
        EmailAuthResult.rateLimited,
      );

      routes.remove('POST token');
      expect(
        await notifier().signInWithEmail(email: _email, password: 'whatever!'),
        EmailAuthResult.failed,
      );

      routes['POST token'] = () => http.Response('oops', 500);
      expect(
        await notifier().signInWithEmail(email: _email, password: 'whatever!'),
        EmailAuthResult.failed,
      );
      expect(state().isSignedIn, isNot(AuthStatus.signedIn));
    });
  });

  group('sign up', () {
    test('creates the account with the first name and waits for the code',
        () async {
      routes['POST signup'] = () => _json(_user());

      final result = await notifier().signUpWithEmail(
        email: 'LEE@example.com',
        password: 'correct horse',
        firstName: '  Lee ',
      );

      expect(result, EmailAuthResult.codeSent);
      expect(state().isSignedIn, isNot(AuthStatus.signedIn));
      final body = bodyOf('POST signup');
      expect(body['email'], _email);
      expect(body['password'], 'correct horse');
      expect(body['data'], {'full_name': 'Lee'});
    });

    test('leaves the name out when none was given', () async {
      routes['POST signup'] = () => _json(_user());

      await notifier().signUpWithEmail(email: _email, password: 'abcdefgh');

      expect(bodyOf('POST signup')['data'], isEmpty);
    });

    test('signs straight in when confirmation is turned off', () async {
      routes['POST signup'] =
          () => _json(_session(metadata: {'full_name': 'Lee'}));

      final result = await notifier().signUpWithEmail(
        email: _email,
        password: 'correct horse',
        firstName: 'Lee',
      );

      expect(result, EmailAuthResult.signedIn);
      expect(state().isSignedIn, AuthStatus.signedIn);
      expect(state().firstName, 'Lee');
    });

    test('reports an address that already has an account', () async {
      routes['POST signup'] = () => _error('user_already_exists', 422);

      final result = await notifier()
          .signUpWithEmail(email: _email, password: 'correct horse');

      expect(result, EmailAuthResult.accountExists);
      expect(state().isSignedIn, isNot(AuthStatus.signedIn));
    });

    test('reports a password Supabase rejects', () async {
      routes['POST signup'] = () => _json({
            'error_code': 'weak_password',
            'msg': 'Password is known to be weak',
            'weak_password': {
              'reasons': ['pwned'],
            },
          }, 422);

      final result =
          await notifier().signUpWithEmail(email: _email, password: 'password');

      expect(result, EmailAuthResult.weakPassword);
    });
  });

  group('confirm email', () {
    test('signs in with the code', () async {
      routes['POST verify'] =
          () => _json(_session(metadata: {'full_name': 'Lee Smith'}));

      final result =
          await notifier().confirmEmail(email: _email, code: ' 123456 ');

      expect(result, EmailAuthResult.signedIn);
      expect(state().isSignedIn, AuthStatus.signedIn);
      expect(state().firstName, 'Lee');
      final body = bodyOf('POST verify');
      expect(body['type'], 'signup');
      expect(body['email'], _email);
      expect(body['token'], '123456');
    });

    test('reports a wrong or expired code', () async {
      routes['POST verify'] = () => _error('otp_expired', 403);

      final result = await notifier().confirmEmail(email: _email, code: '1');

      expect(result, EmailAuthResult.invalidCode);
      expect(state().isSignedIn, isNot(AuthStatus.signedIn));
    });

    test('sends the code again', () async {
      routes['POST resend'] = () => _json({});

      expect(
        await notifier().resendConfirmation(email: _email),
        EmailAuthResult.codeSent,
      );
      expect(bodyOf('POST resend'), containsPair('type', 'signup'));
    });

    test('reports when codes are sent too often', () async {
      routes['POST resend'] = () => _error('over_email_send_rate_limit', 429);

      expect(
        await notifier().resendConfirmation(email: _email),
        EmailAuthResult.rateLimited,
      );
    });
  });

  group('password reset', () {
    test('sends a reset code', () async {
      routes['POST recover'] = () => _json({});

      expect(
        await notifier().sendPasswordReset(email: ' LEE@example.com'),
        EmailAuthResult.codeSent,
      );
      expect(bodyOf('POST recover')['email'], _email);
    });

    test('checks the code, sets the password and signs in', () async {
      routes['POST verify'] = () => _json(_session());
      routes['PUT user'] = () => _json(_user());

      final result = await notifier().resetPassword(
        email: _email,
        code: '123456',
        newPassword: 'new password',
      );

      expect(result, EmailAuthResult.signedIn);
      expect(hits(), ['POST verify', 'PUT user']);
      expect(bodyOf('POST verify')['type'], 'recovery');
      expect(bodyOf('PUT user')['password'], 'new password');
      expect(state().isSignedIn, AuthStatus.signedIn);
    });

    test('a rejected password can be retried without the used code', () async {
      routes['POST verify'] = () => _json(_session());
      routes['PUT user'] = () => _error('weak_password', 422);

      expect(
        await notifier().resetPassword(
          email: _email,
          code: '123456',
          newPassword: 'password',
        ),
        EmailAuthResult.weakPassword,
      );
      expect(state().isSignedIn, isNot(AuthStatus.signedIn));

      routes['PUT user'] = () => _json(_user());
      expect(
        await notifier().resetPassword(
          email: _email,
          code: '123456',
          newPassword: 'a better password',
        ),
        EmailAuthResult.signedIn,
      );
      expect(hits(), ['POST verify', 'PUT user', 'PUT user']);
    });

    test('choosing the current password still signs in', () async {
      routes['POST verify'] = () => _json(_session());
      routes['PUT user'] = () => _error('same_password', 422);

      expect(
        await notifier().resetPassword(
          email: _email,
          code: '123456',
          newPassword: 'old password',
        ),
        EmailAuthResult.signedIn,
      );
      expect(state().isSignedIn, AuthStatus.signedIn);
    });

    test('reports a wrong code without touching the password', () async {
      routes['POST verify'] = () => _error('otp_expired', 403);

      expect(
        await notifier().resetPassword(
          email: _email,
          code: '000000',
          newPassword: 'new password',
        ),
        EmailAuthResult.invalidCode,
      );
      expect(hits(), ['POST verify']);
    });

    test('cancelling drops the session the code created', () async {
      routes['POST verify'] = () => _json(_session());
      routes['PUT user'] = () => _error('weak_password', 422);
      await notifier().resetPassword(
        email: _email,
        code: '123456',
        newPassword: 'password',
      );
      expect(client.auth.currentUser, isNotNull);

      await notifier().cancelPasswordReset();

      expect(client.auth.currentUser, isNull);
    });

    test('cancelling after signing in keeps the session', () async {
      routes['POST verify'] = () => _json(_session());
      routes['PUT user'] = () => _json(_user());
      await notifier().resetPassword(
        email: _email,
        code: '123456',
        newPassword: 'new password',
      );

      await notifier().cancelPasswordReset();

      expect(client.auth.currentUser, isNotNull);
      expect(hits(), isNot(contains('POST logout')));
    });
  });
}
