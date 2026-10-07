import 'package:flutter/material.dart';
import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/screens/home/widgets/set_number_tile.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/number_format.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A finished exercise. Collapsed it shows the name and totals; tapping it
/// opens its sets in place with the top set and average weight underneath.
class CompletedExerciseCard extends StatelessWidget {
  const CompletedExerciseCard({
    super.key,
    required this.exercise,
    required this.open,
    required this.onTap,
  });

  final Exercise exercise;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(t.radii.card);
    final sets = exercise.sets.values.toList();
    final totals = workoutTotals([exercise]);
    final duration =
        (exercise.endTime ?? exercise.startTime).difference(exercise.startTime);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: radius,
        border: Border.all(color: open ? t.accentBorder : t.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              expanded: open,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Row(
                    spacing: t.spacing.gap14,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: t.card2,
                          borderRadius: BorderRadius.circular(t.radii.tile),
                        ),
                        child: Icon(
                          LucideIcons.check,
                          size: 18,
                          color: t.accentText,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 3,
                          children: [
                            Text(
                              exercise.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.cardTitle,
                            ),
                            Text(
                              '${formatCount(totals.sets, 'set')} · '
                              '${formatCount(totals.reps, 'rep')} · '
                              '${formatElapsed(duration)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall
                                  .copyWith(color: t.muted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatVolume(totals.volume),
                            style: AppTypography.stat.copyWith(fontSize: 17),
                          ),
                          Text(
                            'kg vol',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: t.muted,
                            ),
                          ),
                        ],
                      ),
                      AnimatedRotation(
                        turns: open ? 0.25 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: t.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: t.spacing.gap6,
                  children: [
                    for (final (index, set) in sets.indexed)
                      CompactSetRow(
                        number: index + 1,
                        weight: set.weight,
                        reps: set.reps,
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
                      child: DefaultTextStyle.merge(
                        style: AppTypography.footnote.copyWith(color: t.muted),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('TOP SET ${_topSetLabel(exercise)}'),
                            Text(
                              'AVG ${formatWeight(averageWeight(sets))} KG',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _topSetLabel(Exercise exercise) {
    final top = topSet(exercise.sets.values);
    return top == null ? '—' : '${formatWeight(top.weight)} KG × ${top.reps}';
  }
}

/// A 44-tall set row: number, weight, reps and the set's volume. Used in the
/// open completed exercise and on the workout detail screen.
class CompactSetRow extends StatelessWidget {
  const CompactSetRow({
    super.key,
    required this.number,
    required this.weight,
    required this.reps,
    this.mutedUnits = true,
  });

  final int number;
  final double weight;
  final int reps;

  /// Small grey "kg" and "reps", as in the open completed exercise. The
  /// detail screen writes them in the same style as the numbers.
  final bool mutedUnits;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final unitStyle = mutedUnits
        ? AppTypography.caption.copyWith(fontWeight: FontWeight.w500)
        : AppTypography.setValueSmall;
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 6, right: 12),
      decoration: BoxDecoration(
        color: t.card2,
        borderRadius: BorderRadius.circular(t.radii.rowSmall),
      ),
      child: Row(
        spacing: t.spacing.gap12,
        children: [
          SetNumberTile(
            number: number,
            size: 30,
            radius: t.radii.tileSmall,
            fontSize: 12,
          ),
          Expanded(
            child: ValueWithUnit(
              value: formatWeight(weight),
              unit: 'kg',
              valueStyle: AppTypography.setValueSmall,
              unitStyle: unitStyle,
              mutedUnit: mutedUnits,
            ),
          ),
          Expanded(
            child: ValueWithUnit(
              value: '$reps',
              unit: 'reps',
              valueStyle: AppTypography.setValueSmall,
              unitStyle: unitStyle,
              mutedUnit: mutedUnits,
            ),
          ),
          Text(
            formatVolume(weight * reps),
            style: AppTypography.monoSmall.copyWith(color: t.muted),
          ),
        ],
      ),
    );
  }
}
