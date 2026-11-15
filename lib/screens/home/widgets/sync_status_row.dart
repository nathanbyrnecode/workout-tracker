import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/state/workout_sync_state.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/widgets/app_messenger.dart';
import 'package:gym_tracker_app/widgets/app_text_link.dart';
import 'package:gym_tracker_app/widgets/not_synced_marker.dart';

/// Under Home's header while any workout is only on this device: how many
/// are waiting and a Sync button that uploads them now. Hidden when nothing
/// is waiting. The app also syncs by itself at sign-in and when it comes
/// back to the foreground.
class SyncStatusRow extends ConsumerWidget {
  const SyncStatusRow({super.key});

  Future<void> _sync(WidgetRef ref) async {
    final messenger = ref.read(appMessengerProvider);
    final failed = await ref.read(workoutSyncProvider.notifier).syncAll();
    messenger.show(
      failed == 0
          ? 'All workouts synced'
          : "Couldn't sync ${failed == 1 ? 'a workout' : '$failed workouts'}. "
              'Try again when you have a connection.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final sync = ref.watch(workoutSyncProvider);
    final waiting =
        sync.pendingWorkouts.length + sync.pendingManualWorkouts.length;
    if (waiting == 0) {
      return const SizedBox.shrink();
    }
    final busy = sync.isSyncing || sync.uploading.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        t.spacing.screen,
        t.spacing.gap10,
        t.spacing.screen,
        0,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          t.spacing.gap14,
          t.spacing.gap10,
          t.spacing.gap6,
          t.spacing.gap10,
        ),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(t.radii.rowSmall),
          border: Border.all(color: t.line),
        ),
        child: Row(
          spacing: t.spacing.gap10,
          children: [
            const NotSyncedMarker(size: 16),
            Expanded(
              child: Text(
                waiting == 1
                    ? '1 workout not synced'
                    : '$waiting workouts not synced',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(color: t.fg),
              ),
            ),
            if (busy)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.spacing.gap10),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: t.accentText,
                  ),
                ),
              )
            else
              Semantics(
                button: true,
                child: AppTextLink(
                  label: 'Sync',
                  color: t.accentText,
                  style: AppTypography.link,
                  verticalPadding: t.spacing.gap6,
                  onTap: () => _sync(ref),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
