import 'package:flutter/material.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/number_format.dart';
import 'package:gym_tracker_app/widgets/app_bottom_sheet.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';

enum SetMenuAction { edit, delete }

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
      void choose(SetMenuAction action) =>
          Navigator.of(sheetContext).pop(action);
      return [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text('Set $number', style: AppTypography.cardTitleLarge),
            Text(
              '${formatWeight(set.weight)} kg × ${set.reps} reps',
              style: AppTypography.monoSmall.copyWith(color: t.muted),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            AppButton(
              label: 'Edit set',
              style: AppButtonStyle.neutral,
              height: 54,
              radius: t.radii.setRow,
              textStyle: AppTypography.buttonSecondary,
              onPressed: () => choose(SetMenuAction.edit),
            ),
            AppButton(
              label: 'Delete set',
              style: AppButtonStyle.dangerSoft,
              height: 54,
              radius: t.radii.setRow,
              textStyle: AppTypography.buttonSecondary,
              onPressed: () => choose(SetMenuAction.delete),
            ),
          ],
        ),
      ];
    },
  );
}
