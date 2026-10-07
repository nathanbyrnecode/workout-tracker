import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_screen/current_workout_area.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/golden.dart';

final now = DateTime(2026, 10, 7, 9, 41);
final start = now.subtract(const Duration(minutes: 2, seconds: 27));

Exercise finished(int id, String name, List<(double, int)> sets) => Exercise(
      name,
      {
        for (final (i, set) in sets.indexed)
          id * 100 + i: ExerciseSet(set.$1, set.$2, id * 100 + i),
      },
      id,
      start,
    )..setEndTime(start.add(const Duration(minutes: 1, seconds: 18)));

Exercise active(List<ExerciseSet> sets) => Exercise(
      'Incline DB press',
      {for (final set in sets) set.id: set},
      9,
      now.subtract(const Duration(seconds: 55)),
    );

Future<FakeWorkoutNotifier> pumpTab(
  WidgetTester tester, {
  List<Exercise> exercises = const [],
  Exercise? currentExercise,
  DateTime Function()? clock,
}) async {
  final workout = FakeWorkoutNotifier(
    startedAt: start,
    exercises: exercises,
    currentExercise: currentExercise,
  );
  await loadAppFonts();
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentWorkoutProvider.overrideWith(() => workout),
        clockProvider.overrideWithValue(clock ?? () => now),
      ],
      child: MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: const Scaffold(body: CurrentWorkoutArea()),
      ),
    ),
  );
  return workout;
}

void main() {
  testWidgets('active exercise shows its timer, sets and totals',
      (tester) async {
    await pumpTab(
      tester,
      currentExercise: active([
        ExerciseSet(22, 10, 1,
            savedAt: now.subtract(const Duration(seconds: 50))),
        ExerciseSet(24, 8, 2,
            savedAt: now.subtract(const Duration(seconds: 38))),
      ]),
    );

    expect(find.text('In progress · '), findsOneWidget);
    expect(find.text('00:55'), findsOneWidget);
    expect(find.text('Incline DB press'), findsOneWidget);
    expect(find.text('22 kg', findRichText: true), findsOneWidget);
    expect(find.text('10 reps', findRichText: true), findsOneWidget);
    expect(find.text('24 kg', findRichText: true), findsOneWidget);
    expect(find.text('8 reps', findRichText: true), findsOneWidget);
    expect(find.text('2 sets · 18 reps'), findsOneWidget);
    expect(find.text('412 kg volume'), findsOneWidget);
    expect(find.text('No sets added yet'), findsNothing);
  });

  testWidgets('the rest timer counts up from the last saved set',
      (tester) async {
    var time = now;
    await pumpTab(
      tester,
      clock: () => time,
      currentExercise: active([
        ExerciseSet(22, 10, 1,
            savedAt: now.subtract(const Duration(minutes: 5))),
        ExerciseSet(24, 8, 2,
            savedAt: now.subtract(const Duration(seconds: 38))),
      ]),
    );
    expect(find.bySemanticsLabel(RegExp('Rest time')), findsOneWidget);
    expect(find.text('00:38'), findsOneWidget);

    time = time.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:39'), findsOneWidget);
    expect(find.text('00:56'), findsOneWidget);
  });

  testWidgets('an active exercise with no sets has no rest timer or totals',
      (tester) async {
    await pumpTab(tester, currentExercise: active([]));

    expect(find.text('No sets added yet'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Rest time')), findsNothing);
    expect(find.textContaining('kg volume'), findsNothing);
  });

  testWidgets('a set saved before timestamps existed shows no rest timer',
      (tester) async {
    await pumpTab(tester, currentExercise: active([ExerciseSet(22, 10, 1)]));

    expect(find.bySemanticsLabel(RegExp('Rest time')), findsNothing);
    expect(find.text('1 set · 10 reps'), findsOneWidget);
  });

  testWidgets('the set menu deletes the set it was opened for', (tester) async {
    final workout = await pumpTab(
      tester,
      currentExercise: active([
        ExerciseSet(22, 10, 71),
        ExerciseSet(24, 8, 72),
      ]),
    );

    await tester.tap(find.bySemanticsLabel('Set 2 options'));
    await tester.pumpAndSettle();
    expect(find.text('Set 2'), findsOneWidget);
    expect(find.text('24 kg × 8 reps'), findsOneWidget);

    await tester.tap(find.text('Delete set'));
    await tester.pumpAndSettle();
    expect(workout.removedSetIds, [72]);
    expect(find.text('Delete set'), findsNothing);
  });

  testWidgets('dismissing the set menu deletes nothing', (tester) async {
    final workout = await pumpTab(
      tester,
      currentExercise: active([ExerciseSet(22, 10, 71)]),
    );

    await tester.tap(find.bySemanticsLabel(RegExp('Set 1 options')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 40));
    await tester.pumpAndSettle();
    expect(workout.removedSetIds, isEmpty);
  });

  testWidgets('completed rows list newest first with their totals',
      (tester) async {
    await pumpTab(
      tester,
      exercises: [
        finished(1, 'Bench press', [(60, 8), (65, 6), (70, 6)]),
        finished(2, 'Shoulder press', [(30, 10)]),
      ],
    );

    expect(
      tester.getTopLeft(find.text('Shoulder press')).dy,
      lessThan(tester.getTopLeft(find.text('Bench press')).dy),
    );
    expect(find.text('3 sets · 20 reps · 1m 18s'), findsOneWidget);
    expect(find.text('1,290'), findsOneWidget);
    expect(find.text('1 set · 10 reps · 1m 18s'), findsOneWidget);
    // Finished exercises cannot be edited from here.
    expect(find.bySemanticsLabel(RegExp('Set . options')), findsNothing);
    expect(find.textContaining('TOP SET'), findsNothing);
  });

  testWidgets('only one completed row is open at a time', (tester) async {
    await pumpTab(
      tester,
      exercises: [
        finished(1, 'Bench press', [(60, 8), (65, 6), (70, 6)]),
        finished(2, 'Shoulder press', [(30, 10), (32.5, 8)]),
      ],
    );

    await tester.tap(find.text('Bench press'));
    await tester.pumpAndSettle();
    expect(find.text('TOP SET 70 KG × 6'), findsOneWidget);
    expect(find.text('AVG 64.5 KG'), findsOneWidget);
    expect(find.text('60 kg', findRichText: true), findsOneWidget);
    expect(find.text('480'), findsOneWidget);

    // Opening another closes the first.
    await tester.tap(find.text('Shoulder press'));
    await tester.pumpAndSettle();
    expect(find.text('TOP SET 32.5 KG × 8'), findsOneWidget);
    expect(find.text('TOP SET 70 KG × 6'), findsNothing);
    expect(find.textContaining('TOP SET'), findsOneWidget);

    // Tapping the open one closes it.
    await tester.tap(find.text('Shoulder press'));
    await tester.pumpAndSettle();
    expect(find.textContaining('TOP SET'), findsNothing);
  });
}
