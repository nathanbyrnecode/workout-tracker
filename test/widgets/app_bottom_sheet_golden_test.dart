import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/widgets/app_bottom_sheet.dart';
import 'package:gym_tracker_app/widgets/app_background.dart';

import '../helpers/golden.dart';

void main() {
  goldenTest(
    'bottom sheet surface over the scrim',
    name: 'app_bottom_sheet',
    builder: (context) {
      final t = context.tokens;
      return Stack(
        fit: StackFit.expand,
        children: [
          const AppBackground(),
          ColoredBox(color: t.scrim),
          Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              type: MaterialType.transparency,
              child: AppSheet(
                children: [
                  const Text('Delete workout?',
                      style: AppTypography.cardTitleLarge),
                  Text(
                    '“Push day” will be removed from your history and the '
                    'tracker.',
                    style: AppTypography.body.copyWith(color: t.muted),
                  ),
                  Container(
                    height: t.spacing.buttonHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.card2,
                      borderRadius: BorderRadius.circular(t.radii.button),
                    ),
                    child: const Text('Cancel', style: AppTypography.button),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
