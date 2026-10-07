import 'package:flutter/material.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/widgets/app_background.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';

/// Placeholder until the workout summary screen is built. Shown after a
/// workout is saved; Done returns to Home.
class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({super.key, required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackground(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                t.spacing.screen,
                28,
                t.spacing.screen,
                t.spacing.screen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: t.spacing.gap10,
                children: [
                  Text(
                    'WORKOUT COMPLETE',
                    style: AppTypography.labelWide.copyWith(color: t.muted),
                  ),
                  Text(
                    workout.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.screenTitle,
                  ),
                  const Spacer(),
                  AppButton(
                    label: 'Done',
                    style: AppButtonStyle.inverse,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
