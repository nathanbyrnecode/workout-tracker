import 'package:flutter/material.dart';

/// Draws [shadows] around [child] but not behind it. Use it for translucent
/// surfaces such as glass, where a shadow painted underneath would show
/// through and grey the surface.
class OuterShadow extends StatelessWidget {
  const OuterShadow({
    super.key,
    required this.borderRadius,
    required this.shadows,
    required this.child,
  });

  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OuterShadowPainter(radius: borderRadius, shadows: shadows),
      child: child,
    );
  }
}

class _OuterShadowPainter extends CustomPainter {
  const _OuterShadowPainter({required this.radius, required this.shadows});

  final BorderRadius radius;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = radius.toRRect(Offset.zero & size);
    for (final shadow in shadows) {
      final reach = shadow.blurRadius * 2 + shadow.offset.distance;
      final outside = Path.combine(
        PathOperation.difference,
        Path()..addRect((Offset.zero & size).inflate(reach)),
        Path()..addRRect(shape),
      );
      canvas
        ..save()
        ..clipPath(outside)
        ..drawRRect(
          shape.shift(shadow.offset).inflate(shadow.spreadRadius),
          shadow.toPaint(),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_OuterShadowPainter oldDelegate) =>
      radius != oldDelegate.radius || shadows != oldDelegate.shadows;
}
