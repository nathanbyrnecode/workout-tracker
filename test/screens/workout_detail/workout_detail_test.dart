import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/tracker_stats.dart';
import 'package:gym_tracker_app/main_bottom_navigation.dart';
import 'package:gym_tracker_app/screens/tracker/tracker_screen.dart';
import 'package:gym_tracker_app/screens/tracker/widgets/tracker_grid.dart';
import 'package:gym_tracker_app/screens/workout_detail/manual_workout_detail_screen.dart';
import 'package:gym_tracker_app/screens/workout_detail/workout_detail_screen.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_tab_state.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/manual_workouts_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';
import 'package:gym_tracker_app/widgets/app_tab_bar.dart';
import 'package:gym_tracker_app/widgets/location_chip.dart';

import '../../helpers/demo.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

class _PreviousTab extends CurrentTabNotifier {
  @override
  CurrentTabStateData build() => (currentTab: TabItem.previousWorkouts);
}

typedef _App = ({
  FakePastWorkoutsNotifier history,
  FakeManualWorkoutsNotifier manual,
});

/// The whole signed-in app on Home's Previous tab, with the demo history.
Future<_App> pumpWholeApp(WidgetTester tester) async {
  final history = FakePastWorkoutsNotifier(demoHistory());
  final manual = FakeManualWorkoutsNotifier(demoManualWorkouts());
  await pumpApp(
    tester,
    const MainBottomNavigation(),
    overrides: [
      clockProvider.overrideWithValue(() => demoNow),
      currentTabProvider.overrideWith(_PreviousTab.new),
      currentWorkoutProvider.overrideWith(FakeWorkoutNotifier.new),
      userAuthenticationProvider.overrideWith(FakeAuthNotifier.new),
      pastWorkoutsProvider.overrideWith(() => history),
      manualWorkoutsProvider.overrideWith(() => manual),
    ],
  );
  return (history: history, manual: manual);
}

Future<void> goToTracker(WidgetTester tester) async {
  await tester.tap(
    find
        .descendant(of: find.byType(AppTabBar), matching: find.text('Tracker'))
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> tapDay(WidgetTester tester, DateTime day) async {
  for (var week = 0; week < trackerWeeks; week++) {
    for (var weekday = 0; weekday < 7; weekday++) {
      if (trackerGridDay(demoNow, week, weekday) == day) {
        await tester.tapAt(
          tester.getTopLeft(find.byType(TrackerGrid)) +
              TrackerGrid.cellRect(week, weekday).center,
        );
        await tester.pumpAndSettle();
        return;
      }
    }
  }
}

void main() {
  testWidgets('a recorded workout shows its details, totals and every set',
      (tester) async {
    await pumpWholeApp(tester);
    await tester.tap(find.text('06/10/26'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutDetailScreen), findsOneWidget);
    // The tab bar is covered.
    expect(find.byType(AppTabBar).hitTestable(), findsNothing);
    expect(find.text('Push day'), findsOneWidget);
    expect(find.text('06/10/26 · 07:30'), findsOneWidget);
    expect(find.text('PureGym Manchester Piccadilly'), findsOneWidget);
    expect(find.text('00:02:27'), findsOneWidget);
    expect(find.text('SETS'), findsOneWidget);
    expect(find.text('TOTAL VOLUME'), findsOneWidget);
    expect(find.text('1,702 kg'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('Incline DB press'), findsOneWidget);
    expect(find.text('60 kg', findRichText: true), findsOneWidget);
    expect(find.text('480'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Delete workout'), 200);
    expect(find.text('Delete workout'), findsOneWidget);
  });

  testWidgets('Back returns to the Previous tab', (tester) async {
    await pumpWholeApp(tester);
    await tester.tap(find.text('06/10/26'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutDetailScreen), findsNothing);
    expect(find.text('OCTOBER'), findsOneWidget);
  });

  testWidgets('an edit shows on the detail screen and on the Previous card',
      (tester) async {
    await pumpWholeApp(tester);
    await tester.tap(find.text('03/10/26'));
    await tester.pumpAndSettle();
    expect(find.text('Legs'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit workout'), findsOneWidget);
    // Prefilled with the current name.
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Legs',
    );

    await tester.enterText(find.byType(TextField).first, 'Leg day');
    await tester.pump();
    await tester.tap(find.text('Park'));
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Edit workout'), findsNothing);
    expect(find.text('Leg day'), findsOneWidget);
    expect(find.text('Legs'), findsNothing);
    // The detail screen's chip has the new type.
    expect(
      find.descendant(
          of: find.byType(LocationChip), matching: find.text('Park')),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    // So does the card for 3 October on the Previous tab.
    final card = find.ancestor(
      of: find.text('03/10/26'),
      matching: find.byType(Column),
    );
    expect(
      find.descendant(
        of: card.first,
        matching: find.descendant(
          of: find.byType(LocationChip),
          matching: find.text('Park'),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Save changes is disabled while the name is empty',
      (tester) async {
    await pumpWholeApp(tester);
    await tester.tap(find.text('05/10/26'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Save changes'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Pull day'), findsOneWidget);
  });

  testWidgets('a workout saved before titles existed can be given one',
      (tester) async {
    await pumpWholeApp(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('22/09/26'));
    await tester.pumpAndSettle();

    // Shown with the fallback title; the edit field starts empty.
    expect(find.text('Workout'), findsOneWidget);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '',
    );
  });

  testWidgets('deleting from Previous asks first, then returns to Previous',
      (tester) async {
    final app = await pumpWholeApp(tester);
    await tester.tap(find.text('05/10/26'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete workout'), 200);
    await tester.tap(find.text('Delete workout'));
    await tester.pumpAndSettle();

    expect(find.text('Delete workout?'), findsOneWidget);
    expect(
      find.text(
          '“Pull day” will be removed from your history and the tracker.'),
      findsOneWidget,
    );

    // Cancel keeps it.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(app.history.deletedIds, isEmpty);
    expect(find.byType(WorkoutDetailScreen), findsOneWidget);

    await tester.tap(find.text('Delete workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Delete workout').last);
    await tester.pumpAndSettle();

    expect(app.history.deletedIds, [2]);
    expect(find.byType(WorkoutDetailScreen), findsNothing);
    expect(find.text('OCTOBER'), findsOneWidget);
    expect(find.text('05/10/26'), findsNothing);
    expect(find.text('2 WORKOUTS'), findsOneWidget);
  });

  testWidgets('a failed delete stays on the screen and says so',
      (tester) async {
    final app = await pumpWholeApp(tester);
    app.history.failWrites = true;
    await tester.tap(find.text('05/10/26'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete workout'), 200);
    await tester.tap(find.text('Delete workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Delete workout').last);
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutDetailScreen), findsOneWidget);
    expect(find.textContaining('Could not delete the workout'), findsOneWidget);
  });

  testWidgets(
      'deleting the last entry on a day from the Tracker returns there and '
      'clears the day', (tester) async {
    final app = await pumpWholeApp(tester);
    await goToTracker(tester);
    await tapDay(tester, DateTime(2026, 10, 5));
    expect(find.text('Pull day'), findsOneWidget);

    await tester.tap(find.text('Pull day'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutDetailScreen), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Delete workout'), 200);
    await tester.tap(find.text('Delete workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Delete workout').last);
    await tester.pumpAndSettle();

    // Back on the Tracker, with that day still selected and now empty.
    expect(find.byType(TrackerScreen), findsOneWidget);
    expect(find.byType(WorkoutDetailScreen), findsNothing);
    expect(app.history.deletedIds, [2]);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('No workout logged on this day'), findsOneWidget);
    // The streak that ran through yesterday is broken.
    expect(find.text('DAY STREAK'), findsOneWidget);
    final days = buildTrackerDays(
      workouts: app.history.state.workouts,
      manualWorkouts: app.manual.state.workouts,
    );
    expect(heatLevel(days[DateTime(2026, 10, 5)]), 0);
    expect(trackerStreak(days, demoNow), 1);
  });

  testWidgets('a manual workout shows its date, type and place',
      (tester) async {
    await pumpWholeApp(tester);
    await goToTracker(tester);
    await tapDay(tester, DateTime(2026, 10, 4));
    await tester.tap(find.text('Morning run'));
    await tester.pumpAndSettle();

    expect(find.byType(ManualWorkoutDetailScreen), findsOneWidget);
    expect(find.text('LOGGED MANUALLY'), findsOneWidget);
    expect(find.text('Morning run'), findsOneWidget);
    expect(find.text('04/10/26'), findsOneWidget);
    expect(find.text('Sun 4 October 2026'), findsOneWidget);
    expect(find.text('Park'), findsOneWidget);
    // In the chip and in the PLACE row.
    expect(find.text('Mayfield Park'), findsNWidgets(2));
    expect(find.text('Baring St, Manchester M1 2PY'), findsOneWidget);
    expect(
      find.text('No exercise details were recorded for this workout.'),
      findsOneWidget,
    );
  });

  testWidgets('a manual workout with no place says "Not set"', (tester) async {
    await pumpWholeApp(tester);
    await goToTracker(tester);
    await tapDay(tester, DateTime(2026, 10, 4));
    await tester.tap(find.text('Evening stretch and mobility'));
    await tester.pumpAndSettle();

    expect(find.text('Not set'), findsOneWidget);
  });

  testWidgets('a manual workout can be edited and deleted from the Tracker',
      (tester) async {
    final app = await pumpWholeApp(tester);
    await goToTracker(tester);
    await tapDay(tester, DateTime(2026, 9, 30));
    await tester.tap(find.text('Swim'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Long swim');
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Long swim'), findsOneWidget);

    // The tracker card behind has the new name too.
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(TrackerScreen), findsOneWidget);
    expect(find.text('Long swim'), findsOneWidget);

    await tester.tap(find.text('Long swim'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete workout'));
    await tester.pumpAndSettle();
    expect(
      find.text(
          '“Long swim” will be removed from your history and the tracker.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(AppButton, 'Delete workout').last);
    await tester.pumpAndSettle();

    expect(app.manual.deletedIds, [3]);
    expect(find.byType(TrackerScreen), findsOneWidget);
    expect(find.text('No workout logged on this day'), findsOneWidget);
  });
}
