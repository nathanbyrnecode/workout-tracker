import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_header.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_screen/current_workout_area.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_screen/previous_workouts_area.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_toggle.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_block.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_tab_state.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';

/// Home: header, workout block, the Current / Previous toggle and the tab it
/// selects. The floating actions belong to the shell; see
/// `MainBottomNavigation`.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onOpenNotifications,
    this.hasUnread = false,
  });

  final VoidCallback onOpenNotifications;
  final bool hasUnread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final tab = ref.watch(currentTabProvider).currentTab;
    final workout = ref.watch(currentWorkoutProvider);
    final user = ref.watch(userAuthenticationProvider);
    final activeExercise = workout.currentExercise;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeHeader(
            firstName: user.firstName,
            now: ref.watch(clockProvider)(),
            onOpenNotifications: onOpenNotifications,
            hasUnread: hasUnread,
          ),
          WorkoutBlock(
            startTime:
                workout.isInProgress ? workout.workoutStartDateTime : null,
            totals: workoutTotals([
              ...workout.exercises,
              if (activeExercise != null) activeExercise,
            ]),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              t.spacing.screen,
              t.spacing.gap22,
              t.spacing.screen,
              0,
            ),
            child: HomeToggle(
              selected: tab,
              onSelected: ref.read(currentTabProvider.notifier).setCurrentTab,
            ),
          ),
          Expanded(
            child: switch (tab) {
              TabItem.currentWorkout => const CurrentWorkoutArea(),
              TabItem.previousWorkouts => const PreviousWorkoutsArea(),
            },
          ),
        ],
      ),
    );
  }
}
