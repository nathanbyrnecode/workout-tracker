import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/screens/home/widgets/sheets/new_exercise_sheet.dart';
import 'package:gym_tracker_app/screens/home/widgets/sheets/set_sheet.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/widgets/action_button.dart';
import 'package:gym_tracker_app/widgets/floating_action_row.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The floating actions for Home. What it shows depends on the workout:
/// start, add exercise / end workout, or add set / end exercise.
class WorkoutActionArea extends ConsumerWidget {
  const WorkoutActionArea({super.key});

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final typed = await showNewExerciseSheet(context: context);
    if (typed == null) {
      return;
    }
    final workout = ref.read(currentWorkoutProvider);
    await ref.read(currentWorkoutProvider.notifier).startExercise(
          exerciseNameOrDefault(
            typed,
            existingExercises: workout.exercises.length,
          ),
        );
  }

  Future<void> _addSet(BuildContext context, WidgetRef ref) async {
    final sets = ref.read(currentWorkoutProvider).currentExercise?.sets.values;
    if (sets == null) {
      return;
    }
    final values = await showSetSheet(
      context: context,
      number: sets.length + 1,
      // A new set starts from the one before it.
      initial: sets.isEmpty
          ? defaultSetValues
          : (weight: sets.last.weight, reps: sets.last.reps),
    );
    if (values == null) {
      return;
    }
    await ref
        .read(currentWorkoutProvider.notifier)
        .addSet(weight: values.weight, reps: values.reps);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(currentWorkoutProvider);
    final notifier = ref.read(currentWorkoutProvider.notifier);

    if (workout.recoveryStatus == WorkoutRecoveryStatus.failed) {
      return ActionButton.primary(
        onPressed: notifier.restoreActiveWorkout,
        icon: LucideIcons.refreshCw,
        label: 'Retry workout recovery',
      );
    }
    if (workout.recoveryStatus != WorkoutRecoveryStatus.ready ||
        workout.isStartingWorkout) {
      return const SizedBox.shrink();
    }
    if (!workout.isInProgress) {
      return ActionButton.primary(
        onPressed: notifier.startWorkout,
        icon: LucideIcons.dumbbell,
        label: 'Start workout',
      );
    }

    final exerciseInProgress = workout.currentExercise != null;
    return FloatingActionRow(
      children: [
        Expanded(
          flex: 7,
          child: ActionButton.primary(
            onPressed: () => exerciseInProgress
                ? _addSet(context, ref)
                : _addExercise(context, ref),
            icon: LucideIcons.plus,
            label: exerciseInProgress ? 'Add set' : 'Add exercise',
          ),
        ),
        Expanded(
          flex: 5,
          child: ActionButton.stop(
            onPressed:
                exerciseInProgress ? notifier.endExercise : notifier.endWorkout,
            label: exerciseInProgress ? 'End exercise' : 'End workout',
          ),
        ),
      ],
    );
  }
}
