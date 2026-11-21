import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/models/cardio_timer.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/models/weight_unit.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/screens/home/widgets/completed_exercise_card.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_screen/current_workout_area.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_action_area/workout_action_area.dart';
import 'package:gym_tracker_app/screens/workout_detail/workout_detail_screen.dart';
import 'package:gym_tracker_app/screens/workout_summary/workout_summary_screen.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/state/workout_sync_state.dart';
import 'package:gym_tracker_app/util/number_format.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

final now = DateTime(2026, 11, 21, 9, 41);

DateTime ago(int seconds) => now.subtract(Duration(seconds: seconds));

Exercise cardio(CardioTimer timer) => Exercise(
      'Treadmill run',
      {},
      9,
      ago(1200),
      type: ExerciseType.cardio,
      cardio: timer,
    );

final notStarted = cardio(const CardioTimer());
final oneLap = cardio(
  CardioTimer(laps: const [Duration.zero], runningSince: ago(612)),
);
final twoLaps = cardio(
  CardioTimer(
    laps: const [Duration(seconds: 612), Duration.zero],
    runningSince: ago(95),
  ),
);
final pausedOneLap = cardio(
  CardioTimer(laps: const [Duration(seconds: 612)], pausedAt: ago(42)),
);
final pausedTwoLaps = cardio(
  CardioTimer(
    laps: const [Duration(seconds: 612), Duration(seconds: 540)],
    pausedAt: ago(42),
  ),
);

Exercise finished(List<int> laps) => Exercise(
      'Treadmill run',
      {},
      9,
      ago(1200),
      type: ExerciseType.cardio,
      cardio: CardioTimer.fromLapSeconds(laps),
    )..setEndTime(now);

Future<FakeWorkoutNotifier> pumpCardio(
  WidgetTester tester,
  Exercise exercise,
) async {
  final workout = FakeWorkoutNotifier(
    startedAt: ago(1340),
    currentExercise: exercise,
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

void main() {
  group('active cardio card', () {
    testWidgets('not started: prompts to start and offers no laps',
        (tester) async {
      await pumpCardio(tester, notStarted);
      expect(find.text('Treadmill run'), findsOneWidget);
      expect(find.text('CARDIO'), findsOneWidget);
      expect(find.text('ACTIVE TIME'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('Tap Start when you begin'), findsOneWidget);
      expect(find.text('Start new lap'), findsNothing);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('End exercise'), findsOneWidget);
    });

    testWidgets('there is no status text above the name', (tester) async {
      await pumpCardio(tester, oneLap);
      expect(find.textContaining('Running'), findsNothing);
      expect(find.textContaining('In progress'), findsNothing);
    });

    testWidgets('running with one lap shows no lap wording', (tester) async {
      await pumpCardio(tester, oneLap);
      expect(find.text('10:12'), findsOneWidget);
      expect(find.text('Start new lap'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.textContaining('Lap '), findsNothing);
      expect(find.textContaining(' laps'), findsNothing);
    });

    testWidgets('running with two laps lists them', (tester) async {
      await pumpCardio(tester, twoLaps);
      expect(find.text('11:47'), findsOneWidget);
      expect(find.text('Lap 1'), findsOneWidget);
      expect(find.text('Lap 2'), findsOneWidget);
      expect(find.text('10:12'), findsOneWidget);
      expect(find.text('01:35'), findsOneWidget);
      expect(find.text('2 laps'), findsOneWidget);
      expect(find.textContaining('Resume carries'), findsNothing);
    });

    testWidgets('paused with one lap shows only the pause', (tester) async {
      await pumpCardio(tester, pausedOneLap);
      expect(find.text('Paused for 00:42'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Start new lap'), findsOneWidget);
      expect(find.textContaining('Resume carries'), findsNothing);
      expect(find.textContaining('Lap '), findsNothing);
    });

    testWidgets('paused with two laps shows the hint and footer',
        (tester) async {
      await pumpCardio(tester, pausedTwoLaps);
      expect(find.text('19:12'), findsOneWidget);
      expect(find.text('Resume carries on with lap 2'), findsOneWidget);
      expect(find.text('2 laps'), findsOneWidget);
      expect(find.text('Paused for 00:42'), findsOneWidget);
    });

    for (final (exercise, label, action) in [
      (notStarted, 'Start', 'start'),
      (oneLap, 'Pause', 'pause'),
      (pausedTwoLaps, 'Resume', 'resume'),
    ]) {
      testWidgets('$label drives the timer', (tester) async {
        final workout = await pumpCardio(tester, exercise);
        await tester.tap(find.text(label));
        expect(workout.cardioActions, [action]);
      });
    }

    for (final (exercise, state) in [
      (oneLap, 'running'),
      (pausedOneLap, 'paused'),
    ]) {
      testWidgets('Start new lap works while $state', (tester) async {
        final workout = await pumpCardio(tester, exercise);
        await tester.tap(find.text('Start new lap'));
        expect(workout.cardioActions, ['lap']);
      });
    }

    testWidgets('End exercise ends it', (tester) async {
      final workout = await pumpCardio(tester, oneLap);
      await tester.tap(find.text('End exercise'));
      expect(workout.spy.endedExercises, 1);
    });

    testWidgets('the time moves on with the clock', (tester) async {
      var clock = now;
      await pumpApp(
        tester,
        const SingleChildScrollView(child: CurrentWorkoutArea()),
        overrides: [
          currentWorkoutProvider.overrideWith(
            () => FakeWorkoutNotifier(
              startedAt: ago(1340),
              currentExercise: oneLap,
            ),
          ),
          clockProvider.overrideWithValue(() => clock),
        ],
      );
      expect(find.text('10:12'), findsOneWidget);
      clock = clock.add(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('10:15'), findsOneWidget);
    });
  });

  test('times switch to hours at an hour', () {
    expect(formatActiveTime(const Duration(seconds: 59)), '00:59');
    expect(formatActiveTime(const Duration(minutes: 59, seconds: 59)), '59:59');
    expect(formatActiveTime(const Duration(hours: 1, seconds: 9)), '1:00:09');
  });

  group('finished cardio', () {
    Future<void> pumpDone(WidgetTester tester, Exercise exercise,
        {bool open = false}) {
      return pumpApp(
        tester,
        CompletedExerciseCard(exercise: exercise, open: open, onTap: () {}),
      );
    }

    testWidgets('shows its time in place of volume', (tester) async {
      await pumpDone(tester, finished([612, 540]));
      expect(find.text('Cardio · 2 laps'), findsOneWidget);
      expect(find.text('19:12'), findsOneWidget);
      expect(find.text('time'), findsOneWidget);
      expect(find.text('kg vol'), findsNothing);
    });

    testWidgets('with one lap it just says Cardio', (tester) async {
      await pumpDone(tester, finished([612]));
      expect(find.text('Cardio'), findsOneWidget);
      expect(find.text('10:12'), findsOneWidget);
    });

    testWidgets('opened, it lists two or more laps', (tester) async {
      await pumpDone(tester, finished([612, 540]), open: true);
      expect(find.byType(CompactLapRow), findsNWidgets(2));
      expect(find.text('Lap 2'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.textContaining('TOP SET'), findsNothing);
    });

    testWidgets('opened with one lap, nothing extra shows', (tester) async {
      await pumpDone(tester, finished([612]), open: true);
      expect(find.byType(CompactLapRow), findsNothing);
      expect(find.textContaining('TOP SET'), findsNothing);
    });

    testWidgets('a strength exercise shows each set in its own unit',
        (tester) async {
      await pumpDone(
        tester,
        Exercise(
          'Row',
          {
            1: ExerciseSet(60, 5, 1),
            2: ExerciseSet(135, 5, 2, unit: WeightUnit.lb),
          },
          3,
          now,
        )..setEndTime(now),
        open: true,
      );
      expect(find.text('60 kg'), findsOneWidget);
      expect(find.text('135 lb'), findsOneWidget);
      // 135 lb is 61.2 kg, so it is the top set.
      expect(find.text('TOP SET 135 LB × 5'), findsOneWidget);
      // (60 + 61.2) × 5 ÷ 10 reps, in kg.
      expect(find.text('AVG 60.6 KG'), findsOneWidget);
    });
  });

  group('recorded workouts', () {
    Workout mixed() {
      final bench = Exercise('Bench press', {1: ExerciseSet(60, 8, 1)}, 2, now)
        ..setEndTime(now);
      final run = finished([612, 540]);
      return Workout(
        testId(1),
        ago(3600),
        now,
        {bench.id: bench, run.id: run},
        title: 'Mixed',
      );
    }

    testWidgets('the summary leaves cardio out of the volume bars',
        (tester) async {
      await pumpApp(
        tester,
        WorkoutSummaryScreen(workout: mixed()),
        overrides: [
          pastWorkoutsProvider.overrideWith(FakePastWorkoutsNotifier.new),
          workoutSyncProvider.overrideWith(FakeWorkoutSyncNotifier.new),
        ],
      );
      expect(find.text('Bench press'), findsOneWidget);
      expect(find.text('Treadmill run'), findsNothing);
      expect(find.text('2'), findsOneWidget); // EXERCISES
    });

    testWidgets('a cardio-only summary has no volume card', (tester) async {
      final run = finished([612]);
      await pumpApp(
        tester,
        WorkoutSummaryScreen(
          workout: Workout(testId(1), ago(700), now, {run.id: run}),
        ),
        overrides: [
          pastWorkoutsProvider.overrideWith(FakePastWorkoutsNotifier.new),
          workoutSyncProvider.overrideWith(FakeWorkoutSyncNotifier.new),
        ],
      );
      expect(find.text('VOLUME BY EXERCISE'), findsNothing);
    });

    testWidgets('the detail screen shows laps and the active time',
        (tester) async {
      await pumpApp(
        tester,
        WorkoutDetailScreen(workoutId: testId(1), onClose: () {}),
        overrides: [
          pastWorkoutsProvider
              .overrideWith(() => FakePastWorkoutsNotifier([mixed()])),
          workoutSyncProvider.overrideWith(FakeWorkoutSyncNotifier.new),
        ],
      );
      await tester.scrollUntilVisible(find.text('Lap 2'), 100);
      expect(find.byType(CompactLapRow), findsNWidgets(2));
      expect(find.text('19m 12s'), findsOneWidget);
    });
  });
}
