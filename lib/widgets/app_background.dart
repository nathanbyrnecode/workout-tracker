import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';

/// The screen background with the design's two blurred glows.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ColoredBox(
      color: t.bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -140,
            top: 120,
            child: _Orb(width: 320, height: 320, color: t.orb1),
          ),
          Positioned(
            left: -120,
            bottom: -40,
            child: _Orb(width: 300, height: 260, color: t.orb2),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      // CSS blur(70px) is a Gaussian with a standard deviation of 70.
      imageFilter: ImageFilter.blur(
        sigmaX: 70,
        sigmaY: 70,
        tileMode: TileMode.decal,
      ),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.all(Radius.elliptical(width, height)),
        ),
      ),
    );
  }
}
