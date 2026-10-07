import 'package:flutter/material.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/widgets/location_chip.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One entry on the selected day: a recorded workout, the workout in
/// progress or a manual entry. They share this card; a manual entry differs
/// only in its grey icon.
class TrackerEntryCard extends StatelessWidget {
  const TrackerEntryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.muted = false,
    this.locationType,
    this.place,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Grey icon, for manual entries.
  final bool muted;

  /// Null hides the location chip, as for the workout in progress.
  final LocationType? locationType;
  final Place? place;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final locationType = this.locationType;

    return Material(
      color: t.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radii.card),
        side: BorderSide(color: t.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            spacing: t.spacing.gap12,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: t.card2,
                  borderRadius: BorderRadius.circular(t.radii.tile),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: muted ? t.muted : t.accentText,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) => Row(
                        spacing: t.spacing.gap8,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.setValueSmall,
                            ),
                          ),
                          // Sized to its text, up to half the row.
                          if (locationType != null)
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth / 2,
                              ),
                              child: LocationChip(
                                type: locationType,
                                place: place,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(color: t.muted),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 16, color: t.muted),
            ],
          ),
        ),
      ),
    );
  }
}
