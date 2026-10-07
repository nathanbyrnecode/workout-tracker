import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/widgets/app_background.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Placeholder until the workout detail screens are built. It shows the
/// workout's title and a way back.
class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key, required this.title});

  final String title;

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
                14,
                t.spacing.screen,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: t.spacing.gap18,
                children: [
                  Semantics(
                    button: true,
                    label: 'Back',
                    child: Material(
                      color: t.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(t.radii.iconButton),
                        side: BorderSide(color: t.line),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: SizedBox(
                          width: t.spacing.iconButton,
                          height: t.spacing.iconButton,
                          child: Icon(
                            LucideIcons.chevronLeft,
                            size: 20,
                            color: t.fg,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(title, style: AppTypography.screenTitle),
                  Text(
                    'Workout details are coming soon.',
                    style: AppTypography.body.copyWith(color: t.muted),
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
