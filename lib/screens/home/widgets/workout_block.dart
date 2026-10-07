import 'package:flutter/material.dart';
import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/screens/home/widgets/timer_count.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/number_format.dart';

/// The WORKOUT label with its status pill, the large timer and, while a
/// workout is running, its totals.
class WorkoutBlock extends StatelessWidget {
  const WorkoutBlock({
    super.key,
    required this.startTime,
    required this.totals,
  });

  /// Null when no workout is in progress.
  final DateTime? startTime;
  final WorkoutTotals totals;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final startTime = this.startTime;
    final active = startTime != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(t.spacing.screen, 26, t.spacing.screen, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: t.spacing.gap8,
        children: [
          Row(
            spacing: t.spacing.gap8,
            children: [
              Text(
                'WORKOUT',
                style: AppTypography.labelWide.copyWith(color: t.muted),
              ),
              _StatusPill(active: active),
            ],
          ),
          // Scales down rather than clipping on narrow phones.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: active
                ? TimerCount(
                    startTime: startTime,
                    includeHours: true,
                    style: AppTypography.timer.copyWith(color: t.fg),
                  )
                : Text(
                    '00:00:00',
                    style: AppTypography.timer.copyWith(color: t.muted),
                  ),
          ),
          if (active)
            DefaultTextStyle.merge(
              style: AppTypography.statLine.copyWith(color: t.muted),
              child: Row(
                spacing: 16,
                children: [
                  Text('${totals.exercises} EX'),
                  Text('${totals.sets} SETS'),
                  Text('${formatVolume(totals.volume)} KG VOL'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final foreground = active ? t.accentInk : t.muted;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: active ? t.accent : t.card2,
        borderRadius: BorderRadius.circular(t.radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: t.spacing.gap6,
        children: [
          if (active)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            active ? 'ACTIVE' : 'INACTIVE',
            style: AppTypography.pill.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
