import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shows that a workout is only on this device and has not reached the
/// server yet: a small cloud-off icon, with "NOT SYNCED" beside it when
/// [showLabel] is true. Screen readers hear "Not synced" either way.
class NotSyncedMarker extends StatelessWidget {
  const NotSyncedMarker({super.key, this.showLabel = false, this.size = 14});

  final bool showLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      container: true,
      label: 'Not synced',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: t.spacing.gap6,
        children: [
          Icon(LucideIcons.cloudOff, size: size, color: t.fg),
          if (showLabel)
            Text(
              'NOT SYNCED',
              style: AppTypography.labelWide.copyWith(color: t.muted),
            ),
        ],
      ),
    );
  }
}
