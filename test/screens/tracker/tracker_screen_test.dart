import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/tracker_stats.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/screens/tracker/tracker_screen.dart';
import 'package:gym_tracker_app/screens/tracker/widgets/tracker_entry_card.dart';
import 'package:gym_tracker_app/screens/tracker/widgets/tracker_grid.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/manual_workouts_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';

import '../../helpers/demo.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

typedef Taps = ({
  List<DateTime> logged,
  List<Workout> opened,
  List<ManualWorkout> openedManual,
  List<int> openedLive,
});

Future<Taps> pumpTracker(
  WidgetTester tester, {
  List<Workout>? history,
  List<ManualWorkout>? manual,
  FakeWorkoutNotifier Function()? live,
}) async {
  final Taps taps = (logged: [], opened: [], openedManual: [], openedLive: []);
  await pumpApp(
    tester,
    TrackerScreen(
      onLogWorkout: taps.logged.add,
      onOpenWorkout: taps.opened.add,
      onOpenManualWorkout: taps.openedManual.add,
      onOpenLiveWorkout: () => taps.openedLive.add(1),
    ),
    overrides: [
      clockProvider.overrideWithValue(() => demoNow),
      currentWorkoutProvider.overrideWith(live ?? FakeWorkoutNotifier.new),
      pastWorkoutsProvider.overrideWith(
          () => FakePastWorkoutsNotifier(history ?? demoHistory())),
      manualWorkoutsProvider.overrideWith(
          () => FakeManualWorkoutsNotifier(manual ?? demoManualWorkouts())),
    ],
  );
  return taps;
}

/// Taps the grid square for [day].
Future<void> tapDay(WidgetTester tester, DateTime day) async {
  for (var week = 0; week < trackerWeeks; week++) {
    for (var weekday = 0; weekday < 7; weekday++) {
      if (trackerGridDay(demoNow, week, weekday) == day) {
        final origin = tester.getTopLeft(find.byType(TrackerGrid));
        await tester.tapAt(origin + TrackerGrid.cellRect(week, weekday).center);
        await tester.pump();
        return;
      }
    }
  }
  fail('$day is not on the grid');
}

String statValue(WidgetTester tester, String label) {
  final column = find.ancestor(
    of: find.text(label),
    matching: find.byType(Column),
  );
  return tester
      .widget<Text>(
          find.descendant(of: column.first, matching: find.byType(Text)).first)
      .data!;
}

void main() {
  testWidgets('shows the streak, days this month and total days',
      (tester) async {
    await pumpTracker(tester);

    // Logged: 3, 4 (manual), 5, 6 Oct → a four-day streak ending today.
    expect(statValue(tester, 'DAY STREAK'), '4');
    expect(statValue(tester, 'OCTOBER'), '4');
    // Plus 22, 24, 25, 26, 27, 30 Sept and 30 Dec 2025.
    expect(statValue(tester, 'TOTAL DAYS'), '11');
    expect(find.text('LAST 17 WEEKS'), findsOneWidget);
  });

  testWidgets('today is selected and lists its recorded workout',
      (tester) async {
    final taps = await pumpTracker(tester);

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('1 ENTRY'), findsOneWidget);
    expect(find.text('Push day'), findsOneWidget);
    expect(
      find.text('07:30 · 2m 27s · 2 ex · 5 sets · 1,702 kg'),
      findsOneWidget,
    );
    expect(find.text('PureGym Manchester Piccadilly'), findsOneWidget);

    await tester.tap(find.text('Push day'));
    expect(taps.opened.single.id, 1);
  });

  testWidgets('picking a day shows what was logged on it', (tester) async {
    final taps = await pumpTracker(tester);

    await tapDay(tester, DateTime(2026, 10, 5));
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Pull day'), findsOneWidget);
    expect(find.text('Push day'), findsNothing);

    // A day with two manual entries.
    await tapDay(tester, DateTime(2026, 10, 4));
    expect(find.text('Sunday 4 October'), findsOneWidget);
    expect(find.text('2 ENTRIES'), findsOneWidget);
    expect(find.text('Logged manually'), findsNWidgets(2));
    expect(find.text('Mayfield Park'), findsOneWidget);
    // No place: the chip shows the type.
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.text('Morning run'));
    expect(taps.openedManual.single.id, 1);
  });

  testWidgets('an empty day offers to log a workout for that day',
      (tester) async {
    final taps = await pumpTracker(tester);

    await tapDay(tester, DateTime(2026, 10, 1));
    expect(find.text('Thursday 1 October'), findsOneWidget);
    expect(find.text('No workout logged on this day'), findsOneWidget);
    expect(find.textContaining('ENTR'), findsNothing);
    expect(find.byType(TrackerEntryCard), findsNothing);

    await tester.tap(find.text('Log a workout'));
    expect(taps.logged, [DateTime(2026, 10, 1)]);

    // The header button logs for the selected day too.
    await tester.tap(find.text('Log workout'));
    expect(taps.logged, [DateTime(2026, 10, 1), DateTime(2026, 10, 1)]);
  });

  testWidgets('future days cannot be picked', (tester) async {
    await pumpTracker(tester);

    await tapDay(tester, DateTime(2026, 10, 7));
    await tapDay(tester, DateTime(2026, 10, 11));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Push day'), findsOneWidget);
  });

  final liveStart = demoNow.subtract(const Duration(minutes: 3));
  FakeWorkoutNotifier liveWorkout({required bool withSet}) =>
      FakeWorkoutNotifier(
        startedAt: liveStart,
        currentExercise: Exercise(
          'Squat',
          {if (withSet) 1: ExerciseSet(100, 5, 1)},
          1,
          liveStart,
        ),
      );

  testWidgets('a workout in progress with no saved set does not log today',
      (tester) async {
    await pumpTracker(
      tester,
      history: const [],
      manual: const [],
      live: () => liveWorkout(withSet: false),
    );
    expect(find.text('No workout logged on this day'), findsOneWidget);
    expect(statValue(tester, 'DAY STREAK'), '0');
    expect(statValue(tester, 'TOTAL DAYS'), '0');
  });

  testWidgets('the workout in progress shows from its first set and opens Home',
      (tester) async {
    final taps = await pumpTracker(
      tester,
      history: const [],
      manual: const [],
      live: () => liveWorkout(withSet: true),
    );
    expect(statValue(tester, 'DAY STREAK'), '1');
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('1 ex · 1 set · 500 kg so far'), findsOneWidget);

    await tester.tap(find.text('In progress'));
    expect(taps.openedLive, hasLength(1));
  });

  testWidgets('a day lists recorded, then live, then manual entries',
      (tester) async {
    final start = demoNow.subtract(const Duration(minutes: 3));
    await pumpTracker(
      tester,
      manual: [
        ...demoManualWorkouts(),
        ManualWorkout(
          id: 9,
          date: DateTime(2026, 10, 6),
          title: 'Lunchtime walk',
          locationType: demoManualWorkouts().first.locationType,
        ),
      ],
      live: () => FakeWorkoutNotifier(
        startedAt: start,
        currentExercise:
            Exercise('Squat', {1: ExerciseSet(100, 5, 1)}, 1, start),
      ),
    );

    expect(find.text('3 ENTRIES'), findsOneWidget);
    final recorded = tester.getTopLeft(find.text('Push day')).dy;
    final inProgress = tester.getTopLeft(find.text('In progress')).dy;
    final manual = tester.getTopLeft(find.text('Lunchtime walk')).dy;
    expect(recorded, lessThan(inProgress));
    expect(inProgress, lessThan(manual));
  });
}
