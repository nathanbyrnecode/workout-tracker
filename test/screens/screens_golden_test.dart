import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/place_search/place_search_service.dart';
import 'package:gym_tracker_app/data/tracker_stats.dart';
import 'package:gym_tracker_app/models/app_notification.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/screens/home/home_screen.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_action_area/workout_action_area.dart';
import 'package:gym_tracker_app/screens/notifications/notifications_screen.dart';
import 'package:gym_tracker_app/screens/profile/profile_screen.dart';
import 'package:gym_tracker_app/screens/tracker/tracker_screen.dart';
import 'package:gym_tracker_app/screens/tracker/widgets/tracker_grid.dart';
import 'package:gym_tracker_app/screens/welcome/welcome_screen.dart';
import 'package:gym_tracker_app/screens/workout_detail/manual_workout_detail_screen.dart';
import 'package:gym_tracker_app/screens/workout_detail/workout_detail_screen.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_tab_state.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/manual_workouts_state.dart';
import 'package:gym_tracker_app/state/notifications_state.dart'
    show notificationsProvider;
import 'package:gym_tracker_app/state/notifications_state.dart'
    as notifications_state;
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/widgets/app_shell.dart';
import 'package:gym_tracker_app/widgets/app_tab_bar.dart';

import '../helpers/demo.dart';
import '../helpers/fakes.dart';
import '../helpers/golden.dart';

class _PreviousTab extends CurrentTabNotifier {
  @override
  CurrentTabStateData build() => (currentTab: TabItem.previousWorkouts);
}

final _notifications = [
  AppNotification(
    id: 'a',
    title: 'Time to train',
    body: "You haven't logged a workout in 3 days.",
    time: DateTime(2026, 10, 6, 9),
  ),
  AppNotification(
    id: 'b',
    title: 'Workout saved',
    body: '03/10/26 · 1 exercise · 2 sets · 20 reps',
    time: DateTime(2026, 10, 2, 18),
    read: true,
  ),
  AppNotification(
    id: 'c',
    title: 'Welcome aboard',
    body: 'Start your first workout from the Home tab.',
    time: DateTime(2026, 8, 24, 12),
    read: true,
  ),
];

// The design's workout in progress: Bench press done, Incline DB press active.
final _workoutStart = demoNow.subtract(const Duration(minutes: 2, seconds: 27));

FakeWorkoutNotifier _liveWorkout({bool activeExercise = true}) =>
    FakeWorkoutNotifier(
      startedAt: _workoutStart,
      exercises: [
        Exercise(
          'Bench press',
          {
            1: ExerciseSet(60, 8, 1),
            2: ExerciseSet(65, 6, 2),
            3: ExerciseSet(70, 6, 3),
          },
          1,
          _workoutStart,
        )..setEndTime(
            _workoutStart.add(const Duration(minutes: 1, seconds: 18))),
      ],
      currentExercise: activeExercise
          ? Exercise(
              'Incline DB press',
              {
                4: ExerciseSet(22, 10, 4,
                    savedAt: demoNow.subtract(const Duration(seconds: 50))),
                5: ExerciseSet(24, 8, 5,
                    savedAt: demoNow.subtract(const Duration(seconds: 38))),
              },
              2,
              demoNow.subtract(const Duration(seconds: 55)),
            )
          : null,
    );

/// A screen inside the shell, with every provider it could read faked.
void screenGolden(
  String description, {
  required String name,
  required AppTab tab,
  required Widget Function() screen,
  FakeWorkoutNotifier Function()? workout,
  List<AppNotification> notifications = const [],
  bool emptyHistory = false,
  bool previousTab = false,
  bool? hasUnread,
  bool placeSearch = false,
  Future<void> Function(WidgetTester tester)? setUp,
}) {
  goldenTest(
    description,
    name: name,
    wrap: (child) => ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => demoNow),
        currentWorkoutProvider.overrideWith(workout ?? FakeWorkoutNotifier.new),
        userAuthenticationProvider.overrideWith(FakeAuthNotifier.new),
        pastWorkoutsProvider.overrideWith(
          () => FakePastWorkoutsNotifier(emptyHistory ? [] : demoHistory()),
        ),
        manualWorkoutsProvider.overrideWith(
          () => FakeManualWorkoutsNotifier(
            emptyHistory ? [] : demoManualWorkouts(),
          ),
        ),
        notificationsProvider
            .overrideWith(() => FakeNotificationsNotifier(notifications)),
        if (previousTab) currentTabProvider.overrideWith(_PreviousTab.new),
        if (placeSearch)
          placeSearchServiceProvider
              .overrideWithValue(FakePlaceSearchService()),
      ],
      child: child,
    ),
    setUp: (tester) async {
      await setUp?.call(tester);
      await tester.pumpAndSettle();
    },
    builder: (context) => Consumer(
      builder: (context, ref, child) => AppShell(
        selected: tab,
        onSelected: (_) {},
        // The design's screenshots show the bell's dot, so most goldens do
        // too. The Notifications goldens take it from the provider, as the
        // app does, to show that opening the tab clears it.
        hasUnread: hasUnread ??
            notifications_state.hasUnread(ref.watch(notificationsProvider)),
        floatingActions: tab == AppTab.home ? const WorkoutActionArea() : null,
        child: screen(),
      ),
    ),
  );
}

/// A detail screen as pushed over the shell, with the demo data behind it.
void detailGolden(
  String description, {
  required String name,
  required Widget Function() screen,
  Future<void> Function(WidgetTester tester)? setUp,
}) {
  goldenTest(
    description,
    name: name,
    wrap: (child) => ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => demoNow),
        pastWorkoutsProvider
            .overrideWith(() => FakePastWorkoutsNotifier(demoHistory())),
        manualWorkoutsProvider.overrideWith(
          () => FakeManualWorkoutsNotifier(demoManualWorkouts()),
        ),
        placeSearchServiceProvider.overrideWithValue(FakePlaceSearchService()),
      ],
      child: child,
    ),
    setUp: (tester) async {
      await setUp?.call(tester);
      await tester.pumpAndSettle();
    },
    builder: (context) => screen(),
  );
}

Widget _home() => HomeScreen(
      onOpenNotifications: () {},
      onOpenWorkout: (_) {},
      hasUnread: true,
    );

Widget _tracker() => TrackerScreen(
      onLogWorkout: (_) {},
      onOpenWorkout: (_) {},
      onOpenManualWorkout: (_) {},
      onOpenLiveWorkout: () {},
    );

Future<void> _tapDay(WidgetTester tester, DateTime day) async {
  for (var week = 0; week < trackerWeeks; week++) {
    for (var weekday = 0; weekday < 7; weekday++) {
      if (trackerGridDay(demoNow, week, weekday) == day) {
        await tester.tapAt(
          tester.getTopLeft(find.byType(TrackerGrid)) +
              TrackerGrid.cellRect(week, weekday).center,
        );
        return;
      }
    }
  }
}

void main() {
  // ── Sheets (fit-epic.6) ────────────────────────────────────────────────
  screenGolden(
    'new exercise sheet',
    name: 'sheet_new_exercise',
    hasUnread: true,
    tab: AppTab.home,
    screen: _home,
    workout: () => _liveWorkout(activeExercise: false),
    setUp: (tester) => tester.tap(find.text('Add exercise')),
  );

  screenGolden(
    'set sheet when adding',
    name: 'sheet_set_add',
    hasUnread: true,
    tab: AppTab.home,
    screen: _home,
    workout: _liveWorkout,
    setUp: (tester) => tester.tap(find.text('Add set')),
  );

  screenGolden(
    'set sheet when editing',
    name: 'sheet_set_edit',
    hasUnread: true,
    tab: AppTab.home,
    screen: _home,
    workout: _liveWorkout,
    setUp: (tester) async {
      await tester.tap(find.bySemanticsLabel(RegExp('Set 2 options')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit set'));
    },
  );

  screenGolden(
    'set menu sheet',
    name: 'sheet_set_menu',
    hasUnread: true,
    tab: AppTab.home,
    screen: _home,
    workout: _liveWorkout,
    setUp: (tester) =>
        tester.tap(find.bySemanticsLabel(RegExp('Set 2 options'))),
  );

  // ── End workout (fit-epic.7) ───────────────────────────────────────────
  // The Place part needs a place search, which the fake stands in for.
  screenGolden(
    'end workout sheet, empty',
    name: 'sheet_end_workout',
    hasUnread: true,
    tab: AppTab.home,
    screen: _home,
    placeSearch: true,
    workout: () => _liveWorkout(activeExercise: false),
    setUp: (tester) => tester.tap(find.text('End workout')),
  );

  screenGolden(
    'end workout sheet with the place search open',
    name: 'sheet_end_workout_search',
    hasUnread: true,
    tab: AppTab.home,
    screen: _home,
    placeSearch: true,
    workout: () => _liveWorkout(activeExercise: false),
    setUp: (tester) async {
      await tester.tap(find.text('End workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search for a location'));
    },
  );

  screenGolden(
    'end workout sheet, filled in',
    name: 'sheet_end_workout_filled',
    hasUnread: true,
    tab: AppTab.home,
    screen: _home,
    placeSearch: true,
    workout: () => _liveWorkout(activeExercise: false),
    setUp: (tester) async {
      await tester.tap(find.text('End workout'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Push day');
      await tester.tap(find.text('Search for a location'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PureGym Manchester Piccadilly'));
    },
  );

  screenGolden(
    'end workout sheet as the app ships, with no place search',
    name: 'sheet_end_workout_no_places',
    hasUnread: true,
    tab: AppTab.home,
    screen: _home,
    workout: () => _liveWorkout(activeExercise: false),
    setUp: (tester) => tester.tap(find.text('End workout')),
  );

  // ── Workout detail (fit-epic.13) ───────────────────────────────────────
  detailGolden(
    'recorded workout detail',
    name: 'detail',
    screen: () => const WorkoutDetailScreen(workoutId: 1),
  );

  detailGolden(
    'manual workout detail',
    name: 'manual_detail',
    screen: () => const ManualWorkoutDetailScreen(workoutId: 1),
  );

  detailGolden(
    'edit workout sheet',
    name: 'sheet_edit_workout',
    screen: () => const WorkoutDetailScreen(workoutId: 1),
    setUp: (tester) => tester.tap(find.text('Edit')),
  );

  detailGolden(
    'delete workout sheet',
    name: 'sheet_delete_workout',
    screen: () => const WorkoutDetailScreen(workoutId: 1),
    setUp: (tester) async {
      await tester.scrollUntilVisible(find.text('Delete workout'), 200);
      await tester.tap(find.text('Delete workout'));
    },
  );

  // ── Home, Previous tab (fit-epic.10) ───────────────────────────────────
  screenGolden(
    'previous tab at rest',
    name: 'home_previous',
    hasUnread: true,
    tab: AppTab.home,
    screen: _home,
    previousTab: true,
    workout: () => FakeWorkoutNotifier(startedAt: demoNow),
  );

  screenGolden(
    'previous tab scrolled, with the headers stuck and filled',
    name: 'home_previous_scrolled',
    hasUnread: true,
    tab: AppTab.home,
    screen: _home,
    previousTab: true,
    workout: () => FakeWorkoutNotifier(startedAt: demoNow),
    setUp: (tester) =>
        tester.drag(find.byType(CustomScrollView), const Offset(0, -900)),
  );

  screenGolden(
    'previous tab with no history',
    name: 'home_previous_empty',
    hasUnread: true,
    tab: AppTab.home,
    screen: _home,
    previousTab: true,
    emptyHistory: true,
  );

  // ── Tracker (fit-epic.11) ──────────────────────────────────────────────
  screenGolden(
    'tracker on today, with a recorded workout',
    name: 'tracker',
    hasUnread: true,
    tab: AppTab.tracker,
    screen: _tracker,
  );

  screenGolden(
    'tracker on a day with manual entries',
    name: 'tracker_manual_day',
    hasUnread: true,
    tab: AppTab.tracker,
    screen: _tracker,
    setUp: (tester) => _tapDay(tester, DateTime(2026, 10, 4)),
  );

  screenGolden(
    'tracker on a day with nothing logged',
    name: 'tracker_empty_day',
    hasUnread: true,
    tab: AppTab.tracker,
    screen: _tracker,
    setUp: (tester) => _tapDay(tester, DateTime(2026, 10, 1)),
  );

  screenGolden(
    'tracker with a workout in progress today',
    name: 'tracker_live',
    hasUnread: true,
    tab: AppTab.tracker,
    screen: _tracker,
    workout: _liveWorkout,
  );

  // ── Notifications (fit-epic.14) ────────────────────────────────────────
  screenGolden(
    'notifications with one unread',
    name: 'notifications_unread',
    tab: AppTab.notifications,
    screen: () => const NotificationsScreen(),
    notifications: _notifications,
  );

  screenGolden(
    'notifications all read',
    name: 'notifications_read',
    tab: AppTab.notifications,
    screen: () => const NotificationsScreen(),
    notifications: [for (final n in _notifications) n.asRead()],
  );

  screenGolden(
    'notifications empty, as the app ships',
    name: 'notifications_empty',
    tab: AppTab.notifications,
    screen: () => const NotificationsScreen(),
  );

  // ── Profile (fit-epic.15) ──────────────────────────────────────────────
  screenGolden(
    'profile',
    name: 'profile',
    hasUnread: true,
    tab: AppTab.profile,
    screen: () => const ProfileScreen(),
  );

  screenGolden(
    'delete account sheet',
    name: 'sheet_delete_account',
    hasUnread: true,
    tab: AppTab.profile,
    screen: () => const ProfileScreen(),
    setUp: (tester) => tester.tap(find.text('Delete account')),
  );

  // ── Welcome (fit-epic.16) ──────────────────────────────────────────────
  // Rendered as on iOS, where both sign-in buttons show.
  goldenTest(
    'welcome',
    name: 'welcome',
    wrap: (child) => ProviderScope(
      overrides: [
        userAuthenticationProvider.overrideWith(
          () => FakeAuthNotifier(null, AuthStatus.signedOut),
        ),
      ],
      child: child,
    ),
    builder: (context) => Theme(
      data: Theme.of(context).copyWith(platform: TargetPlatform.iOS),
      child: const WelcomeScreen(),
    ),
  );
}
