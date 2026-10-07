import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';

/// A floating action button from the row above the tab bar.
///
/// [ActionButton.primary] is the accent button ("Start workout", "Add set").
/// [ActionButton.stop] is the card-coloured button with danger text and a
/// stop square ("End workout", "End exercise").
class ActionButton extends StatelessWidget {
  const ActionButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : _stop = false;

  const ActionButton.stop({
    super.key,
    required this.label,
    required this.onPressed,
  })  : icon = null,
        _stop = true;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool _stop;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(t.radii.button);
    final foreground = _stop ? t.danger : t.accentInk;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: t.floatingShadow,
      ),
      child: Material(
        color: _stop ? t.card : t.accent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: _stop ? BorderSide(color: t.line) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: t.spacing.floatingButtonHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: _stop || icon != null ? t.spacing.gap8 : 0,
              children: [
                if (_stop)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: t.danger,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )
                else if (icon != null)
                  Icon(icon, size: 20, color: foreground),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.button.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
