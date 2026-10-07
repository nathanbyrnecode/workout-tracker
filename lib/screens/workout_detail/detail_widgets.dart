import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/widgets/app_background.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';
import 'package:gym_tracker_app/widgets/tappable_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The frame both detail screens share: a Back and an Edit button above the
/// scrolling content, with "Delete workout" as the last item.
class DetailScaffold extends StatelessWidget {
  const DetailScaffold({
    super.key,
    required this.onEdit,
    required this.onDelete,
    required this.children,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final List<Widget> children;

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
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                t.spacing.screen,
                12,
                t.spacing.screen,
                40 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      button: true,
                      label: 'Back',
                      child: TappableCard(
                        onTap: () => Navigator.of(context).pop(),
                        radius: t.radii.iconButton,
                        child: SizedBox(
                          width: t.spacing.iconButton - 2,
                          height: t.spacing.iconButton - 2,
                          child: Icon(
                            LucideIcons.chevronLeft,
                            size: 20,
                            color: t.fg,
                          ),
                        ),
                      ),
                    ),
                    TappableCard(
                      onTap: onEdit,
                      radius: t.radii.iconButton,
                      child: Container(
                        height: t.spacing.iconButton - 2,
                        padding: const EdgeInsets.only(left: 12, right: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: t.spacing.gap6,
                          children: [
                            Icon(LucideIcons.pencil, size: 15, color: t.fg),
                            const Text('Edit', style: AppTypography.toggle),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                for (final child in children)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: child,
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: AppButton(
                    label: 'Delete workout',
                    style: AppButtonStyle.dangerSoft,
                    height: 52,
                    textStyle: AppTypography.buttonSecondary,
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A detail screen's workout title: 26px, wraps onto as many lines as needed.
class DetailTitle extends StatelessWidget {
  const DetailTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTypography.detailTitle);
  }
}

/// Tells the user a save or delete did not go through.
void showDetailError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
