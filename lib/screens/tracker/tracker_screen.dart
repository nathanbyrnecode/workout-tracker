import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';

/// Placeholder until the Tracker screen is built.
class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(t.spacing.screen, 18, t.spacing.screen, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tracker', style: AppTypography.screenTitle),
            SizedBox(height: t.spacing.gap12),
            Text(
              'Coming soon',
              style: AppTypography.body.copyWith(color: t.muted),
            ),
          ],
        ),
      ),
    );
  }
}
