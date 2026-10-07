import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/screens/home/widgets/completed_exercise_card.dart';
import 'package:gym_tracker_app/screens/home/widgets/timer_count.dart';
import 'package:gym_tracker_app/screens/workout_detail/detail_widgets.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/date_format.dart';
import 'package:gym_tracker_app/util/number_format.dart';
import 'package:gym_tracker_app/widgets/location_chip.dart';
import 'package:gym_tracker_app/widgets/workout_form_sheet.dart';

/// A recorded workout in full: when and where it was, how long it took, its
/// totals and every set. Edit changes its name and location; Delete removes
/// it and returns to wherever this was opened from.
class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final int workoutId;

  Future<void> _edit(BuildContext context, WidgetRef ref, Workout workout) {
    return showEditWorkoutSheet(
      context: context,
      initial: (
        title: workout.title?.trim() ?? '',
        type: workout.displayLocationType,
        place: workout.place,
      ),
      onSave: (details) =>
          ref.read(pastWorkoutsProvider.notifier).updateWorkout(
                workout.id,
                title: details.title,
                locationType: details.type,
                place: details.place,
              ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    final confirmed = await showDeleteWorkoutSheet(
      context: context,
      workoutName: workout.displayTitle,
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final navigator = Navigator.of(context);
    final deleted =
        await ref.read(pastWorkoutsProvider.notifier).deleteWorkout(workout.id);
    if (deleted) {
      navigator.pop();
    } else if (context.mounted) {
      showDetailError(
        context,
        'Could not delete the workout. Check your connection and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final workout = ref
        .watch(pastWorkoutsProvider)
        .workouts
        .where((workout) => workout.id == workoutId)
        .firstOrNull;
    // Deleted from under the screen: there is nothing to show while it pops.
    if (workout == null) {
      return Scaffold(backgroundColor: t.bg);
    }

    final start = workout.startTime;
    final duration = start == null
        ? Duration.zero
        : (workout.endTime ?? start).difference(start);
    final totals = workoutTotals(workout.exercises.values);

    return DetailScaffold(
      onEdit: () => _edit(context, ref, workout),
      onDelete: () => _delete(context, ref, workout),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: t.spacing.gap8,
          children: [
            DetailTitle(workout.displayTitle),
            Row(
              spacing: t.spacing.gap8,
              children: [
                if (start != null)
                  Text(
                    '${formatShortDate(start)} · ${formatClockTime(start)}',
                    style: AppTypography.labelWide.copyWith(color: t.muted),
                  ),
                Flexible(
                  child: LocationChip(
                    type: workout.displayLocationType,
                    place: workout.place,
                  ),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatTimerDuration(duration, includeHours: true),
                style: AppTypography.timer.copyWith(
                  fontSize: 52,
                  letterSpacing: -2.6,
                ),
              ),
            ),
          ],
        ),
        Column(
          spacing: t.spacing.gap8,
          children: [
            Row(
              spacing: t.spacing.gap8,
              children: [
                Expanded(child: _StatTile('${totals.sets}', 'SETS')),
                Expanded(child: _StatTile('${totals.reps}', 'REPS')),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: t.accent,
                borderRadius: BorderRadius.circular(t.radii.button),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL VOLUME',
                    style: AppTypography.labelSmall.copyWith(
                      letterSpacing: 1.4,
                      color: t.accentInk,
                    ),
                  ),
                  Text(
                    '${formatVolume(totals.volume)} kg',
                    style: AppTypography.statLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: t.accentInk,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        for (final exercise in workout.exercises.values)
          _ExerciseCard(exercise: exercise),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radii.button),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(value, style: AppTypography.statLarge),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              letterSpacing: 1.4,
              color: t.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final duration =
        (exercise.endTime ?? exercise.startTime).difference(exercise.startTime);
    return Container(
      padding: EdgeInsets.all(t.spacing.cardPadding),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radii.card),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: t.spacing.gap8,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
            child: Row(
              spacing: t.spacing.gap12,
              children: [
                Expanded(
                  child: Text(exercise.name, style: AppTypography.cardTitle),
                ),
                Text(
                  formatElapsed(duration),
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 12,
                    color: t.muted,
                  ),
                ),
              ],
            ),
          ),
          for (final (index, set) in exercise.sets.values.indexed)
            CompactSetRow(
              number: index + 1,
              weight: set.weight,
              reps: set.reps,
            ),
        ],
      ),
    );
  }
}
