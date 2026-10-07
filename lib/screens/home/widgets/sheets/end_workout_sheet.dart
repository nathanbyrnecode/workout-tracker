import 'package:flutter/material.dart';
import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/screens/home/widgets/timer_count.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/number_format.dart';
import 'package:gym_tracker_app/widgets/app_bottom_sheet.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';
import 'package:gym_tracker_app/widgets/workout_form_sheet.dart';

/// Asks for the workout's name and location before ending it. [onEnd] ends
/// the workout and reports whether that worked; the sheet closes on success
/// and stays open with a message otherwise. Completes with true when the
/// workout was ended.
Future<bool?> showEndWorkoutSheet({
  required BuildContext context,
  required WorkoutTotals totals,
  required DateTime startedAt,
  required LocationType initialType,
  required Future<bool> Function(WorkoutDetails details) onEnd,
}) {
  return showAppSheet<bool>(
    context: context,
    children: (sheetContext) {
      final t = sheetContext.tokens;
      final summary = AppTypography.body.copyWith(color: t.muted);
      return [
        WorkoutForm(
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              const Text('End workout?', style: AppTypography.cardTitleLarge),
              Wrap(
                children: [
                  Text(
                    '${formatCount(totals.exercises, 'exercise')} · '
                    '${formatCount(totals.sets, 'set')} · '
                    '${formatVolume(totals.volume)} kg in ',
                    style: summary,
                  ),
                  TimerCount(
                    startTime: startedAt,
                    includeHours: true,
                    style: summary,
                  ),
                ],
              ),
            ],
          ),
          initial: (title: '', type: initialType, place: null),
          namePlaceholder: 'e.g. Push day',
          confirmLabel: 'End workout',
          busyLabel: 'Saving…',
          cancelLabel: 'Keep going',
          failureMessage:
              'Could not save the workout. Check your connection and try '
              'again.',
          confirmStyle: AppButtonStyle.danger,
          confirmHeight: 62,
          onConfirm: onEnd,
        ),
      ];
    },
  );
}
