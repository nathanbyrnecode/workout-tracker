import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/screens/home/home_screen.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_action_area/workout_action_area.dart';
import 'package:gym_tracker_app/screens/notifications/notifications_screen.dart';
import 'package:gym_tracker_app/screens/profile/profile_screen.dart';
import 'package:gym_tracker_app/screens/tracker/tracker_screen.dart';
import 'package:gym_tracker_app/screens/workout_detail/manual_workout_detail_screen.dart';
import 'package:gym_tracker_app/screens/workout_detail/workout_detail_screen.dart';
import 'package:gym_tracker_app/state/current_tab_state.dart';
import 'package:gym_tracker_app/state/notifications_state.dart';
import 'package:gym_tracker_app/widgets/app_shell.dart';
import 'package:gym_tracker_app/widgets/app_tab_bar.dart';

class MainBottomNavigation extends ConsumerStatefulWidget {
  const MainBottomNavigation({super.key});

  @override
  ConsumerState<MainBottomNavigation> createState() =>
      _MainBottomNavigationState();
}

class _MainBottomNavigationState extends ConsumerState<MainBottomNavigation> {
  AppTab _tab = AppTab.home;

  /// Detail screens cover the shell, so the tab bar is hidden on them, and
  /// Back or Delete returns to whichever tab opened them.
  void _open(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => screen),
    );
  }

  void _openWorkout(Workout workout) =>
      _open(WorkoutDetailScreen(workoutId: workout.id));

  @override
  Widget build(BuildContext context) {
    final unread = hasUnread(ref.watch(notificationsProvider));
    return AppShell(
      selected: _tab,
      hasUnread: unread,
      onSelected: (tab) => setState(() => _tab = tab),
      floatingActions: _tab == AppTab.home ? const WorkoutActionArea() : null,
      child: switch (_tab) {
        AppTab.home => HomeScreen(
            hasUnread: unread,
            onOpenNotifications: () =>
                setState(() => _tab = AppTab.notifications),
            onOpenWorkout: _openWorkout,
          ),
        AppTab.tracker => TrackerScreen(
            // The Log workout sheet arrives with its own task.
            onLogWorkout: (day) {},
            onOpenWorkout: _openWorkout,
            onOpenManualWorkout: (workout) =>
                _open(ManualWorkoutDetailScreen(workoutId: workout.id)),
            onOpenLiveWorkout: () {
              ref
                  .read(currentTabProvider.notifier)
                  .setCurrentTab(TabItem.currentWorkout);
              setState(() => _tab = AppTab.home);
            },
          ),
        AppTab.notifications => const NotificationsScreen(),
        AppTab.profile => const ProfileScreen(),
      },
    );
  }
}
