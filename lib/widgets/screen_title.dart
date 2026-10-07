import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';

/// A screen's title, with an optional small label above it and an optional
/// widget at the trailing edge.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, {super.key, this.label, this.trailing});

  final String title;
  final String? label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final label = this.label;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              if (label != null)
                Text(
                  label,
                  style: AppTypography.labelWide.copyWith(color: t.muted),
                ),
              Text(title, style: AppTypography.screenTitle),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
