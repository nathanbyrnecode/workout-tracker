import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';

/// The edge the design gives a glass surface: a 1px `glassLine` border with a
/// soft `glassHi` highlight inside the top edge and a `glassLo` shade inside
/// the bottom edge. Paints over [child] and ignores touches.
class GlassRim extends StatelessWidget {
  const GlassRim({super.key, required this.borderRadius, required this.child});

  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return CustomPaint(
      foregroundPainter: _GlassRimPainter(
        radius: borderRadius,
        line: t.glassLine,
        highlight: t.glassHi,
        shade: t.glassLo,
      ),
      child: child,
    );
  }
}

class _GlassRimPainter extends CustomPainter {
  const _GlassRimPainter({
    required this.radius,
    required this.line,
    required this.highlight,
    required this.shade,
  });

  final BorderRadius radius;
  final Color line;
  final Color highlight;
  final Color shade;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = radius.toRRect(Offset.zero & size);
    final inner = outer.deflate(1);

    // CSS `inset 0 1px 1px`: the surface's own outline, moved 1px, blurred by
    // 1px and kept only where it falls inside the surface.
    void inset(Color color, Offset offset) {
      final edge = Path.combine(
        PathOperation.difference,
        Path()..addRect((Offset.zero & size).inflate(4)),
        Path()..addRRect(inner.shift(offset)),
      );
      canvas
        ..save()
        ..clipRRect(inner)
        ..drawPath(
          edge,
          Paint()
            ..color = color
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
        )
        ..restore();
    }

    inset(highlight, const Offset(0, 1));
    inset(shade, const Offset(0, -1));

    canvas.drawRRect(
      outer.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = line,
    );
  }

  @override
  bool shouldRepaint(_GlassRimPainter oldDelegate) =>
      radius != oldDelegate.radius ||
      line != oldDelegate.line ||
      highlight != oldDelegate.highlight ||
      shade != oldDelegate.shade;
}
