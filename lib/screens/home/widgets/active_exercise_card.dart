import 'package:flutter/material.dart';
import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/screens/home/widgets/set_number_tile.dart';
import 'package:gym_tracker_app/screens/home/widgets/timer_count.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/number_format.dart';
import 'package:gym_tracker_app/widgets/dashed_border.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The exercise in progress: its timer and name, a rest timer that counts up
/// from the last saved set, one row per set and the running totals.
class ActiveExerciseCard extends StatelessWidget {
  const ActiveExerciseCard({
    super.key,
    required this.exercise,
    required this.onSetMenu,
  });

  final Exercise exercise;

  /// Called with a set and its number (from 1) when its ⋮ button is tapped.
  final void Function(ExerciseSet set, int number) onSetMenu;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final sets = exercise.sets.values.toList();
    final restingSince = lastSetSavedAt(sets);
    final totals = workoutTotals([exercise]);

    return Container(
      padding: EdgeInsets.all(t.spacing.cardPaddingLarge),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radii.cardLarge),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: t.spacing.gap14,
        children: [
          Row(
            spacing: t.spacing.gap10,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Row(
                      children: [
                        Text(
                          'In progress · ',
                          style: AppTypography.caption
                              .copyWith(color: t.accentText),
                        ),
                        TimerCount(
                          startTime: exercise.startTime,
                          style: AppTypography.caption
                              .copyWith(color: t.accentText),
                        ),
                      ],
                    ),
                    Text(
                      exercise.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.exerciseName,
                    ),
                  ],
                ),
              ),
              if (restingSince != null) _RestTimer(since: restingSince),
            ],
          ),
          Column(
            spacing: t.spacing.gap6,
            children: [
              for (final (index, set) in sets.indexed)
                _SetRow(
                  set: set,
                  number: index + 1,
                  onMenu: () => onSetMenu(set, index + 1),
                ),
              if (sets.isEmpty) const _NoSets(),
            ],
          ),
          if (sets.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${formatCount(totals.sets, 'set')} · '
                  '${formatCount(totals.reps, 'rep')}',
                  style: AppTypography.bodySmall.copyWith(color: t.muted),
                ),
                Text(
                  '${formatVolume(totals.volume)} kg volume',
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RestTimer extends StatelessWidget {
  const _RestTimer({required this.since});

  final DateTime since;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: 'Rest time',
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: t.card2,
          borderRadius: BorderRadius.circular(t.radii.tile),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: t.spacing.gap6,
          children: [
            Icon(LucideIcons.timer, size: 14, color: t.accentText),
            TimerCount(
              startTime: since,
              style: AppTypography.monoSmall.copyWith(
                fontSize: 14,
                color: t.accentText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.set,
    required this.number,
    required this.onMenu,
  });

  final ExerciseSet set;
  final int number;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 8, right: 6),
      decoration: BoxDecoration(
        color: t.card2,
        borderRadius: BorderRadius.circular(t.radii.setRow),
      ),
      child: Row(
        spacing: t.spacing.gap12,
        children: [
          SetNumberTile(
            number: number,
            size: 36,
            radius: t.radii.tileMedium,
            fontSize: 13,
          ),
          Expanded(
            child: ValueWithUnit(
              value: formatWeight(set.weight),
              unit: 'kg',
              valueStyle: AppTypography.setValue,
              unitStyle: AppTypography.bodySmall,
            ),
          ),
          Expanded(
            child: ValueWithUnit(
              value: '${set.reps}',
              unit: 'reps',
              valueStyle: AppTypography.setValue,
              unitStyle: AppTypography.bodySmall,
            ),
          ),
          Semantics(
            button: true,
            label: 'Set $number options',
            child: InkResponse(
              onTap: onMenu,
              radius: 20,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  LucideIcons.ellipsisVertical,
                  size: 18,
                  color: t.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSets extends StatelessWidget {
  const _NoSets();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DashedBorder(
      color: t.line,
      borderRadius: t.radii.setRow,
      child: SizedBox(
        height: 56,
        child: Center(
          child: Text(
            'No sets added yet',
            style: AppTypography.bodyMedium.copyWith(color: t.muted),
          ),
        ),
      ),
    );
  }
}
