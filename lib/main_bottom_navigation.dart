import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';
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

/// The workout whose detail screen is open over a tab.
typedef _OpenDetail = ({int id, bool manual});

class MainBottomNavigation extends ConsumerStatefulWidget {
  const MainBottomNavigation({super.key});

  @override
  ConsumerState<MainBottomNavigation> createState() =>
      _MainBottomNavigationState();
}

class _MainBottomNavigationState extends ConsumerState<MainBottomNavigation> {
  AppTab _tab = AppTab.home;

  /// A detail screen takes the place of the tab's screen, inside the shell,
  /// so the tab bar stays visible as the design shows. Closing it (Back or
  /// Delete) reveals the tab it was opened from, still in the same state.
  _OpenDetail? _detail;

  void _openWorkout(Workout workout) =>
      setState(() => _detail = (id: workout.id, manual: false));

  void _openManualWorkout(ManualWorkout workout) =>
      setState(() => _detail = (id: workout.id, manual: true));

  void _closeDetail() => setState(() => _detail = null);

  @override
  Widget build(BuildContext context) {
    final unread = hasUnread(ref.watch(notificationsProvider));
    final detail = _detail;

    return PopScope(
      // The system back gesture closes an open detail screen first.
      canPop: detail == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _closeDetail();
        }
      },
      child: AppShell(
        selected: _tab,
        hasUnread: unread,
        onSelected: (tab) => setState(() {
          _tab = tab;
          _detail = null;
        }),
        floatingActions: _tab == AppTab.home && detail == null
            ? const WorkoutActionArea()
            : null,
        // Both stay in the tree so the tab keeps its scroll position and
        // selected day while a detail screen is open over it.
        child: Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: detail != null,
              child: TickerMode(enabled: detail == null, child: _tabScreen()),
            ),
            if (detail != null)
              detail.manual
                  ? ManualWorkoutDetailScreen(
                      key: ValueKey(detail),
                      workoutId: detail.id,
                      onClose: _closeDetail,
                    )
                  : WorkoutDetailScreen(
                      key: ValueKey(detail),
                      workoutId: detail.id,
                      onClose: _closeDetail,
                    ),
          ],
        ),
      ),
    );
  }

  Widget _tabScreen() {
    return switch (_tab) {
      AppTab.home => HomeScreen(
          hasUnread: hasUnread(ref.watch(notificationsProvider)),
          onOpenNotifications: () =>
              setState(() => _tab = AppTab.notifications),
          onOpenWorkout: _openWorkout,
        ),
      AppTab.tracker => TrackerScreen(
          onOpenWorkout: _openWorkout,
          onOpenManualWorkout: _openManualWorkout,
          onOpenLiveWorkout: () {
            ref
                .read(currentTabProvider.notifier)
                .setCurrentTab(TabItem.currentWorkout);
            setState(() => _tab = AppTab.home);
          },
        ),
      AppTab.notifications => const NotificationsScreen(),
      AppTab.profile => const ProfileScreen(),
    };
  }
}
