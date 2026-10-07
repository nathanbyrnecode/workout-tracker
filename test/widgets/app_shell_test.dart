import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/main_bottom_navigation.dart';
import 'package:gym_tracker_app/screens/home/home_screen.dart';
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
    expect(find.byType(HomeScreen), findsOneWidget);
    // Home supplies the floating actions; the other tabs have none.
    expect(find.text('Start workout'), findsOneWidget);

    await tester.tap(tabLabel('Tracker'));
    await tester.pumpAndSettle();
    expect(find.byType(TrackerScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('Start workout'), findsNothing);

    await tester.tap(tabLabel('Notifications'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);

    await tester.tap(tabLabel('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tester.tap(tabLabel('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('a pressed tab opens only when the finger lifts', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentWorkoutProvider.overrideWith(() => _ReadyWorkoutNotifier()),
          userAuthenticationProvider.overrideWith(() => _SignedInNotifier()),
        ],
        child: app(const MainBottomNavigation()),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(tabLabel('Tracker')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(TrackerScreen), findsNothing);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(TrackerScreen), findsOneWidget);
  });

  testWidgets('the tab bar keeps its state when the floating actions go',
      (tester) async {
    // If the bar were rebuilt from scratch its bubble would jump to the new
    // tab instead of sliding there.
    Widget shell({required bool actions}) => app(
          AppShell(
            selected: actions ? AppTab.home : AppTab.tracker,
            onSelected: (_) {},
            floatingActions: actions ? const Text('Start workout') : null,
            child: const SizedBox.expand(),
          ),
        );

    await tester.pumpWidget(shell(actions: true));
    final before = tester.element(find.byType(AppTabBar));
    await tester.pumpWidget(shell(actions: false));
    await tester.pumpAndSettle();
    expect(tester.element(find.byType(AppTabBar)), same(before));
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

  Future<double> barGap(
    WidgetTester tester, {
    required TargetPlatform platform,
    required double inset,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(Brightness.dark).copyWith(platform: platform),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          viewPadding: EdgeInsets.only(bottom: inset),
        ),
        child: AppShell(
          selected: AppTab.home,
          onSelected: (_) {},
          child: const SizedBox(),
        ),
      ),
    ));
    return 844 - tester.getRect(find.byType(AppTabBar)).bottom;
  }

  testWidgets('on an iPhone the bar stays 26 above the bottom edge',
      (tester) async {
    // 34 is the home indicator inset.
    expect(await barGap(tester, platform: TargetPlatform.iOS, inset: 34), 26);
  });

  testWidgets('on Android the bar clears a tall navigation bar',
      (tester) async {
    // Gesture navigation fits inside the design gap; buttons do not.
    expect(
        await barGap(tester, platform: TargetPlatform.android, inset: 16), 26);
    expect(
        await barGap(tester, platform: TargetPlatform.android, inset: 48), 56);
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
