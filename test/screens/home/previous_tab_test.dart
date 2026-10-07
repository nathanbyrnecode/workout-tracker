import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/screens/home/home_screen.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_history_card.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_tab_state.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/widgets/location_chip.dart';

import '../../helpers/demo.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

class _PreviousTab extends CurrentTabNotifier {
  @override
  CurrentTabStateData build() => (currentTab: TabItem.previousWorkouts);
}

Future<List<Workout>> pumpPrevious(
  WidgetTester tester, {
  required List<Workout> history,
}) async {
  final opened = <Workout>[];
  await pumpApp(
    tester,
    HomeScreen(onOpenNotifications: () {}, onOpenWorkout: opened.add),
    overrides: [
      currentTabProvider.overrideWith(_PreviousTab.new),
      currentWorkoutProvider.overrideWith(FakeWorkoutNotifier.new),
      userAuthenticationProvider.overrideWith(FakeAuthNotifier.new),
      pastWorkoutsProvider
          .overrideWith(() => FakePastWorkoutsNotifier(history)),
      clockProvider.overrideWithValue(() => demoNow),
    ],
  );
  return opened;
}

double top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text).hitTestable().first).dy;

void main() {
  testWidgets('lists history under year and month headers with counts',
      (tester) async {
    await pumpPrevious(tester, history: demoHistory());

    expect(find.text('2026'), findsOneWidget);
    expect(find.text('OCTOBER'), findsOneWidget);
    expect(find.text('3 WORKOUTS'), findsOneWidget);
    expect(top(tester, '2026'), lessThan(top(tester, 'OCTOBER')));
    expect(top(tester, 'OCTOBER'), lessThan(top(tester, '06/10/26')));
    expect(top(tester, '06/10/26'), lessThan(top(tester, '05/10/26')));
  });

  testWidgets('a card shows the date, place and four totals', (tester) async {
    await pumpPrevious(tester, history: [demoHistory().first]);

    final card = find.byType(WorkoutHistoryCard);
    expect(card, findsOneWidget);
    expect(find.text('1 WORKOUT'), findsOneWidget);
    expect(find.text('06/10/26'), findsOneWidget);
    expect(find.text('PureGym Manchester Piccadilly'), findsOneWidget);
    for (final value in ['2', '5', '38', '1,702']) {
      expect(find.descendant(of: card, matching: find.text(value)),
          findsOneWidget);
    }
    // No time, duration or title on the card.
    expect(find.text('Push day'), findsNothing);
    expect(find.textContaining('07:30'), findsNothing);
  });

  testWidgets('a long place name gives way; the date never shrinks',
      (tester) async {
    await pumpPrevious(tester, history: [demoHistory().first]);

    final date = tester.getSize(find.text('06/10/26'));
    final chip = tester.getRect(find.byType(LocationChip));
    final cardRight = tester.getRect(find.byType(WorkoutHistoryCard)).right;
    // The date is laid out at its full width on one line.
    expect(date.height, lessThan(30));
    expect(date.width, greaterThan(60));
    // The chip stops short of the chevron.
    expect(chip.right, lessThan(cardRight - 30));
  });

  testWidgets('a workout with no saved location shows the fallback type',
      (tester) async {
    await pumpPrevious(
      tester,
      history: [testWorkout(8, DateTime(2026, 9, 22, 9))],
    );
    expect(find.text('Gym'), findsOneWidget);
  });

  testWidgets('tapping a card opens that workout', (tester) async {
    final opened = await pumpPrevious(tester, history: demoHistory());
    await tester.tap(find.text('05/10/26'));
    expect(opened.single.id, 2);
  });

  testWidgets('year and month headers stick, and the next month takes over',
      (tester) async {
    await pumpPrevious(tester, history: demoHistory());
    final restingYear = top(tester, '2026');
    expect(restingYear, greaterThan(200));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pumpAndSettle();
    // The page header has scrolled away; the year sits at the top with the
    // month directly under it.
    expect(find.text('Nathan').hitTestable(), findsNothing);
    expect(top(tester, '2026'), lessThan(20));
    expect(top(tester, 'OCTOBER') - top(tester, '2026'), closeTo(44, 14));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pumpAndSettle();
    // September has pushed October off; the year is still there.
    expect(find.text('OCTOBER').hitTestable(), findsNothing);
    expect(find.text('SEPTEMBER').hitTestable(), findsOneWidget);
    expect(find.text('5 WORKOUTS').hitTestable(), findsOneWidget);
    expect(top(tester, '2026'), lessThan(20));
  });

  testWidgets('only headers stuck at the top have the blurred fill',
      (tester) async {
    await pumpPrevious(tester, history: demoHistory());
    bool filled(String header) => find
        .ancestor(of: find.text(header), matching: find.byType(BackdropFilter))
        .evaluate()
        .isNotEmpty;

    // At rest nothing is stuck.
    expect(filled('2026'), isFalse);
    expect(filled('OCTOBER'), isFalse);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pump();

    // October and its year are stuck; September is still on its way up.
    expect(filled('2026'), isTrue);
    expect(filled('OCTOBER'), isTrue);
    expect(find.text('SEPTEMBER').hitTestable(), findsOneWidget);
    expect(filled('SEPTEMBER'), isFalse);
  });

  testWidgets('with no history it says so', (tester) async {
    await pumpPrevious(tester, history: const []);
    expect(find.text('Workouts you finish will show up here.'), findsOneWidget);
    expect(find.byType(WorkoutHistoryCard), findsNothing);
  });
}
