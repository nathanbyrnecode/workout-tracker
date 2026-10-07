import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_screen/current_workout_area.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_action_area/workout_action_area.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/theme/app_theme.dart';

void main() {
  testWidgets('shows recovery progress and prevents a new workout',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentWorkoutProvider.overrideWith(() => _RecoveryNotifier())
        ],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          home: Scaffold(
              body: Column(children: [
            Expanded(child: CurrentWorkoutArea()),
            WorkoutActionArea(),
          ])),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Checking for an unfinished workout…'), findsOneWidget);
    expect(find.text('Start workout'), findsNothing);
  });

  testWidgets('failed recovery offers retry before enabling workout actions',
      (tester) async {
    final notifier = _RecoveryNotifier(failed: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentWorkoutProvider.overrideWith(() => notifier)],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          home: Scaffold(
              body: Column(children: [
            Expanded(child: CurrentWorkoutArea()),
            WorkoutActionArea(),
          ])),
        ),
      ),
    );
    expect(find.textContaining('Could not check your saved workout.'),
        findsOneWidget);
    expect(find.text('Start workout'), findsNothing);
    await tester.tap(find.text('Retry workout recovery'));
    await tester.pump();
    expect(notifier.retries, 1);
    expect(find.text('Start workout'), findsOneWidget);
    expect(find.textContaining('Get started by starting a'), findsOneWidget);
  });

  testWidgets('overlays a remove menu without changing set card dimensions',
      (tester) async {
    var removed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: Scaffold(
          body: Center(
            child: CurrentExerciseSetCard(
              weight: '80',
              reps: '10',
              onRemove: () => removed = true,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(CurrentExerciseSetCard)),
      const Size(121, 167),
    );
    expect(find.text('80'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(
      tester.getCenter(find.text('80')).dx,
      tester.getCenter(find.byType(CurrentExerciseSetCard)).dx,
    );
    expect(
      tester.getCenter(find.text('10')).dx,
      tester.getCenter(find.byType(CurrentExerciseSetCard)).dx,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Remove set'), findsOneWidget);

    await tester.tap(find.text('Remove set'));
    await tester.pumpAndSettle();

    expect(removed, isTrue);
  });

  testWidgets('does not show set menus after an exercise is completed',
      (tester) async {
    final startTime = DateTime(2026, 8, 23, 9);
    final completedExercise = Exercise(
      'Squat',
      {1: ExerciseSet(80, 10, 1)},
      1,
      startTime,
    )..setEndTime(startTime.add(const Duration(minutes: 10)));

    final completedExerciseState = (
      workoutId: 1,
      workoutStartDateTime: startTime,
      workoutEndDateTime: null,
      isInProgress: true,
      exercises: [completedExercise],
      currentExercise: null,
      recoveryStatus: WorkoutRecoveryStatus.ready,
      isStartingWorkout: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentWorkoutProvider.overrideWithValue(completedExerciseState),
        ],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          home: Scaffold(body: CurrentWorkoutArea()),
        ),
      ),
    );

    expect(find.byIcon(Icons.more_vert), findsNothing);
  });
}

class _RecoveryNotifier extends CurrentWorkoutNotifier {
  _RecoveryNotifier({this.failed = false});
  final bool failed;
  int retries = 0;

  @override
  CurrentWorkoutStateData build() => (
        workoutId: null,
        workoutStartDateTime: null,
        workoutEndDateTime: null,
        isInProgress: false,
        exercises: [],
        currentExercise: null,
        recoveryStatus: failed
            ? WorkoutRecoveryStatus.failed
            : WorkoutRecoveryStatus.loading,
        isStartingWorkout: false,
      );

  @override
  Future<void> restoreActiveWorkout() async {
    retries++;
    state = (
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
}
