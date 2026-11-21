import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/models/cardio_timer.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/screens/home/home_screen.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_action_area/workout_action_area.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/widgets/app_shell.dart';
import 'package:gym_tracker_app/widgets/app_tab_bar.dart';

import '../../helpers/fakes.dart';
import '../../helpers/golden.dart';

// The states in the frames table of design/handoff-units-cardio/SPEC.md. The
// seed workout behind each: Bench press and Incline DB press done, then
// Treadmill run.

final _now = DateTime(2026, 10, 7, 9, 41);
final _workoutStart = _now.subtract(const Duration(minutes: 22, seconds: 20));

DateTime _ago(int seconds) => _now.subtract(Duration(seconds: seconds));

List<Exercise> _doneExercises() => [
      Exercise(
        'Bench press',
        {
          1: ExerciseSet(60, 8, 1),
          2: ExerciseSet(65, 6, 2),
          3: ExerciseSet(70, 6, 3),
        },
        1,
        _workoutStart,
      )..setEndTime(_workoutStart.add(const Duration(minutes: 1, seconds: 18))),
      Exercise(
        'Incline DB press',
        {
          4: ExerciseSet(22, 10, 4),
          5: ExerciseSet(24, 8, 5),
        },
        2,
        _workoutStart.add(const Duration(minutes: 2)),
      )..setEndTime(_workoutStart.add(const Duration(minutes: 2, seconds: 55))),
    ];

Exercise _treadmill(CardioTimer timer) => Exercise(
      'Treadmill run',
      {},
      6,
      _ago(1200),
      type: ExerciseType.cardio,
      cardio: timer,
    );

void _cardioGolden(
  String description, {
  required String name,
  required FakeWorkoutNotifier Function() workout,
  Future<void> Function(WidgetTester tester)? setUp,
}) {
  goldenTest(
    description,
    name: name,
    overrides: [
      currentWorkoutProvider.overrideWith(workout),
      userAuthenticationProvider.overrideWith(FakeAuthNotifier.new),
      pastWorkoutsProvider.overrideWith(FakePastWorkoutsNotifier.new),
      clockProvider.overrideWithValue(() => _now),
    ],
    setUp: (tester) async {
      await setUp?.call(tester);
      await tester.pumpAndSettle();
    },
    builder: (context) => AppShell(
      selected: AppTab.home,
      onSelected: (_) {},
      hasUnread: true,
      floatingActions: const WorkoutActionArea(),
      child: HomeScreen(
        onOpenWorkout: (_) {},
        onOpenNotifications: () {},
        hasUnread: true,
      ),
    ),
  );
}

FakeWorkoutNotifier _active(CardioTimer timer) => FakeWorkoutNotifier(
      startedAt: _workoutStart,
      exercises: _doneExercises(),
      currentExercise: _treadmill(timer),
    );

void main() {
  _cardioGolden(
    'new exercise sheet, Strength selected',
    name: 'cardio_1_new_exercise',
    workout: () => FakeWorkoutNotifier(
      startedAt: _workoutStart,
      exercises: _doneExercises(),
    ),
    setUp: (tester) => tester.tap(find.text('Add exercise')),
  );

  _cardioGolden(
    'new exercise sheet, Cardio selected and named',
    name: 'cardio_1b_new_exercise_cardio',
    workout: () => FakeWorkoutNotifier(
      startedAt: _workoutStart,
      exercises: _doneExercises(),
    ),
    setUp: (tester) async {
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cardio'));
      await tester.enterText(find.byType(TextField), 'Treadmill run');
    },
  );

  _cardioGolden(
    'cardio added, not started',
    name: 'cardio_2_not_started',
    workout: () => _active(const CardioTimer()),
  );

  _cardioGolden(
    'cardio running with one lap',
    name: 'cardio_3_running_timer_only',
    workout: () => _active(
      CardioTimer(laps: const [Duration.zero], runningSince: _ago(612)),
    ),
  );

  _cardioGolden(
    'cardio running with two laps',
    name: 'cardio_4_running_with_laps',
    workout: () => _active(
      CardioTimer(
        laps: const [Duration(seconds: 612), Duration.zero],
        runningSince: _ago(95),
      ),
    ),
  );

  _cardioGolden(
    'cardio paused with two laps',
    name: 'cardio_5_paused',
    workout: () => _active(
      CardioTimer(
        laps: const [Duration(seconds: 612), Duration(seconds: 540)],
        pausedAt: _ago(42),
      ),
    ),
  );

  _cardioGolden(
    'cardio finished and opened in the workout',
    name: 'cardio_6_finished',
    workout: () => FakeWorkoutNotifier(
      startedAt: _workoutStart,
      exercises: [
        ..._doneExercises(),
        _treadmill(CardioTimer.fromLapSeconds(const [612, 540]))
          ..setEndTime(_now),
      ],
    ),
    setUp: (tester) => tester.tap(find.text('Treadmill run')),
  );
}
