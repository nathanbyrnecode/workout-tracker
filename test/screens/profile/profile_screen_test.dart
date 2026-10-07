import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/theme_mode_storage.dart';
import 'package:gym_tracker_app/screens/profile/profile_screen.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/state/theme_mode_state.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/theme/app_theme.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';

import '../../helpers/fakes.dart';
import '../../helpers/golden.dart';

/// Profile under the real theme switching, as `App` wires it.
class _ThemedProfile extends ConsumerWidget {
  const _ThemedProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider).themeMode,
      home: const Scaffold(body: ProfileScreen()),
    );
  }
}

Future<({FakeAuthNotifier auth, FakeThemeModeStorage storage})> pumpProfile(
  WidgetTester tester, {
  int workouts = 3,
  Brightness system = Brightness.light,
}) async {
  final auth = FakeAuthNotifier();
  final storage = FakeThemeModeStorage();
  await loadAppFonts();
  await tester.binding.setSurfaceSize(goldenSurfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.platformDispatcher.platformBrightnessTestValue = system;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userAuthenticationProvider.overrideWith(() => auth),
        pastWorkoutsProvider.overrideWith(
          () => FakePastWorkoutsNotifier([
            for (var i = 0; i < workouts; i++)
              testWorkout(i + 1, DateTime(2026, 10, i + 1)),
          ]),
        ),
        themeModeStorageProvider.overrideWithValue(storage),
      ],
      child: const _ThemedProfile(),
    ),
  );
  await tester.pumpAndSettle();
  return (auth: auth, storage: storage);
}

Color background(WidgetTester tester) =>
    tester.element(find.byType(ProfileScreen)).tokens.bg;

void main() {
  testWidgets('shows who is signed in and how many workouts are logged',
      (tester) async {
    await pumpProfile(tester);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Nathan'), findsOneWidget);
    expect(find.text('N'), findsOneWidget);
    expect(find.text('3 WORKOUTS LOGGED'), findsOneWidget);
  });

  testWidgets('one workout is singular', (tester) async {
    await pumpProfile(tester, workouts: 1);
    expect(find.text('1 WORKOUT LOGGED'), findsOneWidget);
  });

  testWidgets('appearance follows the system until the user picks',
      (tester) async {
    final profile = await pumpProfile(tester, system: Brightness.dark);
    expect(background(tester), AppTokens.dark.bg);
    expect(profile.storage.value, isNull);
  });

  testWidgets('picking an appearance switches at once and is saved',
      (tester) async {
    final profile = await pumpProfile(tester, system: Brightness.light);
    expect(background(tester), AppTokens.light.bg);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(background(tester), AppTokens.dark.bg);
    expect(profile.storage.value, 'dark');

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(background(tester), AppTokens.light.bg);
    expect(profile.storage.value, 'light');
  });

  testWidgets('sign out calls the existing sign-out', (tester) async {
    final profile = await pumpProfile(tester);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(profile.auth.signOuts, 1);
  });

  testWidgets('delete account asks first and Cancel deletes nothing',
      (tester) async {
    final profile = await pumpProfile(tester);
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete account?'), findsOneWidget);
    expect(
      find.text(
          'This permanently removes your account and all workout history.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(profile.auth.deletions, 0);
    expect(find.text('Delete account?'), findsNothing);

    // Tapping outside the sheet does not delete either.
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 40));
    await tester.pumpAndSettle();
    expect(profile.auth.deletions, 0);
  });

  testWidgets('confirming calls the existing account deletion', (tester) async {
    final profile = await pumpProfile(tester);
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account').last);
    await tester.pumpAndSettle();

    expect(profile.auth.deletions, 1);
    expect(find.text('Deleting account…'), findsOneWidget);
  });

  testWidgets('a failed deletion says so and can be tried again',
      (tester) async {
    final profile = await pumpProfile(tester);
    profile.auth.failDeletion = true;
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Your account could not be deleted. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Delete account'), findsOneWidget);
    expect(find.text('Deleting account…'), findsNothing);
  });
}
