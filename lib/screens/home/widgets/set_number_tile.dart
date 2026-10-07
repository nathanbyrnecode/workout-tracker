import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';

/// The small square that shows a set's number at the start of a set row.
class SetNumberTile extends StatelessWidget {
  const SetNumberTile({
    super.key,
    required this.number,
    required this.size,
    required this.radius,
    required this.fontSize,
  });

  final int number;
  final double size;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        '$number',
        style: AppTypography.monoSmall.copyWith(
          fontSize: fontSize,
          color: t.muted,
        ),
      ),
    );
  }
}

/// A number with its unit beside it in smaller muted text: "60 kg", "8 reps".
class ValueWithUnit extends StatelessWidget {
  const ValueWithUnit({
    super.key,
    required this.value,
    required this.unit,
    required this.valueStyle,
    required this.unitStyle,
  });

  final String value;
  final String unit;
  final TextStyle valueStyle;
  final TextStyle unitStyle;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: value,
        style: valueStyle,
        children: [
          TextSpan(
            text: ' $unit',
            style: unitStyle.copyWith(color: context.tokens.muted),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
