import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/screens/home/home_screen.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_action_area/workout_action_area.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/widgets/app_shell.dart';
import 'package:gym_tracker_app/widgets/app_tab_bar.dart';

import '../../helpers/fakes.dart';
import '../../helpers/golden.dart';

final _now = DateTime(2026, 10, 7, 9, 41);

/// Home inside the shell, as in `design/workout-tracker/screens/home-*.png`.
void homeGolden(
  String description, {
  required String name,
  required FakeWorkoutNotifier Function() workout,
}) {
  goldenTest(
    description,
    name: name,
    wrap: (child) => ProviderScope(
      overrides: [
        currentWorkoutProvider.overrideWith(workout),
        userAuthenticationProvider.overrideWith(FakeAuthNotifier.new),
        pastWorkoutsProvider.overrideWith(FakePastWorkoutsNotifier.new),
        clockProvider.overrideWithValue(() => _now),
      ],
      child: child,
    ),
    builder: (context) => AppShell(
      selected: AppTab.home,
      onSelected: (_) {},
      hasUnread: true,
      floatingActions: const WorkoutActionArea(),
      child: HomeScreen(onOpenNotifications: () {}, hasUnread: true),
    ),
  );
}

void main() {
  homeGolden(
    'home with no workout',
    name: 'home_idle',
    workout: FakeWorkoutNotifier.new,
  );

  homeGolden(
    'home with a workout and no exercises',
    name: 'home_empty_workout',
    workout: () => FakeWorkoutNotifier(startedAt: _now),
  );

  homeGolden(
    'home while checking for an unfinished workout',
    name: 'home_recovery_loading',
    workout: () => FakeWorkoutNotifier(
      recoveryStatus: WorkoutRecoveryStatus.loading,
    ),
  );

  homeGolden(
    'home after the unfinished workout check failed',
    name: 'home_recovery_failed',
    workout: () => FakeWorkoutNotifier(
      recoveryStatus: WorkoutRecoveryStatus.failed,
    ),
  );
}
