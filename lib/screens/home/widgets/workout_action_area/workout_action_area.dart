import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_action_area/exercise_actions.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_action_area/workout_actions.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/widgets/action_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The floating actions for Home. What it shows depends on the workout:
/// start, add exercise / end workout, or add set / end exercise.
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
      return ActionButton.primary(
        onPressed: workoutNotifier.restoreActiveWorkout,
        icon: LucideIcons.refreshCw,
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
    return ActionButton.primary(
      onPressed: workoutNotifier.startWorkout,
      icon: LucideIcons.dumbbell,
      label: 'Start workout',
    );
  }
}
