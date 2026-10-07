import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';
import 'package:gym_tracker_app/screens/workout_detail/detail_widgets.dart';
import 'package:gym_tracker_app/state/manual_workouts_state.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/date_format.dart';
import 'package:gym_tracker_app/widgets/dashed_border.dart';
import 'package:gym_tracker_app/widgets/location_chip.dart';
import 'package:gym_tracker_app/widgets/workout_form_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A manually logged workout: its date, type and place. It has no exercises.
class ManualWorkoutDetailScreen extends ConsumerWidget {
  const ManualWorkoutDetailScreen({
    super.key,
    required this.workoutId,
    required this.onClose,
  });

  final int workoutId;

  /// Leaves the screen: Back, or after the workout is deleted.
  final VoidCallback onClose;

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ManualWorkout workout,
  ) {
    return showEditWorkoutSheet(
      context: context,
      initial: (
        title: workout.title,
        type: workout.locationType,
        place: workout.place,
      ),
      onSave: (details) =>
          ref.read(manualWorkoutsProvider.notifier).updateManualWorkout(
                workout.id,
                title: details.title,
                locationType: details.type,
                place: details.place,
              ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ManualWorkout workout,
  ) async {
    final confirmed = await showDeleteWorkoutSheet(
      context: context,
      workoutName: workout.title,
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final deleted = await ref
        .read(manualWorkoutsProvider.notifier)
        .deleteManualWorkout(workout.id);
    if (deleted) {
      onClose();
    } else if (context.mounted) {
      showDetailError(
        context,
        'Could not delete the workout. Check your connection and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final workout = ref
        .watch(manualWorkoutsProvider)
        .workouts
        .where((workout) => workout.id == workoutId)
        .firstOrNull;
    if (workout == null) {
      return const SizedBox.shrink();
    }
    final place = workout.place;
    final address = place?.address;

    return DetailScaffold(
      onBack: onClose,
      onEdit: () => _edit(context, ref, workout),
      onDelete: () => _delete(context, ref, workout),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: t.spacing.gap8,
          children: [
            DashedBorder(
              color: t.line,
              borderRadius: t.radii.chip,
              child: Container(
                // 24 inside the 1.5 border, as the design's CSS box is.
                height: 27,
                padding: const EdgeInsets.symmetric(horizontal: 10.5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: t.spacing.gap6,
                  children: [
                    Icon(LucideIcons.pencil, size: 11, color: t.muted),
                    Text(
                      'LOGGED MANUALLY',
                      style: AppTypography.labelSmall.copyWith(
                        letterSpacing: 1.4,
                        color: t.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DetailTitle(workout.title),
            Row(
              spacing: t.spacing.gap8,
              children: [
                Text(
                  formatShortDate(workout.date),
                  style: AppTypography.labelWide.copyWith(color: t.muted),
                ),
                Flexible(
                  child: LocationChip(type: workout.locationType, place: place),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(t.radii.card),
            border: Border.all(color: t.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoRow(
                label: 'DATE',
                child: Text(
                  formatLongDate(workout.date),
                  style: _infoValue,
                ),
              ),
              _InfoRow(
                label: 'TYPE',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: t.spacing.gap6,
                  children: [
                    Icon(
                      locationIcon(workout.locationType),
                      size: 16,
                      color: t.fg,
                    ),
                    Text(workout.locationType.label, style: _infoValue),
                  ],
                ),
              ),
              _InfoRow(
                label: 'PLACE',
                last: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 2,
                  children: [
                    Text(
                      place?.name ?? 'Not set',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _infoValue,
                    ),
                    if (address != null && address.isNotEmpty)
                      Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w400,
                          color: t.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            'No exercise details were recorded for this workout.',
            style: AppTypography.bodyMedium.copyWith(
              color: t.muted,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

final _infoValue = AppTypography.body.copyWith(fontWeight: FontWeight.w500);

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.child, this.last = false});

  final String label;
  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        spacing: t.spacing.gap12,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: t.muted),
          ),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: child),
          ),
        ],
      ),
    );
  }
}
