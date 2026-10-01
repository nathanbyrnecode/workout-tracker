import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_action_area/exercise_actions.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_action_area/workout_actions.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/widgets/card_button.dart';

class WorkoutActionArea extends ConsumerStatefulWidget {
  const WorkoutActionArea({super.key});

  @override
  ConsumerState<WorkoutActionArea> createState() => _WorkoutActionAreaState();
}

class _WorkoutActionAreaState extends ConsumerState<WorkoutActionArea> {
  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(currentWorkoutProvider);
    final workoutNotifier = ref.watch(currentWorkoutProvider.notifier);

    if (workoutState.recoveryStatus == WorkoutRecoveryStatus.failed) {
      return CardButton(
        onTap: () => workoutNotifier.restoreActiveWorkout(),
        icon: Icons.refresh,
        label: 'Retry workout recovery',
      );
    }
    if (workoutState.recoveryStatus != WorkoutRecoveryStatus.ready ||
        workoutState.isStartingWorkout) {
      return const SizedBox.shrink();
    }

    final bool workoutInProgress = workoutState.isInProgress;
    final bool exerciseInProgress = workoutState.currentExercise != null;

    if (workoutInProgress && !exerciseInProgress) {
      return WorkoutActions();
    } else if (workoutInProgress && exerciseInProgress) {
      return ExerciseActions();
    }
    return CardButton(
      onTap: () => workoutNotifier.startWorkout(),
      icon: Icons.fitness_center_rounded,
      label: "Start workout",
    );
  }
}
