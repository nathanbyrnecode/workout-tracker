import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/screens/welcome/welcome_screen.dart';
import 'package:gym_tracker_app/screens/welcome/widgets/email_auth_sheet.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';
import 'package:gym_tracker_app/widgets/app_text_link.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

Future<FakeAuthNotifier> openSheet(WidgetTester tester) async {
  final auth = FakeAuthNotifier(null, AuthStatus.signedOut);
  await pumpApp(
    tester,
    const WelcomeScreen(),
    overrides: [userAuthenticationProvider.overrideWith(() => auth)],
  );
  await tester.tap(find.text('Sign in with email'));
  await settle(tester);
  return auth;
}

/// Lets the sheet animate without running down the resend countdown, which
/// pumpAndSettle would do.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder field(String label) => find.descendant(
      of: find
          .ancestor(
            of: find.text(label),
            matching: find.byType(Column),
          )
          .first,
      matching: find.byType(TextField),
    );

Future<void> enter(WidgetTester tester, String label, String text) async {
  await tester.enterText(field(label).first, text);
  await tester.pump();
}

bool enabled(WidgetTester tester, String button) =>
    tester
        .widget<AppButton>(find.widgetWithText(AppButton, button))
        .onPressed !=
    null;

bool linkEnabled(WidgetTester tester, String label) =>
    tester.widget<AppTextLink>(find.widgetWithText(AppTextLink, label)).onTap !=
    null;

Future<void> tapButton(WidgetTester tester, String button) async {
  await tester.ensureVisible(find.widgetWithText(AppButton, button));
  await tester.tap(find.widgetWithText(AppButton, button));
  await settle(tester);
}

Future<void> tapLink(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.widgetWithText(AppTextLink, label));
  await tester.tap(find.widgetWithText(AppTextLink, label));
  await settle(tester);
}

bool get sheetOpen => find.byType(EmailAuthForm).evaluate().isNotEmpty;

void main() {
  testWidgets('signs in and closes once the details are filled in',
      (tester) async {
    final auth = await openSheet(tester);

    expect(sheetOpen, isTrue);
    expect(enabled(tester, 'Sign in'), isFalse);
    await enter(tester, 'EMAIL', 'lee@example');
    await enter(tester, 'PASSWORD', 'secret');
    expect(enabled(tester, 'Sign in'), isFalse);
    await enter(tester, 'EMAIL', 'lee@example.com');
    expect(enabled(tester, 'Sign in'), isTrue);

    await tapButton(tester, 'Sign in');

    expect(auth.emailCalls.single.method, 'signInWithEmail');
    expect(auth.emailCalls.single.args,
        {'email': 'lee@example.com', 'password': 'secret'});
    expect(sheetOpen, isFalse);
  });

  testWidgets('wrong details keep the sheet open with a message',
      (tester) async {
    final auth = await openSheet(tester);
    auth.emailResults['signInWithEmail'] = EmailAuthResult.invalidCredentials;

    await enter(tester, 'EMAIL', 'lee@example.com');
    await enter(tester, 'PASSWORD', 'wrong');
    await tapButton(tester, 'Sign in');

    expect(sheetOpen, isTrue);
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
  });

  testWidgets('the password can be shown', (tester) async {
    await openSheet(tester);
    await enter(tester, 'PASSWORD', 'secret');
    TextField password() => tester.widget<TextField>(field('PASSWORD').first);

    expect(password().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(password().obscureText, isFalse);
  });

  testWidgets('an unconfirmed account goes to the code step', (tester) async {
    final auth = await openSheet(tester);
    auth.emailResults['signInWithEmail'] = EmailAuthResult.emailNotConfirmed;

    await enter(tester, 'EMAIL', ' Lee@Example.com');
    await enter(tester, 'PASSWORD', 'secret');
    await tapButton(tester, 'Sign in');

    expect(find.text('Check your email'), findsOneWidget);
    expect(
      find.textContaining('not confirmed yet', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('lee@example.com'), findsOneWidget);
    expect(enabled(tester, 'Confirm'), isFalse);

    await enter(tester, 'CODE', '12345');
    expect(enabled(tester, 'Confirm'), isFalse);
    await enter(tester, 'CODE', '123456');
    await tapButton(tester, 'Confirm');

    expect(auth.emailCalls.last.method, 'confirmEmail');
    expect(auth.emailCalls.last.args['code'], '123456');
    expect(sheetOpen, isFalse);
  });

  testWidgets('the code field takes six digits only', (tester) async {
    final auth = await openSheet(tester);
    auth.emailResults['signInWithEmail'] = EmailAuthResult.emailNotConfirmed;
    await enter(tester, 'EMAIL', 'lee@example.com');
    await enter(tester, 'PASSWORD', 'secret');
    await tapButton(tester, 'Sign in');

    await enter(tester, 'CODE', '12a34567');

    expect(tester.widget<TextField>(field('CODE')).controller!.text, '123456');
  });

  testWidgets('a code can be sent again after a minute', (tester) async {
    final auth = await openSheet(tester);
    auth.emailResults['signInWithEmail'] = EmailAuthResult.emailNotConfirmed;
    await enter(tester, 'EMAIL', 'lee@example.com');
    await enter(tester, 'PASSWORD', 'secret');
    await tapButton(tester, 'Sign in');

    expect(linkEnabled(tester, 'Send again in 60s'), isFalse);
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Send again in 30s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    expect(linkEnabled(tester, 'Send again'), isTrue);

    await tapLink(tester, 'Send again');

    expect(auth.emailCalls.last.method, 'resendConfirmation');
    expect(find.text('Send again in 60s'), findsOneWidget);
  });

  testWidgets('a wrong code keeps the sheet open with a message',
      (tester) async {
    final auth = await openSheet(tester);
    auth.emailResults['signInWithEmail'] = EmailAuthResult.emailNotConfirmed;
    auth.emailResults['confirmEmail'] = EmailAuthResult.invalidCode;
    await enter(tester, 'EMAIL', 'lee@example.com');
    await enter(tester, 'PASSWORD', 'secret');
    await tapButton(tester, 'Sign in');

    await enter(tester, 'CODE', '000000');
    await tapButton(tester, 'Confirm');

    expect(sheetOpen, isTrue);
    expect(find.textContaining('wrong or has expired'), findsOneWidget);
  });

  testWidgets('creates an account and asks for the code', (tester) async {
    final auth = await openSheet(tester);

    await tapLink(tester, 'Create an account');
    expect(find.text('Create an account'), findsOneWidget);
    await enter(tester, 'FIRST NAME', 'Lee');
    await enter(tester, 'EMAIL', 'lee@example.com');
    await enter(tester, 'PASSWORD', '1234567');
    expect(enabled(tester, 'Create account'), isFalse);
    await enter(tester, 'PASSWORD', '12345678');
    expect(enabled(tester, 'Create account'), isTrue);

    await tapButton(tester, 'Create account');

    expect(auth.emailCalls.single.method, 'signUpWithEmail');
    expect(auth.emailCalls.single.args, {
      'email': 'lee@example.com',
      'password': '12345678',
      'firstName': 'Lee',
    });
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('already have an account'), findsOneWidget);
  });

  testWidgets('a rejected password on sign-up says why', (tester) async {
    final auth = await openSheet(tester);
    auth.emailResults['signUpWithEmail'] = EmailAuthResult.weakPassword;

    await tapLink(tester, 'Create an account');
    await enter(tester, 'EMAIL', 'lee@example.com');
    await enter(tester, 'PASSWORD', 'password');
    await tapButton(tester, 'Create account');

    expect(find.textContaining('data breach'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('resets a forgotten password and signs in', (tester) async {
    final auth = await openSheet(tester);

    await enter(tester, 'EMAIL', 'lee@example.com');
    await tapLink(tester, 'Forgot password?');
    expect(enabled(tester, 'Send code'), isTrue);
    await tapButton(tester, 'Send code');

    expect(auth.emailCalls.single.method, 'sendPasswordReset');
    expect(find.textContaining("we've sent it"), findsOneWidget);
    await enter(tester, 'CODE', '123456');
    await enter(tester, 'NEW PASSWORD', 'short');
    expect(enabled(tester, 'Set password and sign in'), isFalse);
    await enter(tester, 'NEW PASSWORD', 'long enough');
    await tapButton(tester, 'Set password and sign in');

    expect(auth.emailCalls.last.method, 'resetPassword');
    expect(auth.emailCalls.last.args, {
      'email': 'lee@example.com',
      'code': '123456',
      'newPassword': 'long enough',
    });
    expect(sheetOpen, isFalse);
  });

  testWidgets('leaving a reset part-way drops its session', (tester) async {
    final auth = await openSheet(tester);
    await enter(tester, 'EMAIL', 'lee@example.com');
    await tapLink(tester, 'Forgot password?');
    await tapButton(tester, 'Send code');

    await tapLink(tester, 'Back to sign in');
    expect(auth.passwordResetCancels, 1);
    expect(find.text('Sign in with email'), findsWidgets);

    await tapLink(tester, 'Forgot password?');
    await tapButton(tester, 'Send code');
    Navigator.of(tester.element(find.byType(EmailAuthForm))).pop();
    await settle(tester);
    expect(sheetOpen, isFalse);
    expect(auth.passwordResetCancels, 2);
  });

  testWidgets('links are disabled while a step runs', (tester) async {
    final auth = await openSheet(tester);
    final gate = Completer<void>();
    auth.emailGate = gate.future;
    await enter(tester, 'EMAIL', 'lee@example.com');
    await enter(tester, 'PASSWORD', 'secret');

    await tapButton(tester, 'Sign in');

    expect(find.widgetWithText(AppButton, 'Signing in…'), findsOneWidget);
    expect(linkEnabled(tester, 'Create an account'), isFalse);
    expect(linkEnabled(tester, 'Forgot password?'), isFalse);

    gate.complete();
    await settle(tester);
    expect(sheetOpen, isFalse);
  });
}
