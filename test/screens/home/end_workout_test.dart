import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/place_search/place_search_service.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_action_area/workout_action_area.dart';
import 'package:gym_tracker_app/screens/workout_summary/workout_summary_screen.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';

import '../../helpers/demo.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

final _start = demoNow.subtract(const Duration(minutes: 2, seconds: 27));

Exercise _benchPress() => Exercise(
      'Bench press',
      {1: ExerciseSet(60, 8, 1), 2: ExerciseSet(65, 6, 2)},
      1,
      _start,
    )..setEndTime(_start.add(const Duration(minutes: 1)));

/// Pumps the Home actions for a workout with one finished exercise and opens
/// the End workout sheet.
Future<({FakeWorkoutNotifier workout, FakePlaceSearchService? places})>
    openEndSheet(
  WidgetTester tester, {
  List<Workout> history = const [],
  bool withPlaceSearch = false,
}) async {
  final workout =
      FakeWorkoutNotifier(startedAt: _start, exercises: [_benchPress()]);
  final places = withPlaceSearch ? FakePlaceSearchService() : null;
  await pumpApp(
    tester,
    const Align(
      alignment: Alignment.bottomCenter,
      child: Padding(padding: EdgeInsets.all(20), child: WorkoutActionArea()),
    ),
    overrides: [
      clockProvider.overrideWithValue(() => demoNow),
      currentWorkoutProvider.overrideWith(() => workout),
      pastWorkoutsProvider
          .overrideWith(() => FakePastWorkoutsNotifier(history)),
      if (places != null) placeSearchServiceProvider.overrideWithValue(places),
    ],
  );
  await tester.tap(find.text('End workout'));
  await tester.pumpAndSettle();
  return (workout: workout, places: places);
}

/// The sheet's confirm button (the Home action behind it has the same label).
Finder endButton() => find.widgetWithText(AppButton, 'End workout');

/// Whether the tile for [type] is marked as the selected one.
bool isSelected(WidgetTester tester, LocationType type) => tester
    .widgetList<Semantics>(
      find.ancestor(
        of: find.text(type.label),
        matching: find.byType(Semantics),
      ),
    )
    .any((semantics) => semantics.properties.selected ?? false);

void main() {
  testWidgets('summarises the workout and asks for a name', (tester) async {
    await openEndSheet(tester);

    expect(find.text('End workout?'), findsOneWidget);
    expect(find.text('1 exercise · 2 sets · 870 kg in '), findsOneWidget);
    expect(find.text('00:02:27'), findsOneWidget);
    expect(find.text('WORKOUT NAME'), findsOneWidget);
    expect(find.text('REQUIRED'), findsOneWidget);
    expect(find.text('e.g. Push day'), findsOneWidget);
    expect(find.text('Keep going'), findsOneWidget);
  });

  testWidgets('cannot end without a name', (tester) async {
    final sheet = await openEndSheet(tester);

    expect(tester.widget<AppButton>(endButton()).onPressed, isNull);
    await tester.tap(endButton(), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(sheet.workout.endedWorkouts, 0);
    expect(find.text('End workout?'), findsOneWidget);

    // Spaces are not a name.
    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.pump();
    expect(tester.widget<AppButton>(endButton()).onPressed, isNull);
  });

  testWidgets('the name stops at 40 characters', (tester) async {
    await openEndSheet(tester);
    await tester.enterText(find.byType(TextField).first, 'x' * 60);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      hasLength(40),
    );
  });

  testWidgets('ends with the name and type, then shows the summary',
      (tester) async {
    final sheet = await openEndSheet(tester);

    await tester.enterText(find.byType(TextField).first, ' Push day ');
    await tester.pump();
    await tester.tap(find.text('Park'));
    await tester.pump();
    await tester.tap(endButton());
    await tester.pumpAndSettle();

    expect(sheet.workout.endedWith, [
      (title: 'Push day', type: LocationType.park, place: null),
    ]);
    expect(find.text('End workout?'), findsNothing);
    expect(find.byType(WorkoutSummaryScreen), findsOneWidget);
    expect(find.text('Push day'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutSummaryScreen), findsNothing);
  });

  testWidgets('the type defaults to the last workout\'s type', (tester) async {
    await openEndSheet(
      tester,
      history: [
        testWorkout(1, DateTime(2026, 10, 1), type: LocationType.gym),
        testWorkout(2, DateTime(2026, 10, 5), type: LocationType.home),
      ],
    );
    expect(isSelected(tester, LocationType.home), isTrue);
    expect(isSelected(tester, LocationType.gym), isFalse);
  });

  testWidgets('with no history the type defaults to Gym', (tester) async {
    await openEndSheet(tester);
    expect(isSelected(tester, LocationType.gym), isTrue);
  });

  testWidgets('a failed save keeps the sheet open with a message',
      (tester) async {
    final sheet = await openEndSheet(tester);
    sheet.workout.endOutcome = EndWorkoutOutcome.failed;

    await tester.enterText(find.byType(TextField).first, 'Push day');
    await tester.pump();
    await tester.tap(endButton());
    await tester.pumpAndSettle();

    expect(find.text('End workout?'), findsOneWidget);
    expect(find.textContaining('Could not save the workout'), findsOneWidget);
    expect(find.byType(WorkoutSummaryScreen), findsNothing);

    // Trying again works.
    sheet.workout.endOutcome = EndWorkoutOutcome.saved;
    await tester.tap(endButton());
    await tester.pumpAndSettle();
    expect(sheet.workout.endedWorkouts, 2);
    expect(find.byType(WorkoutSummaryScreen), findsOneWidget);
  });

  testWidgets('Keep going closes the sheet and ends nothing', (tester) async {
    final sheet = await openEndSheet(tester);
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(find.text('End workout?'), findsNothing);
    expect(sheet.workout.endedWorkouts, 0);
  });

  testWidgets('with no place search, Place is not offered', (tester) async {
    await openEndSheet(tester);
    expect(find.text('LOCATION'), findsOneWidget);
    expect(find.text('PLACE'), findsNothing);
    expect(find.text('Search for a location'), findsNothing);
  });

  group('place search', () {
    testWidgets('opens on nearby places, nearest first', (tester) async {
      await openEndSheet(tester, withPlaceSearch: true);
      expect(find.text('PLACE'), findsOneWidget);
      expect(find.text('OPTIONAL'), findsOneWidget);

      await tester.tap(find.text('Search for a location'));
      await tester.pumpAndSettle();

      expect(find.text('Use current location'), findsOneWidget);
      expect(find.text('NEARBY'), findsOneWidget);
      expect(find.text('0.4 mi'), findsOneWidget);
      final gym = tester.getTopLeft(find.text('PureGym Manchester Piccadilly'));
      final park = tester.getTopLeft(find.text('Mayfield Park'));
      expect(gym.dy, lessThan(park.dy));
    });

    testWidgets('typing filters to RESULTS after a pause', (tester) async {
      final sheet = await openEndSheet(tester, withPlaceSearch: true);
      await tester.tap(find.text('Search for a location'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'park');
      // Nothing is asked until typing pauses.
      await tester.pump(const Duration(milliseconds: 100));
      expect(sheet.places!.searches, isEmpty);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(sheet.places!.searches, ['park']);
      expect(find.text('RESULTS'), findsOneWidget);
      expect(find.text('NEARBY'), findsNothing);
      expect(find.text('Mayfield Park'), findsOneWidget);
      expect(find.text('Whitworth Park'), findsOneWidget);
      expect(find.text('PureGym Manchester Piccadilly'), findsNothing);
    });

    testWidgets('says so when nothing matches', (tester) async {
      await openEndSheet(tester, withPlaceSearch: true);
      await tester.tap(find.text('Search for a location'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'zzz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('No places match “zzz”'), findsOneWidget);
      // Still labelled as results, as in the design, not as nearby places.
      expect(find.text('RESULTS'), findsOneWidget);
      expect(find.text('NEARBY'), findsNothing);
    });

    testWidgets('picking a place keeps the type and is saved with the workout',
        (tester) async {
      final sheet = await openEndSheet(tester, withPlaceSearch: true);
      await tester.tap(find.text('Home'));
      await tester.pump();
      await tester.tap(find.text('Search for a location'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mayfield Park'));
      await tester.pumpAndSettle();

      // The panel collapses to the chosen place; the type is untouched.
      expect(find.text('NEARBY'), findsNothing);
      expect(find.text('Mayfield Park'), findsOneWidget);
      expect(find.text('Baring St, Manchester M1 2PY'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(isSelected(tester, LocationType.home), isTrue);

      await tester.enterText(find.byType(TextField).first, 'Circuit');
      await tester.pump();
      await tester.tap(endButton());
      await tester.pumpAndSettle();

      final ended = sheet.workout.endedWith.single;
      expect(ended.title, 'Circuit');
      expect(ended.type, LocationType.home);
      expect(ended.place?.name, 'Mayfield Park');
      expect(ended.place?.address, 'Baring St, Manchester M1 2PY');
    });

    testWidgets('a chosen place can be removed or changed', (tester) async {
      await openEndSheet(tester, withPlaceSearch: true);
      await tester.tap(find.text('Search for a location'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mayfield Park'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      expect(find.text('NEARBY'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      // Cancelling a change keeps the place that was there.
      expect(find.text('Mayfield Park'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(RegExp('Remove place')));
      await tester.pumpAndSettle();
      expect(find.text('Mayfield Park'), findsNothing);
      expect(find.text('Search for a location'), findsOneWidget);
    });

    testWidgets('Use current location asks the service only when tapped',
        (tester) async {
      final sheet = await openEndSheet(tester, withPlaceSearch: true);
      await tester.tap(find.text('Search for a location'));
      await tester.pumpAndSettle();
      expect(sheet.places!.currentLocationRequests, 0);

      await tester.tap(find.text('Use current location'));
      await tester.pumpAndSettle();
      expect(sheet.places!.currentLocationRequests, 1);
      expect(find.text('Current location'), findsOneWidget);
      expect(find.text('Near Piccadilly, Manchester M1'), findsOneWidget);
    });
  });
}
