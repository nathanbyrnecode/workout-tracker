import 'package:flutter/material.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/number_format.dart';
import 'package:gym_tracker_app/widgets/app_bottom_sheet.dart';

enum SetMenuAction { delete }

/// The sheet behind a set's ⋮ button. Completes with the chosen action, or
/// null if it was dismissed.
Future<SetMenuAction?> showSetMenuSheet({
  required BuildContext context,
  required ExerciseSet set,
  required int number,
}) {
  return showAppSheet<SetMenuAction>(
    context: context,
    children: (sheetContext) {
      final t = sheetContext.tokens;
      return [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text('Set $number', style: AppTypography.cardTitleLarge),
            Text(
              '${formatWeight(set.weight)} kg × ${set.reps} reps',
              style: AppTypography.body.copyWith(color: t.muted),
            ),
          ],
        ),
        Material(
          color: t.dangerBg,
          borderRadius: BorderRadius.circular(t.radii.button),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(sheetContext).pop(SetMenuAction.delete),
            child: SizedBox(
              height: t.spacing.buttonHeight,
              child: Center(
                child: Text(
                  'Delete set',
                  style: AppTypography.button.copyWith(color: t.danger),
                ),
              ),
            ),
          ),
        ),
      ];
    },
  );
}
