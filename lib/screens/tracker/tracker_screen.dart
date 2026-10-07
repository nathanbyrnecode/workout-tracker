import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/data/tracker_stats.dart';
import 'package:gym_tracker_app/data/workout_history.dart';
import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/screens/tracker/widgets/log_workout_sheet.dart';
import 'package:gym_tracker_app/screens/tracker/widgets/tracker_entry_card.dart';
import 'package:gym_tracker_app/screens/tracker/widgets/tracker_grid.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/manual_workouts_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/date_format.dart';
import 'package:gym_tracker_app/util/number_format.dart';
import 'package:gym_tracker_app/widgets/dashed_border.dart';
import 'package:gym_tracker_app/widgets/location_chip.dart';
import 'package:gym_tracker_app/widgets/screen_title.dart';
import 'package:gym_tracker_app/widgets/tappable_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The Tracker: streak and day counts, the 17-week grid, and what was logged
/// on the selected day.
class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({
    super.key,
    required this.onOpenWorkout,
    required this.onOpenManualWorkout,
    required this.onOpenLiveWorkout,
  });

  final ValueChanged<Workout> onOpenWorkout;
  final ValueChanged<ManualWorkout> onOpenManualWorkout;

  /// The workout in progress was tapped; it lives on Home.
  final VoidCallback onOpenLiveWorkout;

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen> {
  /// Null means today, so the selection follows the date past midnight.
  DateTime? _selected;

  /// Opens the Log workout sheet on [day]. After a workout is added, the
  /// tracker selects the day it was logged for.
  Future<void> _logWorkout(DateTime day) async {
    final today = dayOf(ref.read(clockProvider)());
    await showLogWorkoutSheet(
      context: context,
      initialDay: day,
      today: today,
      initialType: defaultLocationType(ref.read(pastWorkoutsProvider).workouts),
      onAdd: (loggedDay, details) async {
        final added =
            await ref.read(manualWorkoutsProvider.notifier).addManualWorkout(
                  date: loggedDay,
                  title: details.title,
                  locationType: details.type,
                  place: details.place,
                );
        if (added != null && mounted) {
          setState(() => _selected = loggedDay);
        }
        return added != null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final today = dayOf(ref.watch(clockProvider)());
    final live = ref.watch(currentWorkoutProvider);
    final liveExercise = live.currentExercise;
    final days = buildTrackerDays(
      workouts: ref.watch(pastWorkoutsProvider).workouts,
      manualWorkouts: ref.watch(manualWorkoutsProvider).workouts,
      liveStart: live.isInProgress ? live.workoutStartDateTime : null,
      liveTotals: workoutTotals([
        ...live.exercises,
        if (liveExercise != null) liveExercise,
      ]),
    );
    final selected = _selected ?? today;
    final entries = days[selected] ?? const <TrackerEntry>[];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          t.spacing.screen,
          16,
          t.spacing.screen,
          t.spacing.contentBottom,
        ),
        children: [
          ScreenTitle(
            'Tracker',
            label: 'ACTIVITY',
            trailing: _LogButton(onPressed: () => _logWorkout(selected)),
          ),
          SizedBox(height: t.spacing.gap14),
          Row(
            spacing: t.spacing.gap8,
            children: [
              Expanded(
                child: _StatTile(
                  value: '${trackerStreak(days, today)}',
                  label: 'DAY STREAK',
                  accent: true,
                ),
              ),
              Expanded(
                child: _StatTile(
                  value: '${trackerDaysThisMonth(days, today)}',
                  label: monthName(today.month).toUpperCase(),
                ),
              ),
              Expanded(
                child: _StatTile(value: '${days.length}', label: 'TOTAL DAYS'),
              ),
            ],
          ),
          SizedBox(height: t.spacing.gap14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(t.radii.cardLarge),
              border: Border.all(color: t.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: t.spacing.gap12,
              children: [
                // Scales down on phones narrower than the design's.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: TrackerGrid(
                    days: days,
                    today: today,
                    selected: selected,
                    onSelected: (day) => setState(() => _selected = day),
                  ),
                ),
                const _Legend(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 22, 2, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  relativeDayLabel(selected, today: today),
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 18,
                    letterSpacing: -0.36,
                  ),
                ),
                if (entries.isNotEmpty)
                  Text(
                    entries.length == 1
                        ? '1 ENTRY'
                        : '${entries.length} ENTRIES',
                    style: AppTypography.labelWide.copyWith(
                      letterSpacing: 1.32,
                      color: t.muted,
                    ),
                  ),
              ],
            ),
          ),
          if (entries.isEmpty)
            _EmptyDay(onLog: () => _logWorkout(selected))
          else
            for (final (index, entry) in entries.indexed)
              Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : t.spacing.gap14),
                child: _entryCard(entry),
              ),
        ],
      ),
    );
  }

  Widget _entryCard(TrackerEntry entry) {
    switch (entry) {
      case RecordedEntry(:final workout, :final totals):
        final start = workout.startTime!;
        final duration = (workout.endTime ?? start).difference(start);
        return TrackerEntryCard(
          icon: locationIcon(workout.displayLocationType),
          title: workout.displayTitle,
          subtitle: '${formatClockTime(start)} · ${formatElapsed(duration)} · '
              '${totals.exercises} ex · ${formatCount(totals.sets, 'set')} · '
              '${formatVolume(totals.volume)} kg',
          locationType: workout.displayLocationType,
          place: workout.place,
          onTap: () => widget.onOpenWorkout(workout),
        );
      case LiveEntry(:final totals):
        return TrackerEntryCard(
          icon: LucideIcons.clock,
          title: 'In progress',
          subtitle: '${totals.exercises} ex · '
              '${formatCount(totals.sets, 'set')} · '
              '${formatVolume(totals.volume)} kg so far',
          onTap: widget.onOpenLiveWorkout,
        );
      case ManualEntry(:final workout):
        return TrackerEntryCard(
          icon: locationIcon(workout.locationType),
          muted: true,
          title: workout.title,
          subtitle: 'Logged manually',
          locationType: workout.locationType,
          place: workout.place,
          onTap: () => widget.onOpenManualWorkout(workout),
        );
    }
  }
}

class _LogButton extends StatelessWidget {
  const _LogButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return TappableCard(
      onTap: onPressed,
      radius: t.radii.iconButton,
      child: Container(
        // 44 tall including the border.
        height: t.spacing.iconButton - 2,
        padding: const EdgeInsets.only(left: 10, right: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: t.spacing.gap6,
          children: [
            Icon(LucideIcons.plus, size: 18, color: t.fg),
            Text('Log workout', style: AppTypography.toggle),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    this.accent = false,
  });

  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent ? t.accent : t.card,
        borderRadius: BorderRadius.circular(t.radii.button),
        // The accent tile's border is its own colour, so all three tiles are
        // the same height.
        border: Border.all(color: accent ? t.accent : t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            value,
            style: AppTypography.statLarge.copyWith(
              letterSpacing: -0.78,
              color: accent ? t.accentInk : t.fg,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              letterSpacing: 1.4,
              color: accent ? t.accentInk : t.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = AppTypography.labelSmall.copyWith(
      letterSpacing: 0.8,
      color: t.muted,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('LAST $trackerWeeks WEEKS', style: style),
        Row(
          spacing: 3,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Text('LESS', style: style),
            ),
            for (var level = 0; level <= 3; level++)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: t.heat(level),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Text('MORE', style: style),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.onLog});

  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DashedBorder(
      color: t.line,
      borderRadius: t.radii.card,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          spacing: t.spacing.gap12,
          children: [
            Text(
              'No workout logged on this day',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: t.muted),
            ),
            Material(
              color: t.accent,
              borderRadius: BorderRadius.circular(t.radii.iconButton),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onLog,
                // As wide as its label, not the card.
                child: Container(
                  height: t.spacing.iconButton,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      'Log a workout',
                      style: AppTypography.toggle.copyWith(color: t.accentInk),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
