import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

final _now = DateTime(2026, 10, 7, 9, 41);

/// Home inside the shell, as in `design/workout-tracker/screens/home-*.png`.
void homeGolden(
  String description, {
  required String name,
  required FakeWorkoutNotifier Function() workout,
  Future<void> Function(WidgetTester tester)? setUp,
}) {
  goldenTest(
    description,
    name: name,
    wrap: (child) => ProviderScope(
      overrides: [
        currentWorkoutProvider.overrideWith(workout),
        userAuthenticationProvider.overrideWith(FakeAuthNotifier.new),
        pastWorkoutsProvider.overrideWith(FakePastWorkoutsNotifier.new),
        clockProvider.overrideWithValue(() => _now),
      ],
      child: child,
    ),
    // Far enough into the loading spinner's animation for it to be visible.
    setUp: (tester) async {
      await setUp?.call(tester);
      await tester.pump(const Duration(milliseconds: 600));
    },
    builder: (context) => AppShell(
      selected: AppTab.home,
      onSelected: (_) {},
      hasUnread: true,
      floatingActions: const WorkoutActionArea(),
      child: HomeScreen(onOpenNotifications: () {}, hasUnread: true),
    ),
  );
}

// The design's demo workout, 2m 27s in: a finished Bench press and an
// Incline DB press in progress.
final _workoutStart = _now.subtract(const Duration(minutes: 2, seconds: 27));

Exercise _benchPress() => Exercise(
      'Bench press',
      {
        1: ExerciseSet(60, 8, 1),
        2: ExerciseSet(65, 6, 2),
        3: ExerciseSet(70, 6, 3),
      },
      1,
      _workoutStart,
    )..setEndTime(_workoutStart.add(const Duration(minutes: 1, seconds: 18)));

Exercise _inclinePress({bool withSets = true}) => Exercise(
      'Incline DB press',
      {
        if (withSets) ...{
          4: ExerciseSet(22, 10, 4,
              savedAt: _now.subtract(const Duration(seconds: 50))),
          5: ExerciseSet(24, 8, 5,
              savedAt: _now.subtract(const Duration(seconds: 38))),
        },
      },
      2,
      _now.subtract(const Duration(seconds: 55)),
    );

void main() {
  homeGolden(
    'home with an active exercise and a finished one',
    name: 'home_active_exercise',
    workout: () => FakeWorkoutNotifier(
      startedAt: _workoutStart,
      exercises: [_benchPress()],
      currentExercise: _inclinePress(),
    ),
  );

  homeGolden(
    'home with an active exercise that has no sets',
    name: 'home_active_exercise_no_sets',
    workout: () => FakeWorkoutNotifier(
      startedAt: _workoutStart,
      currentExercise: _inclinePress(withSets: false),
    ),
  );

  homeGolden(
    'home with a finished exercise opened',
    name: 'home_completed_expanded',
    workout: () => FakeWorkoutNotifier(
      startedAt: _workoutStart,
      exercises: [_benchPress()],
      currentExercise: _inclinePress(),
    ),
    setUp: (tester) async {
      await tester.tap(find.text('Bench press'));
      await tester.pumpAndSettle();
    },
  );

  homeGolden(
    'home between exercises',
    name: 'home_active_workout',
    workout: () => FakeWorkoutNotifier(
      startedAt: _workoutStart,
      exercises: [_benchPress()],
    ),
  );

  homeGolden(
    'home with no workout',
    name: 'home_idle',
    workout: FakeWorkoutNotifier.new,
  );

  homeGolden(
    'home with a workout and no exercises',
    name: 'home_empty_workout',
    workout: () => FakeWorkoutNotifier(startedAt: _now),
  );

  homeGolden(
    'home while checking for an unfinished workout',
    name: 'home_recovery_loading',
    workout: () => FakeWorkoutNotifier(
      recoveryStatus: WorkoutRecoveryStatus.loading,
    ),
  );

  homeGolden(
    'home after the unfinished workout check failed',
    name: 'home_recovery_failed',
    workout: () => FakeWorkoutNotifier(
      recoveryStatus: WorkoutRecoveryStatus.failed,
    ),
  );
}
