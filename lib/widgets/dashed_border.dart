import 'package:flutter/material.dart';

/// A rounded rectangle with a dashed outline, for the design's empty and
/// "add" placeholders.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.color,
    required this.borderRadius,
    required this.child,
    this.strokeWidth = 1.5,
  });

  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: color,
        radius: borderRadius,
        strokeWidth: strokeWidth,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  // Browsers draw dashes about three stroke widths long with matching gaps.
  double get _dash => strokeWidth * 3;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(strokeWidth / 2),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    for (final metric in outline.computeMetrics()) {
      // Fit a whole number of dash + gap pairs so the pattern closes evenly.
      final pairs = (metric.length / (_dash * 2)).round().clamp(1, 1 << 20);
      final step = metric.length / pairs;
      for (var i = 0; i < pairs; i++) {
        final start = i * step;
        canvas.drawPath(metric.extractPath(start, start + step / 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      radius != oldDelegate.radius ||
      strokeWidth != oldDelegate.strokeWidth;
}
