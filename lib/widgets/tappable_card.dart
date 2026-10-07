import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';

/// A card-coloured surface with the 1px line border that responds to taps.
///
/// The border takes up space, as a CSS border does, so [child] is inset by
/// it. (A `Material` with a bordered shape draws its border over the content
/// instead, which makes the card 2px smaller than the design.)
class TappableCard extends StatelessWidget {
  const TappableCard({
    super.key,
    required this.onTap,
    required this.child,
    this.radius,
  });

  final VoidCallback? onTap;
  final Widget child;

  /// Defaults to the card radius, 20.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = this.radius ?? t.radii.card;
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: t.line),
      ),
      child: Material(
        type: MaterialType.transparency,
        // Inside the border, so the ripple stays within it.
        borderRadius: BorderRadius.circular(radius - 1),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: child),
      ),
    );
  }
}
