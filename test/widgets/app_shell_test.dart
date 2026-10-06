import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/main_bottom_navigation.dart';
import 'package:gym_tracker_app/screens/home/home_screen_v2.dart';
import 'package:gym_tracker_app/screens/notifications/notifications_screen.dart';
import 'package:gym_tracker_app/screens/profile/profile_screen.dart';
import 'package:gym_tracker_app/screens/tracker/tracker_screen.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/theme/app_theme.dart';
import 'package:gym_tracker_app/widgets/app_shell.dart';
import 'package:gym_tracker_app/widgets/app_tab_bar.dart';

Widget app(Widget home) => MaterialApp(
      theme: buildAppTheme(Brightness.dark),
      home: home,
    );

/// The bar draws each label twice, once per selection state.
Finder tabLabel(String label) => find
    .descendant(of: find.byType(AppTabBar), matching: find.text(label))
    .first;

void main() {
  testWidgets('the four tabs switch screens', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentWorkoutProvider.overrideWith(() => _ReadyWorkoutNotifier()),
          userAuthenticationProvider.overrideWith(() => _SignedInNotifier()),
        ],
        child: app(const MainBottomNavigation()),
      ),
    );
    expect(find.byType(HomeScreenV2), findsOneWidget);
    // Home supplies the floating actions; the other tabs have none.
    expect(find.text('Start workout'), findsOneWidget);

    await tester.tap(tabLabel('Tracker'));
    await tester.pumpAndSettle();
    expect(find.byType(TrackerScreen), findsOneWidget);
    expect(find.byType(HomeScreenV2), findsNothing);
    expect(find.text('Start workout'), findsNothing);

    await tester.tap(tabLabel('Notifications'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);

    await tester.tap(tabLabel('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tester.tap(tabLabel('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreenV2), findsOneWidget);
  });

  testWidgets('the tab bar is 340 by 66 and sits 26 above the bottom',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(AppShell(
      selected: AppTab.home,
      onSelected: (_) {},
      child: const SizedBox(),
    )));

    final bar = tester.getRect(find.byType(AppTabBar));
    expect(bar.size, const Size(340, 66));
    expect(bar.left, 25);
    expect(844 - bar.bottom, 26);
  });

  testWidgets('floating actions sit 106 above the bottom with 20 either side',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const key = Key('actions');
    await tester.pumpWidget(app(AppShell(
      selected: AppTab.home,
      onSelected: (_) {},
      floatingActions: const SizedBox(key: key, height: 56),
      child: const SizedBox(),
    )));

    final actions = tester.getRect(find.byKey(key));
    expect(844 - actions.bottom, 106);
    expect(actions.left, 20);
    expect(actions.right, 370);
  });

  testWidgets('the bar moves up when the system inset is taller than its gap',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(MediaQuery(
      data: const MediaQueryData(
        size: Size(390, 844),
        viewPadding: EdgeInsets.only(bottom: 48),
      ),
      child: AppShell(
        selected: AppTab.home,
        onSelected: (_) {},
        child: const SizedBox(),
      ),
    )));

    expect(844 - tester.getRect(find.byType(AppTabBar)).bottom, 56);
  });

  testWidgets('tapping a tab reports it', (tester) async {
    AppTab? tapped;
    await tester.pumpWidget(app(AppShell(
      selected: AppTab.home,
      onSelected: (tab) => tapped = tab,
      child: const SizedBox(),
    )));

    await tester.tap(tabLabel('Profile'));
    await tester.pumpAndSettle();
    expect(tapped, AppTab.profile);
  });
}

class _ReadyWorkoutNotifier extends CurrentWorkoutNotifier {
  @override
  CurrentWorkoutStateData build() => (
        workoutId: null,
        workoutStartDateTime: null,
        workoutEndDateTime: null,
        isInProgress: false,
        exercises: [],
        currentExercise: null,
        recoveryStatus: WorkoutRecoveryStatus.ready,
        isStartingWorkout: false,
      );
}

class _SignedInNotifier extends UserAuthenticationNotifier {
  @override
  UserAuthenticationStateData build() =>
      (isSignedIn: AuthStatus.signedIn, firstName: 'Nathan');
}
