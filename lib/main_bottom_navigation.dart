import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/screens/home/home_screen.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_action_area/workout_action_area.dart';
import 'package:gym_tracker_app/screens/notifications/notifications_screen.dart';
import 'package:gym_tracker_app/screens/profile/profile_screen.dart';
import 'package:gym_tracker_app/screens/tracker/tracker_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selected: _tab,
      onSelected: (tab) => setState(() => _tab = tab),
      floatingActions: _tab == AppTab.home ? const WorkoutActionArea() : null,
      child: switch (_tab) {
        AppTab.home => HomeScreen(
            onOpenNotifications: () =>
                setState(() => _tab = AppTab.notifications),
          ),
        AppTab.tracker => const TrackerScreen(),
        AppTab.notifications => const NotificationsScreen(),
        AppTab.profile => const ProfileScreen(),
      },
    );
  }
}
