import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/screens/welcome/welcome_screen.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

Future<FakeAuthNotifier> pumpWelcome(WidgetTester tester) async {
  final auth = FakeAuthNotifier(null, AuthStatus.signedOut);
  await pumpApp(
    tester,
    const WelcomeScreen(),
    overrides: [userAuthenticationProvider.overrideWith(() => auth)],
  );
  return auth;
}

void main() {
  testWidgets('on iOS both sign-in buttons call the existing sign-in methods',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final auth = await pumpWelcome(tester);

    expect(find.text('WELCOME'), findsOneWidget);
    expect(find.text('Track your workouts. Crush your goals.'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);

    await tester.tap(find.text('Sign in with Apple'));
    await tester.pumpAndSettle();
    expect(auth.appleSignIns, 1);
    expect(auth.googleSignIns, 0);

    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();
    expect(auth.googleSignIns, 1);
    expect(auth.appleSignIns, 1);

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('on Android only Google sign-in is offered', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final auth = await pumpWelcome(tester);

    expect(find.text('Sign in with Apple'), findsNothing);
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();
    expect(auth.googleSignIns, 1);

    debugDefaultTargetPlatformOverride = null;
  });
}
