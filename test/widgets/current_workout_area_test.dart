import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_screen/current_workout_area.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_action_area/workout_action_area.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/theme/app_theme.dart';

import '../helpers/fakes.dart';

void main() {
  Future<void> pump(WidgetTester tester, CurrentWorkoutNotifier notifier) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [currentWorkoutProvider.overrideWith(() => notifier)],
          child: MaterialApp(
            theme: buildAppTheme(Brightness.dark),
            home: const Scaffold(
              body: Column(children: [
                Expanded(child: CurrentWorkoutArea()),
                WorkoutActionArea(),
              ]),
            ),
          ),
        ),
      );

  testWidgets('shows progress and no Start while the device copy is read',
      (tester) async {
    await pump(
      tester,
      FakeWorkoutNotifier(recoveryStatus: WorkoutRecoveryStatus.loading),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Checking for an unfinished workout…'), findsOneWidget);
    expect(find.text('Start workout'), findsNothing);
  });

  testWidgets('offers Start once the device copy has been read',
      (tester) async {
    await pump(tester, FakeWorkoutNotifier());
    expect(find.text('Start workout'), findsOneWidget);
    expect(find.textContaining('Get started by starting a'), findsOneWidget);
    expect(find.textContaining('Retry'), findsNothing);
  });
}
