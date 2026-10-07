import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/data/workout_history.dart';
import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/screens/home/widgets/sheets/end_workout_sheet.dart';
import 'package:gym_tracker_app/screens/home/widgets/sheets/new_exercise_sheet.dart';
import 'package:gym_tracker_app/screens/home/widgets/sheets/set_sheet.dart';
import 'package:gym_tracker_app/screens/workout_summary/workout_summary_screen.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
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

  Future<void> _endWorkout(BuildContext context, WidgetRef ref) async {
    final workout = ref.read(currentWorkoutProvider);
    final startedAt = workout.workoutStartDateTime;
    if (startedAt == null) {
      return;
    }
    final navigator = Navigator.of(context);
    Workout? saved;
    await showEndWorkoutSheet(
      context: context,
      totals: workoutTotals(workout.exercises),
      startedAt: startedAt,
      // Most people train in the same kind of place as last time.
      initialType: defaultLocationType(ref.read(pastWorkoutsProvider).workouts),
      onDiscard: ref.read(currentWorkoutProvider.notifier).discardWorkout,
      onEnd: (details) async {
        final result =
            await ref.read(currentWorkoutProvider.notifier).endWorkout(
                  title: details.title,
                  locationType: details.type,
                  place: details.place,
                );
        saved = result.workout;
        return result.outcome != EndWorkoutOutcome.failed;
      },
    );
    final workoutToShow = saved;
    if (workoutToShow != null) {
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (context) => WorkoutSummaryScreen(workout: workoutToShow),
        ),
      );
    }
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
            onPressed: exerciseInProgress
                ? notifier.endExercise
                : () => _endWorkout(context, ref),
            label: exerciseInProgress ? 'End exercise' : 'End workout',
          ),
        ),
      ],
    );
  }
}
