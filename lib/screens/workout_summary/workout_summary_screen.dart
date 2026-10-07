import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/screens/home/widgets/timer_count.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/date_format.dart';
import 'package:gym_tracker_app/util/number_format.dart';
import 'package:gym_tracker_app/widgets/app_background.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shown after a workout is saved: how long it took, its totals and how the
/// volume split across exercises. It is pushed over the shell, so there is no
/// tab bar. Done returns to Home.
class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({super.key, required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final start = workout.startTime;
    final duration = start == null
        ? Duration.zero
        : (workout.endTime ?? start).difference(start);
    final exercises = workout.exercises.values.toList();
    final totals = workoutTotals(exercises);
    final largest = exercises.fold<double>(
      0,
      (most, exercise) => max(most, setsVolume(exercise.sets.values)),
    );

    return Scaffold(
      backgroundColor: t.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackground(),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                t.spacing.screen,
                40,
                t.spacing.screen,
                40 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(t.radii.setRow),
                    ),
                    child:
                        Icon(LucideIcons.check, size: 26, color: t.accentInk),
                  ),
                ),
                SizedBox(height: t.spacing.gap22),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: t.spacing.gap6,
                  children: [
                    Text(
                      'WORKOUT COMPLETE',
                      style:
                          AppTypography.labelWide.copyWith(color: t.accentText),
                    ),
                    Text(
                      workout.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.summaryTitle,
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatTimerDuration(duration, includeHours: true),
                        style: AppTypography.timer.copyWith(
                          fontSize: 60,
                          letterSpacing: -3,
                        ),
                      ),
                    ),
                    Text(
                      [
                        if (start != null) formatShortDate(start),
                        if (start != null) formatClockTime(start),
                        workout.place?.name ??
                            workout.displayLocationType.label,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(color: t.muted),
                    ),
                  ],
                ),
                SizedBox(height: t.spacing.gap22),
                Row(
                  spacing: t.spacing.gap8,
                  children: [
                    Expanded(
                      child: _StatTile('${totals.exercises}', 'EXERCISES'),
                    ),
                    Expanded(child: _StatTile('${totals.sets}', 'SETS')),
                    Expanded(child: _StatTile('${totals.reps}', 'REPS')),
                  ],
                ),
                SizedBox(height: t.spacing.gap22),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: t.card,
                    borderRadius: BorderRadius.circular(t.radii.card),
                    border: Border.all(color: t.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: t.spacing.gap14,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'VOLUME BY EXERCISE',
                            style: AppTypography.labelSmall.copyWith(
                              letterSpacing: 1.4,
                              color: t.muted,
                            ),
                          ),
                          Text(
                            '${formatVolume(totals.volume)} kg',
                            style: AppTypography.stat.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      for (final exercise in exercises)
                        _VolumeBar(exercise: exercise, largest: largest),
                    ],
                  ),
                ),
                SizedBox(height: t.spacing.gap22),
                AppButton(
                  label: 'Done',
                  style: AppButtonStyle.inverse,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radii.button),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(value, style: AppTypography.stat.copyWith(fontSize: 24)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

/// One exercise's volume as a bar whose length is its share of the largest
/// exercise's volume.
class _VolumeBar extends StatelessWidget {
  const _VolumeBar({required this.exercise, required this.largest});

  final Exercise exercise;
  final double largest;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final volume = setsVolume(exercise.sets.values);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: t.spacing.gap6,
      children: [
        Row(
          spacing: t.spacing.gap12,
          children: [
            Expanded(
              child: Text(
                exercise.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium,
              ),
            ),
            Text(
              formatVolume(volume),
              style: AppTypography.monoSmall.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: t.muted,
              ),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(t.radii.trackerSquare),
          child: SizedBox(
            height: 8,
            child: ColoredBox(
              color: t.card2,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: volumeShare(volume, largest),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.accent,
                    borderRadius: BorderRadius.circular(t.radii.trackerSquare),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// How much of the bar an exercise fills: its volume as a share of the
/// largest, never less than 4% so that a small exercise still shows.
double volumeShare(double volume, double largest) {
  if (largest <= 0) {
    return 0.04;
  }
  return (volume / largest).clamp(0.04, 1.0);
}
