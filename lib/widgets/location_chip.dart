import 'package:flutter/material.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The icon for a location type: dumbbell, house, tree or pin.
IconData locationIcon(LocationType type) => switch (type) {
      LocationType.gym => LucideIcons.dumbbell,
      LocationType.home => LucideIcons.house,
      LocationType.park => LucideIcons.treePine,
      LocationType.other => LucideIcons.mapPin,
    };

/// A small chip with the location type's icon and the place name, or the
/// type's name when no place was chosen. Long names end in an ellipsis; put
/// the chip in a `Flexible` so it can shrink.
class LocationChip extends StatelessWidget {
  const LocationChip({super.key, required this.type, this.place});

  final LocationType type;
  final Place? place;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: t.card2,
        borderRadius: BorderRadius.circular(t.radii.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(locationIcon(type), size: 11, color: t.muted),
          Flexible(
            child: Text(
              place?.name ?? type.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: t.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
