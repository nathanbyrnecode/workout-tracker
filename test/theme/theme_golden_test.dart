import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';

import '../helpers/golden.dart';

/// A reference sheet of the tokens and type styles. It doubles as the example
/// for the golden harness: copy this file's shape for screen goldens.
void main() {
  goldenTest(
    'theme reference sheet',
    name: 'theme_reference',
    builder: (context) => const _ThemeReference(),
  );
}

class _ThemeReference extends StatelessWidget {
  const _ThemeReference();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final swatches = <(String, Color)>[
      ('bg', t.bg),
      ('card', t.card),
      ('card2', t.card2),
      ('fg', t.fg),
      ('muted', t.muted),
      ('accent', t.accent),
      ('accentText', t.accentText),
      ('danger', t.danger),
      ('dangerBg', t.dangerBg),
      ('sheet', t.sheet),
      ('heat 0', t.heat(0)),
      ('heat 1', t.heat(1)),
      ('heat 2', t.heat(2)),
      ('heat 3', t.heat(3)),
      ('glass', t.glass),
      ('bubble', t.glassBubble),
    ];

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(t.spacing.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ACTIVITY',
              style: AppTypography.label.copyWith(color: t.muted),
            ),
            const Text('Tracker', style: AppTypography.screenTitle),
            SizedBox(height: t.spacing.gap12),
            const Text('00:02:27', style: AppTypography.timer),
            SizedBox(height: t.spacing.gap12),
            const Text('Incline DB press', style: AppTypography.cardTitleLarge),
            const Text('Bench press', style: AppTypography.cardTitle),
            Text(
              '3 sets · 20 reps · 1m 18s',
              style: AppTypography.bodySmall.copyWith(color: t.muted),
            ),
            Row(
              children: [
                const Text('1,320', style: AppTypography.statLarge),
                SizedBox(width: t.spacing.gap12),
                const Text('173', style: AppTypography.stat),
                SizedBox(width: t.spacing.gap12),
                Text(
                  'IN PROGRESS',
                  style: AppTypography.labelSmall.copyWith(color: t.accentText),
                ),
              ],
            ),
            SizedBox(height: t.spacing.gap14),
            Container(
              height: t.spacing.buttonHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.accent,
                borderRadius: BorderRadius.circular(t.radii.button),
                boxShadow: t.floatingShadow,
              ),
              child: Text(
                'Start workout',
                style: AppTypography.button.copyWith(color: t.accentInk),
              ),
            ),
            SizedBox(height: t.spacing.gap8),
            Container(
              height: t.spacing.buttonHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.dangerBg,
                borderRadius: BorderRadius.circular(t.radii.button),
              ),
              child: Text(
                'Delete workout',
                style: AppTypography.buttonSecondary.copyWith(color: t.danger),
              ),
            ),
            SizedBox(height: t.spacing.gap18),
            Wrap(
              spacing: t.spacing.gap8,
              runSpacing: t.spacing.gap8,
              children: [
                for (final (name, colour) in swatches)
                  SizedBox(
                    width: 81,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: colour,
                            borderRadius:
                                BorderRadius.circular(t.radii.iconButton),
                            border: Border.all(color: t.line),
                          ),
                        ),
                        SizedBox(height: t.spacing.gap6),
                        Text(
                          name,
                          style: AppTypography.labelSmall
                              .copyWith(color: t.muted, letterSpacing: 0),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
