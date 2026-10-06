import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_screen/current_workout_area.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_screen/previous_workouts_area.dart';
import 'package:gym_tracker_app/screens/home/widgets/timer_count.dart';
import 'package:gym_tracker_app/state/current_tab_state.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/util/color_utils.dart';
import 'package:gym_tracker_app/widgets/activity_pill.dart';

class HomeScreenV2 extends ConsumerStatefulWidget {
  const HomeScreenV2({super.key});

  @override
  ConsumerState<HomeScreenV2> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreenV2> {
  @override
  Widget build(BuildContext context) {
    final currentTabState = ref.watch(currentTabProvider);
    final currentTabNotifier = ref.read(currentTabProvider.notifier);
    var workoutProvider = ref.watch(currentWorkoutProvider);
    bool workoutInProgress = workoutProvider.isInProgress;
    final user = ref.watch(userAuthenticationProvider);

    return SafeArea(
      child: Stack(children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                          '$greeting${(user.firstName ?? '').isEmpty ? "!" : ""}',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.normal)),
                      if ((user.firstName ?? '').isNotEmpty)
                        Text(' ${user.firstName}!',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: Color(0xffB6E3FF),
                        size: 24,
                      ))
                ],
              ),
            ),
            // == workout timer ==
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: 14,
                    children: [
                      Text(
                        "Workout",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14),
                      ),
                      ActivityPill(
                        active: workoutInProgress,
                      )
                    ],
                  ),
                  if (workoutProvider.isInProgress)
                    TimerCount(
                      startTime: workoutProvider.workoutStartDateTime ??
                          DateTime.now(),
                      includeHours: true,
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 31,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: TabButton(
                      label: 'Current Workout',
                      enabled:
                          currentTabState.currentTab == TabItem.currentWorkout,
                      onTap: () {
                        currentTabNotifier
                            .setCurrentTab(TabItem.currentWorkout);
                      },
                    ),
                  ),
                  Expanded(
                    child: TabButton(
                      label: 'Previous Workouts',
                      enabled: currentTabState.currentTab ==
                          TabItem.previousWorkouts,
                      onTap: () {
                        currentTabNotifier
                            .setCurrentTab(TabItem.previousWorkouts);
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (currentTabState.currentTab == TabItem.currentWorkout)
              Expanded(child: CurrentWorkoutArea())
            else if (currentTabState.currentTab == TabItem.previousWorkouts)
              Expanded(child: PreviousWorkoutsArea()),
          ],
        ),
      ]),
    );
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }
}

class TabButton extends StatelessWidget {
  const TabButton({
    super.key,
    required this.onTap,
    this.enabled = true,
    this.label = 'Tab Button',
  });

  final void Function() onTap;
  final bool enabled;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: primaryColour, width: 1),
        borderRadius: BorderRadius.circular(100),
      ),
      color: enabled ? primaryColour : Colors.transparent,
      child: InkWell(
        splashColor: darken(primaryColour, 0.08).withValues(alpha: 0.8),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color:
                    enabled ? Color.fromARGB(255, 32, 39, 48) : primaryColour,
                fontSize: 16,
                fontWeight: FontWeight.normal),
          ),
        ),
      ),
    );
  }
}
