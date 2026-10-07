import 'package:flutter/material.dart';
import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/screens/home/widgets/sheets/hold_to_discard_button.dart';
import 'package:gym_tracker_app/screens/home/widgets/timer_count.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/number_format.dart';
import 'package:gym_tracker_app/widgets/app_bottom_sheet.dart';
import 'package:gym_tracker_app/widgets/workout_form_sheet.dart';

/// Asks for the workout's name and location before ending it. [onEnd] ends
/// the workout and reports whether that worked; the sheet closes on success
/// and stays open with a message otherwise. Completes with true when the
/// workout was ended.
///
/// Holding the End workout button for three seconds calls [onDiscard], which
/// throws the workout away, and then closes the sheet.
Future<bool?> showEndWorkoutSheet({
  required BuildContext context,
  required WorkoutTotals totals,
  required DateTime startedAt,
  required LocationType initialType,
  required Future<bool> Function(WorkoutDetails details) onEnd,
  required Future<bool> Function() onDiscard,
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
          onConfirm: onEnd,
          confirmBuilder: (context, {required canConfirm, required confirm}) =>
              HoldToDiscardButton(
            label: 'End workout',
            enabled: canConfirm,
            onTap: confirm,
            onDiscard: () async {
              final navigator = Navigator.of(context);
              if (await onDiscard()) {
                navigator.pop(false);
              }
            },
          ),
        ),
      ];
    },
  );
}
