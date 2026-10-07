import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/data/workout_history.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_history_card.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/date_format.dart';
import 'package:gym_tracker_app/util/number_format.dart';

/// Home's Previous tab, as a sliver for Home's scroll view: finished workouts
/// grouped by year and month, newest first. The year header sticks to the top
/// and the month header sticks under it; each new one pushes the last away.
class PreviousWorkoutsArea extends ConsumerWidget {
  const PreviousWorkoutsArea({
    super.key,
    required this.onOpenWorkout,
    this.headersFilled = false,
  });

  final ValueChanged<Workout> onOpenWorkout;

  /// Whether the sticky headers have a blurred fill behind them. True once
  /// the list has scrolled up under the status bar; at rest they are clear.
  final bool headersFilled;

  static const yearHeaderHeight = 44.0;
  static const monthHeaderHeight = 34.0;

  /// Space between the toggle and the first year header.
  static const topPadding = 10.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final years =
        groupWorkoutsByMonth(ref.watch(pastWorkoutsProvider).workouts);

    if (years.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(60, 82, 60, 64),
          child: Text(
            'Workouts you finish will show up here.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: t.muted),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(top: topPadding),
      sliver: SliverMainAxisGroup(
        slivers: [
          for (final year in years)
            SliverMainAxisGroup(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HeaderDelegate(
                    height: yearHeaderHeight,
                    filled: headersFilled,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${year.year}',
                        style: AppTypography.statLarge
                            .copyWith(letterSpacing: -1.04),
                      ),
                    ),
                  ),
                ),
                for (final month in year.months)
                  SliverMainAxisGroup(
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _HeaderDelegate(
                          height: monthHeaderHeight,
                          filled: headersFilled,
                          underline: true,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                monthName(month.month).toUpperCase(),
                                style: AppTypography.labelWide
                                    .copyWith(color: t.accentText),
                              ),
                              Text(
                                formatCount(month.workouts.length, 'workout')
                                    .toUpperCase(),
                                style: AppTypography.labelWide.copyWith(
                                  letterSpacing: 1.32,
                                  color: t.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          t.spacing.screen,
                          t.spacing.gap10,
                          t.spacing.screen,
                          t.spacing.gap14,
                        ),
                        sliver: SliverList.separated(
                          itemCount: month.workouts.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: t.spacing.gap10),
                          itemBuilder: (context, index) {
                            final workout = month.workouts[index];
                            return WorkoutHistoryCard(
                              key: ValueKey(workout.id),
                              workout: workout,
                              onTap: () => onOpenWorkout(workout),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A fixed-height sticky header that spans the screen. Clear at rest; with
/// [filled] it gets the page colour at 70% over a blur of what is behind it.
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HeaderDelegate({
    required this.height,
    required this.filled,
    required this.child,
    this.underline = false,
  });

  final double height;
  final bool filled;
  final bool underline;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = context.tokens;
    return StickyHeaderFill(
      filled: filled,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: underline ? Border(bottom: BorderSide(color: t.line)) : null,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: t.spacing.screen),
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_HeaderDelegate oldDelegate) =>
      height != oldDelegate.height ||
      filled != oldDelegate.filled ||
      underline != oldDelegate.underline ||
      child != oldDelegate.child;
}

/// The fill behind Home's sticky headers and the status bar once the history
/// list is scrolled under them: the page colour at 70% over a 20px blur.
class StickyHeaderFill extends StatelessWidget {
  const StickyHeaderFill({super.key, required this.filled, this.child});

  final bool filled;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (!filled) {
      return SizedBox.expand(child: child);
    }
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: ColoredBox(
          color: t.bg.withValues(alpha: 0.7),
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}
