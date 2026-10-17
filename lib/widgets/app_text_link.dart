import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';

/// A tappable line of text, such as "Privacy Policy" or "Forgot password?".
/// With a null [onTap] it is shown at 40% opacity and ignores taps.
class AppTextLink extends StatelessWidget {
  const AppTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.style = AppTypography.bodySmall,
    this.verticalPadding = 2,
  });

  final String label;
  final VoidCallback? onTap;

  /// Defaults to the muted text colour.
  final Color? color;
  final TextStyle style;

  /// Widens the tap target where there is room, as in sheets.
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radii.chip),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: verticalPadding,
          ),
          child: Text(label, style: style.copyWith(color: color ?? t.muted)),
        ),
      ),
    );
  }
}
