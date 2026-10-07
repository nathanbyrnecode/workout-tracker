import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/screens/home/home_screen.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_header.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_screen/previous_workouts_area.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_action_area/workout_action_area.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/golden.dart';

final morning = DateTime(2026, 10, 7, 9, 41);

Future<void> pumpHome(
  WidgetTester tester, {
  required FakeWorkoutNotifier workout,
  String? firstName = 'Nathan',
  DateTime Function()? now,
  VoidCallback? onOpenNotifications,
}) async {
  // Real font metrics: the default test font is much wider than Geist.
  await loadAppFonts();
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentWorkoutProvider.overrideWith(() => workout),
        userAuthenticationProvider
            .overrideWith(() => FakeAuthNotifier(firstName)),
        pastWorkoutsProvider.overrideWith(FakePastWorkoutsNotifier.new),
        clockProvider.overrideWithValue(now ?? () => morning),
      ],
      child: MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: Scaffold(
          body: Stack(
            children: [
              HomeScreen(
                  onOpenWorkout: (_) {},
                  onOpenNotifications: onOpenNotifications ?? () {}),
              const Positioned(
                left: 20,
                right: 20,
                bottom: 106,
                child: WorkoutActionArea(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('idle: inactive pill, zero timer, prompt and Start workout',
      (tester) async {
    final workout = FakeWorkoutNotifier();
    await pumpHome(tester, workout: workout);

    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Nathan'), findsOneWidget);
    expect(find.text('N'), findsOneWidget);
    expect(find.text('INACTIVE'), findsOneWidget);
    expect(find.text('00:00:00'), findsOneWidget);
    expect(find.textContaining('KG VOL'), findsNothing);
    expect(find.text('Get started by starting a workout!'), findsOneWidget);

    await tester.tap(find.text('Start workout'));
    expect(workout.starts, 1);
  });

  testWidgets('workout with no exercises: active pill, totals, both actions',
      (tester) async {
    final workout = FakeWorkoutNotifier(
      startedAt: morning.subtract(const Duration(minutes: 2, seconds: 27)),
    );
    await pumpHome(tester, workout: workout);

    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('00:02:27'), findsOneWidget);
    expect(find.text('0 EX'), findsOneWidget);
    expect(find.text('0 SETS'), findsOneWidget);
    expect(find.text('0 KG VOL'), findsOneWidget);
    expect(
      find.text('No exercises have been added to this workout yet'),
      findsOneWidget,
    );
    expect(find.text('Add exercise'), findsOneWidget);
    expect(find.text('Start workout'), findsNothing);

    await tester.tap(find.text('End workout'));
    expect(workout.endedWorkouts, 1);
  });

  testWidgets('totals include the active exercise as well as finished ones',
      (tester) async {
    final start = morning.subtract(const Duration(minutes: 10));
    final done = Exercise(
      'Bench press',
      {1: ExerciseSet(60, 8, 1), 2: ExerciseSet(65, 6, 2)},
      1,
      start,
    )..setEndTime(start.add(const Duration(minutes: 3)));
    final active = Exercise('Incline', {3: ExerciseSet(22.5, 10, 3)}, 2, start);
    final workout = FakeWorkoutNotifier(
      startedAt: start,
      exercises: [done],
      currentExercise: active,
    );
    await pumpHome(tester, workout: workout);

    expect(find.text('2 EX'), findsOneWidget);
    expect(find.text('3 SETS'), findsOneWidget);
    expect(find.text('1,095 KG VOL'), findsOneWidget);
    expect(find.text('Add set'), findsOneWidget);

    await tester.tap(find.text('End exercise'));
    expect(workout.endedExercises, 1);
  });

  testWidgets('the timer ticks every second', (tester) async {
    var now = morning;
    await pumpHome(
      tester,
      workout: FakeWorkoutNotifier(
        startedAt: morning.subtract(const Duration(seconds: 58)),
      ),
      now: () => now,
    );
    expect(find.text('00:00:58'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:00:59'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01:00'), findsOneWidget);

    // An hour later it has not wrapped.
    now = now.add(const Duration(hours: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('01:01:00'), findsOneWidget);
  });

  testWidgets('recovery in progress: progress message and no actions',
      (tester) async {
    await pumpHome(
      tester,
      workout: FakeWorkoutNotifier(
        recoveryStatus: WorkoutRecoveryStatus.loading,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Checking for an unfinished workout…'), findsOneWidget);
    expect(find.text('Start workout'), findsNothing);
    expect(find.text('INACTIVE'), findsOneWidget);
  });

  testWidgets('recovery failed: explains and offers a retry', (tester) async {
    final workout = FakeWorkoutNotifier(
      recoveryStatus: WorkoutRecoveryStatus.failed,
    );
    await pumpHome(tester, workout: workout);

    expect(
      find.textContaining('Could not check your saved workout.'),
      findsOneWidget,
    );
    expect(find.text('Start workout'), findsNothing);

    await tester.tap(find.text('Retry workout recovery'));
    expect(workout.retries, 1);
  });

  testWidgets('the toggle switches between Current and Previous',
      (tester) async {
    await pumpHome(tester, workout: FakeWorkoutNotifier());
    expect(find.byType(PreviousWorkoutsArea), findsNothing);

    await tester.tap(find.text('Previous').first);
    await tester.pumpAndSettle();
    expect(find.byType(PreviousWorkoutsArea), findsOneWidget);
    expect(find.text('Get started by starting a workout!'), findsNothing);
    // The floating actions stay on both tabs.
    expect(find.text('Start workout'), findsOneWidget);

    await tester.tap(find.text('Current').first);
    await tester.pumpAndSettle();
    expect(find.text('Get started by starting a workout!'), findsOneWidget);
  });

  testWidgets('the bell opens notifications', (tester) async {
    var opened = 0;
    await pumpHome(
      tester,
      workout: FakeWorkoutNotifier(),
      onOpenNotifications: () => opened++,
    );

    await tester.tap(find.bySemanticsLabel('Notifications'));
    expect(opened, 1);
  });

  testWidgets('with no name the greeting stands alone', (tester) async {
    await pumpHome(tester, workout: FakeWorkoutNotifier(), firstName: null);

    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Nathan'), findsNothing);
  });

  test('the greeting follows the time of day', () {
    expect(greetingFor(DateTime(2026, 10, 7, 0)), 'Good morning');
    expect(greetingFor(DateTime(2026, 10, 7, 11, 59)), 'Good morning');
    expect(greetingFor(DateTime(2026, 10, 7, 12)), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 10, 7, 17, 59)), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 10, 7, 18)), 'Good evening');
    expect(greetingFor(DateTime(2026, 10, 7, 23, 59)), 'Good evening');
  });
}
