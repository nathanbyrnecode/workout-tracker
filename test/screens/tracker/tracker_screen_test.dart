import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/tracker_stats.dart';
import 'package:gym_tracker_app/data/place_search/place_search_service.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/screens/tracker/tracker_screen.dart';
import 'package:gym_tracker_app/screens/tracker/widgets/tracker_entry_card.dart';
import 'package:gym_tracker_app/screens/tracker/widgets/tracker_grid.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/manual_workouts_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';

import '../../helpers/demo.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

typedef Taps = ({
  FakeManualWorkoutsNotifier manual,
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
  final manualNotifier =
      FakeManualWorkoutsNotifier(manual ?? demoManualWorkouts());
  final Taps taps = (
    manual: manualNotifier,
    opened: [],
    openedManual: [],
    openedLive: [],
  );
  await pumpApp(
    tester,
    TrackerScreen(
      onOpenWorkout: taps.opened.add,
      onOpenManualWorkout: taps.openedManual.add,
      onOpenLiveWorkout: () => taps.openedLive.add(1),
    ),
    overrides: [
      clockProvider.overrideWithValue(() => demoNow),
      currentWorkoutProvider.overrideWith(live ?? FakeWorkoutNotifier.new),
      pastWorkoutsProvider.overrideWith(
          () => FakePastWorkoutsNotifier(history ?? demoHistory())),
      manualWorkoutsProvider.overrideWith(() => manualNotifier),
      placeSearchServiceProvider
          .overrideWithValue(const UnavailablePlaceSearchService()),
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

  testWidgets('an empty day says so and offers to log a workout',
      (tester) async {
    await pumpTracker(tester);

    await tapDay(tester, DateTime(2026, 10, 1));
    expect(find.text('Thursday 1 October'), findsOneWidget);
    expect(find.text('No workout logged on this day'), findsOneWidget);
    expect(find.textContaining('ENTR'), findsNothing);
    expect(find.byType(TrackerEntryCard), findsNothing);
    expect(find.text('Log a workout'), findsOneWidget);
  });

  group('logging a workout', () {
    Future<void> openLogSheet(WidgetTester tester, String button) async {
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
    }

    AppButton addButton(WidgetTester tester) =>
        tester.widget<AppButton>(find.widgetWithText(AppButton, 'Add workout'));

    testWidgets('the sheet opens on the selected day', (tester) async {
      await pumpTracker(tester);
      await tapDay(tester, DateTime(2026, 10, 1));
      await openLogSheet(tester, 'Log a workout');

      // The sheet's title; the empty-day button behind it says the same.
      expect(find.text('Log a workout'), findsNWidgets(2));
      expect(
        find.text("For workouts you didn't record in the app."),
        findsOneWidget,
      );
      expect(find.text('01 OCT 2026'), findsOneWidget);
      expect(find.text('e.g. Morning run'), findsOneWidget);
      // The header button opens it on the selected day too.
      await tester.tapAt(const Offset(195, 20));
      await tester.pumpAndSettle();
      await openLogSheet(tester, 'Log workout');
      expect(find.text('01 OCT 2026'), findsOneWidget);
    });

    testWidgets('the date steps back freely but not past today',
        (tester) async {
      await pumpTracker(tester);
      await openLogSheet(tester, 'Log workout');
      expect(find.text('06 OCT 2026'), findsOneWidget);

      // Already on today: Next does nothing.
      await tester.tap(find.bySemanticsLabel('Next day'), warnIfMissed: false);
      await tester.pump();
      expect(find.text('06 OCT 2026'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Previous day'));
      await tester.pump();
      expect(find.text('05 OCT 2026'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Previous day'));
      await tester.pump();
      expect(find.text('04 OCT 2026'), findsOneWidget);
      expect(find.text('Sunday 4 October'), findsWidgets);

      await tester.tap(find.bySemanticsLabel('Next day'));
      await tester.tap(find.bySemanticsLabel('Next day'));
      await tester.pump();
      expect(find.text('06 OCT 2026'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Next day'), warnIfMissed: false);
      await tester.pump();
      expect(find.text('06 OCT 2026'), findsOneWidget);
    });

    testWidgets('Add workout is disabled until there is a name',
        (tester) async {
      final taps = await pumpTracker(tester);
      await openLogSheet(tester, 'Log workout');

      expect(addButton(tester).onPressed, isNull);
      await tester.tap(find.text('Add workout'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(taps.manual.added, isEmpty);

      await tester.enterText(find.byType(TextField).first, '  ');
      await tester.pump();
      expect(addButton(tester).onPressed, isNull);
      await tester.enterText(find.byType(TextField).first, 'Run');
      await tester.pump();
      expect(addButton(tester).onPressed, isNotNull);
    });

    testWidgets(
        'adding logs it for the chosen day and the tracker shows that day',
        (tester) async {
      final taps = await pumpTracker(tester);
      // Today is selected; log for the 1st, three days back from the 4th.
      await tapDay(tester, DateTime(2026, 10, 2));
      await openLogSheet(tester, 'Log a workout');
      await tester.tap(find.bySemanticsLabel('Previous day'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, ' Morning run ');
      await tester.pump();
      await tester.tap(find.text('Park'));
      await tester.pump();
      await tester.tap(find.text('Add workout'));
      await tester.pumpAndSettle();

      expect(taps.manual.added.single.date, DateTime(2026, 10, 1));
      expect(taps.manual.added.single.title, 'Morning run');
      expect(taps.manual.added.single.locationType, LocationType.park);
      // The sheet is gone and the tracker has moved to the logged day,
      // without a reload.
      expect(find.text('Add workout'), findsNothing);
      expect(find.text('Thursday 1 October'), findsOneWidget);
      expect(find.text('Morning run'), findsOneWidget);
      expect(find.text('Logged manually'), findsOneWidget);
      expect(find.text('1 ENTRY'), findsOneWidget);
      expect(statValue(tester, 'TOTAL DAYS'), '12');
    });

    testWidgets('a day can have several logged workouts', (tester) async {
      final taps = await pumpTracker(tester);
      await tapDay(tester, DateTime(2026, 10, 1));

      for (final name in ['Morning run', 'Evening swim']) {
        await openLogSheet(tester, 'Log workout');
        await tester.enterText(find.byType(TextField).first, name);
        await tester.pump();
        await tester.tap(find.text('Add workout'));
        await tester.pumpAndSettle();
      }

      expect(taps.manual.added, hasLength(2));
      expect(find.text('2 ENTRIES'), findsOneWidget);
      expect(find.text('Morning run'), findsOneWidget);
      expect(find.text('Evening swim'), findsOneWidget);
    });

    testWidgets('a failed add keeps the sheet open with a message',
        (tester) async {
      final taps = await pumpTracker(tester);
      taps.manual.failAdds = true;
      await openLogSheet(tester, 'Log workout');
      await tester.enterText(find.byType(TextField).first, 'Run');
      await tester.pump();
      await tester.tap(find.text('Add workout'));
      await tester.pumpAndSettle();

      expect(find.text('Add workout'), findsOneWidget);
      expect(find.textContaining('Could not add the workout'), findsOneWidget);
    });

    testWidgets('the type starts as the most recent workout\'s type',
        (tester) async {
      await pumpTracker(
        tester,
        history: [
          testWorkout(1, DateTime(2026, 10, 5), type: LocationType.home)
        ],
      );
      await openLogSheet(tester, 'Log workout');
      expect(
        tester
            .widgetList<Semantics>(find.ancestor(
                of: find.text('Home'), matching: find.byType(Semantics)))
            .any((semantics) => semantics.properties.selected ?? false),
        isTrue,
      );
    });
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
