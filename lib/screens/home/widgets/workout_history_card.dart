import 'package:flutter/material.dart';
import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/date_format.dart';
import 'package:gym_tracker_app/util/number_format.dart';
import 'package:gym_tracker_app/widgets/location_chip.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A finished workout on the Previous tab: its date, where it was, and four
/// totals. The whole card is tappable.
class WorkoutHistoryCard extends StatelessWidget {
  const WorkoutHistoryCard({
    super.key,
    required this.workout,
    required this.onTap,
  });

  final Workout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final totals = workoutTotals(workout.exercises.values);
    final start = workout.startTime;

    return Material(
      color: t.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radii.card),
        side: BorderSide(color: t.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            spacing: t.spacing.gap14,
            children: [
              Row(
                children: [
                  // The date keeps its width; only the chip gives way.
                  Text(
                    start == null ? '' : formatShortDate(start),
                    style: AppTypography.cardTitle,
                  ),
                  SizedBox(width: t.spacing.gap8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: LocationChip(
                        type: workout.displayLocationType,
                        place: workout.place,
                      ),
                    ),
                  ),
                  SizedBox(width: t.spacing.gap10),
                  Icon(LucideIcons.chevronRight, size: 16, color: t.muted),
                ],
              ),
              Row(
                children: [
                  _Stat(value: '${totals.exercises}', label: 'EX'),
                  _Stat(value: '${totals.sets}', label: 'SETS'),
                  _Stat(value: '${totals.reps}', label: 'REPS'),
                  _Stat(
                    value: formatVolume(totals.volume),
                    label: 'KG',
                    accent: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.accent = false});

  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            value,
            maxLines: 1,
            softWrap: false,
            style: AppTypography.stat.copyWith(
              color: accent ? t.accentText : t.fg,
            ),
          ),
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
