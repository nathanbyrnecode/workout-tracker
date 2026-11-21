import 'package:flutter/widgets.dart';

enum MediaGlyphShape { play, pause }

/// A filled play or pause symbol. Lucide only has these as outlines, and the
/// design calls for solid glyphs.
class MediaGlyph extends StatelessWidget {
  const MediaGlyph({
    super.key,
    required this.shape,
    required this.size,
    required this.color,
  });

  final MediaGlyphShape shape;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MediaGlyphPainter(shape, color)),
    );
  }
}

class _MediaGlyphPainter extends CustomPainter {
  const _MediaGlyphPainter(this.shape, this.color);

  final MediaGlyphShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 20-unit grid, then scaled.
    canvas.scale(size.width / 20);
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    switch (shape) {
      case MediaGlyphShape.play:
        final triangle = Path()
          ..moveTo(5, 3.5)
          ..lineTo(16, 10)
          ..lineTo(5, 16.5)
          ..close();
        canvas.drawPath(triangle, fill);
        // A stroke of the same colour rounds the corners.
        canvas.drawPath(
          triangle,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeJoin = StrokeJoin.round,
        );
      case MediaGlyphShape.pause:
        for (final left in const [5.0, 11.5]) {
          canvas.drawRRect(
            RRect.fromLTRBR(
              left,
              3.5,
              left + 3.5,
              16.5,
              const Radius.circular(1),
            ),
            fill,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_MediaGlyphPainter old) =>
      old.shape != shape || old.color != color;
}
