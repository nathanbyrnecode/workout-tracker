import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_screen/current_workout_area.dart';
import 'package:gym_tracker_app/screens/home/widgets/sheets/new_exercise_sheet.dart';
import 'package:gym_tracker_app/screens/home/widgets/sheets/set_sheet.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_action_area/workout_action_area.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

final now = DateTime(2026, 10, 7, 9, 41);

Exercise active(List<ExerciseSet> sets) => Exercise(
      'Incline DB press',
      {for (final set in sets) set.id: set},
      9,
      now.subtract(const Duration(seconds: 55)),
    );

Future<FakeWorkoutNotifier> pumpWorkout(
  WidgetTester tester, {
  List<Exercise> exercises = const [],
  Exercise? currentExercise,
}) async {
  final workout = FakeWorkoutNotifier(
    startedAt: now.subtract(const Duration(minutes: 5)),
    exercises: exercises,
    currentExercise: currentExercise,
  );
  await pumpApp(
    tester,
    const Column(
      children: [
        Expanded(child: SingleChildScrollView(child: CurrentWorkoutArea())),
        Padding(padding: EdgeInsets.all(20), child: WorkoutActionArea()),
      ],
    ),
    overrides: [
      currentWorkoutProvider.overrideWith(() => workout),
      clockProvider.overrideWithValue(() => now),
    ],
  );
  return workout;
}

String field(WidgetTester tester, int index) =>
    tester.widget<TextField>(find.byType(TextField).at(index)).controller!.text;

void main() {
  group('new exercise', () {
    testWidgets('starts an exercise with the typed name', (tester) async {
      final workout = await pumpWorkout(tester);
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      expect(find.text('New exercise'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '  Bench press ');
      await tester.tap(find.text('Start exercise'));
      await tester.pumpAndSettle();
      expect(workout.startedExercises, ['Bench press']);
      expect(find.text('New exercise'), findsNothing);
    });

    testWidgets('an empty name becomes "Exercise N"', (tester) async {
      final done = Exercise('Squat', {1: ExerciseSet(60, 8, 1)}, 1, now)
        ..setEndTime(now);
      final workout = await pumpWorkout(tester, exercises: [done]);
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start exercise'));
      await tester.pumpAndSettle();
      expect(workout.startedExercises, ['Exercise 2']);
    });

    testWidgets('dismissing the sheet starts nothing', (tester) async {
      final workout = await pumpWorkout(tester);
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();
      expect(workout.startedExercises, isEmpty);
    });

    test('default names count the exercises already in the workout', () {
      expect(exerciseNameOrDefault('', existingExercises: 0), 'Exercise 1');
      expect(exerciseNameOrDefault('   ', existingExercises: 3), 'Exercise 4');
      expect(exerciseNameOrDefault(' Row ', existingExercises: 3), 'Row');
    });
  });

  group('add set', () {
    testWidgets('the first set starts from 20 kg × 10', (tester) async {
      final workout = await pumpWorkout(tester, currentExercise: active([]));
      await tester.tap(find.text('Add set'));
      await tester.pumpAndSettle();

      expect(find.text('Set 1'), findsOneWidget);
      expect(field(tester, 0), '20');
      expect(field(tester, 1), '10');

      await tester.tap(find.widgetWithText(InkWell, 'Add set').last);
      await tester.pumpAndSettle();
      expect(workout.addedSets, [(weight: 20.0, reps: 10)]);
    });

    testWidgets('a new set is pre-filled from the last one', (tester) async {
      await pumpWorkout(
        tester,
        currentExercise: active([
          ExerciseSet(22, 10, 1),
          ExerciseSet(24.5, 8, 2),
        ]),
      );
      await tester.tap(find.text('Add set'));
      await tester.pumpAndSettle();

      expect(find.text('Set 3'), findsOneWidget);
      expect(field(tester, 0), '24.5');
      expect(field(tester, 1), '8');
    });

    testWidgets('steppers move by 2.5 kg and 1 rep and stop at zero',
        (tester) async {
      final workout = await pumpWorkout(
        tester,
        currentExercise: active([ExerciseSet(2.5, 1, 1)]),
      );
      await tester.tap(find.text('Add set'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Increase weight · kg'));
      await tester.pump();
      expect(field(tester, 0), '5');
      await tester.tap(find.bySemanticsLabel('Increase reps'));
      await tester.pump();
      expect(field(tester, 1), '2');

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.bySemanticsLabel('Decrease weight · kg'));
        await tester.tap(find.bySemanticsLabel('Decrease reps'));
        await tester.pump();
      }
      expect(field(tester, 0), '0');
      expect(field(tester, 1), '0');

      await tester.tap(find.widgetWithText(InkWell, 'Add set').last);
      await tester.pumpAndSettle();
      expect(workout.addedSets, [(weight: 0.0, reps: 0)]);
    });

    testWidgets('typed values are used, and an empty field counts as zero',
        (tester) async {
      final workout = await pumpWorkout(tester, currentExercise: active([]));
      await tester.tap(find.text('Add set'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '82.5');
      await tester.enterText(find.byType(TextField).at(1), '');
      await tester.tap(find.widgetWithText(InkWell, 'Add set').last);
      await tester.pumpAndSettle();
      expect(workout.addedSets, [(weight: 82.5, reps: 0)]);
    });
  });

  group('set menu', () {
    testWidgets('Edit set opens the set pre-filled and saves the change',
        (tester) async {
      final workout = await pumpWorkout(
        tester,
        currentExercise: active([
          ExerciseSet(22, 10, 71),
          ExerciseSet(24, 8, 72),
        ]),
      );
      await tester.tap(find.bySemanticsLabel(RegExp('Set 2 options')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit set'));
      await tester.pumpAndSettle();

      expect(find.text('Edit set 2'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
      expect(field(tester, 0), '24');
      expect(field(tester, 1), '8');

      await tester.tap(find.bySemanticsLabel('Increase weight · kg'));
      await tester.pump();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(workout.updatedSets, [(id: 72, weight: 26.5, reps: 8)]);
      expect(workout.addedSets, isEmpty);
      expect(workout.removedSetIds, isEmpty);
    });

    testWidgets('dismissing the edit sheet changes nothing', (tester) async {
      final workout = await pumpWorkout(
        tester,
        currentExercise: active([ExerciseSet(22, 10, 71)]),
      );
      await tester.tap(find.bySemanticsLabel(RegExp('Set 1 options')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit set'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();
      expect(workout.updatedSets, isEmpty);
    });
  });

  testWidgets('the set sheet returns what it was given when confirmed',
      (tester) async {
    await pumpApp(tester, const SizedBox());
    SetValues? result;
    await openWith(tester, (context) async {
      result = await showSetSheet(
        context: context,
        number: 4,
        initial: (weight: 60, reps: 8),
      );
    });
    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();
    expect(result, (weight: 60.0, reps: 8));
  });
}
