import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
