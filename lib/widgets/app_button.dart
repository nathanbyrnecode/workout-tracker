import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';

enum AppButtonStyle {
  /// Accent fill: the main action.
  accent,

  /// Foreground fill with background-coloured text: "Sign in with Apple",
  /// "Done".
  inverse,

  /// Card fill with a line border.
  card,

  /// Inset fill: "Cancel", "Keep going", "Edit set".
  neutral,

  /// Tinted danger fill with danger text: "Delete workout".
  dangerSoft,

  /// Solid danger fill: the confirming destructive action.
  danger,
}

/// A full-width button in one of the design's fills. With a null [onPressed]
/// it is shown at 40% opacity and ignores taps.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.accent,
    this.height,
    this.radius,
    this.textStyle = AppTypography.button,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;

  /// Defaults to the 56 of sheet and screen buttons.
  final double? height;

  /// Defaults to the button radius, 18.
  final double? radius;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (fill, foreground) = switch (style) {
      AppButtonStyle.accent => (t.accent, t.accentInk),
      AppButtonStyle.inverse => (t.fg, t.bg),
      AppButtonStyle.card => (t.card, t.fg),
      AppButtonStyle.neutral => (t.card2, t.fg),
      AppButtonStyle.dangerSoft => (t.dangerBg, t.danger),
      AppButtonStyle.danger => (t.danger, t.onDanger),
    };

    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius ?? t.radii.button),
          side: style == AppButtonStyle.card
              ? BorderSide(color: t.line)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: height ?? t.spacing.buttonHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle.copyWith(color: foreground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
