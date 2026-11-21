import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/local_workout_store.dart';
import 'package:gym_tracker_app/data/supabase_client_provider.dart';
import 'package:gym_tracker_app/data/tracker_stats.dart';
import 'package:gym_tracker_app/data/workout_json.dart';
import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/models/cardio_timer.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/util/date_format.dart';
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fakes.dart';

void main() {
  late SupabaseClient client;
  late ProviderContainer container;
  late MemoryWorkoutStore store;
  late DateTime now;

  ProviderContainer newContainer() => ProviderContainer(overrides: [
        supabaseClientProvider.overrideWithValue(client),
        localWorkoutStoreProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => now),
      ]);

  setUp(() async {
    now = DateTime(2026, 11, 21, 9);
    store = MemoryWorkoutStore();
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      // No signal: uploads fail and workouts stay on the device.
      httpClient: MockClient(
        (_) async => throw const SocketException('No route to host'),
      ),
    );
    await client.auth.recoverSession(jsonEncode({
      'access_token': 'test-token',
      'token_type': 'bearer',
      'user': {
        'id': 'user-a',
        'app_metadata': {},
        'user_metadata': {},
        'aud': 'authenticated',
        'created_at': '2026-01-01T00:00:00Z',
      },
    }));
    container = newContainer();
  });

  tearDown(() async {
    container.dispose();
    await client.dispose();
  });

  CurrentWorkoutNotifier notifier() =>
      container.read(currentWorkoutProvider.notifier);
  CurrentWorkoutStateData state() => container.read(currentWorkoutProvider);
  void wait(int seconds) => now = now.add(Duration(seconds: seconds));

  Future<void> addCardio() async {
    await notifier().restoreActiveWorkout();
    await notifier().startWorkout();
    await notifier().startExercise('Treadmill run', type: ExerciseType.cardio);
  }

  Future<EndWorkoutResult> endWorkout() =>
      notifier().endWorkout(title: 'Run', locationType: LocationType.gym);

  test('adding a cardio exercise does not start the timer', () async {
    await addCardio();
    wait(30);
    final exercise = state().currentExercise!;
    expect(exercise.isCardio, isTrue);
    expect(exercise.cardio.status, CardioStatus.notStarted);
    expect(exercise.cardio.activeTime(now), Duration.zero);
  });

  test('start, pause and resume leave the pause out of the time', () async {
    await addCardio();
    await notifier().startCardio();
    expect(state().currentExercise!.cardio.status, CardioStatus.running);
    wait(60);
    await notifier().pauseCardio();
    expect(state().currentExercise!.cardio.status, CardioStatus.paused);
    wait(300);
    await notifier().resumeCardio();
    wait(40);
    expect(
      state().currentExercise!.cardio.activeTime(now),
      const Duration(seconds: 100),
    );
  });

  test('a new lap works while running', () async {
    await addCardio();
    await notifier().startCardio();
    wait(612);
    await notifier().startNewLap();
    wait(95);
    expect(state().currentExercise!.cardio.lapSeconds(now), [612, 95]);
  });

  test('a new lap works while paused, and resumes', () async {
    await addCardio();
    await notifier().startCardio();
    wait(612);
    await notifier().pauseCardio();
    wait(42);
    await notifier().startNewLap();
    wait(10);
    final timer = state().currentExercise!.cardio;
    expect(timer.status, CardioStatus.running);
    expect(timer.lapSeconds(now), [612, 10]);
  });

  test('cardio actions do nothing on a strength exercise', () async {
    await notifier().restoreActiveWorkout();
    await notifier().startWorkout();
    await notifier().startExercise('Squat');
    await notifier().startCardio();
    expect(state().currentExercise!.cardio.laps, isEmpty);
  });

  group('ending the exercise', () {
    test('with no time removes it', () async {
      await addCardio();
      wait(30);
      await notifier().endExercise();
      expect(state().currentExercise, isNull);
      expect(state().exercises, isEmpty);
    });

    test('started but under a second removes it', () async {
      await addCardio();
      await notifier().startCardio();
      now = now.add(const Duration(milliseconds: 400));
      await notifier().endExercise();
      expect(state().exercises, isEmpty);
    });

    test('keeps the active time and the laps', () async {
      await addCardio();
      await notifier().startCardio();
      wait(612);
      await notifier().startNewLap();
      wait(540);
      await notifier().pauseCardio();
      wait(42);
      await notifier().endExercise();

      final done = state().exercises.single;
      expect(state().currentExercise, isNull);
      expect(done.isCardio, isTrue);
      expect(done.endTime, now);
      expect(done.cardio.status, isNot(CardioStatus.running));
      expect(done.activeTime, const Duration(minutes: 19, seconds: 12));
      expect(done.cardio.lapSeconds(now), [612, 540]);
    });
  });

  group('ending the workout while cardio is active', () {
    test('saves the running cardio with the time so far', () async {
      await addCardio();
      await notifier().startCardio();
      wait(300);

      final result = await endWorkout();

      expect(result.outcome, EndWorkoutOutcome.savedLocally);
      final saved = result.workout!.exercises.values.single;
      expect(saved.isCardio, isTrue);
      expect(saved.activeTime, const Duration(minutes: 5));
      expect(state().isInProgress, isFalse);

      final pending = store.pendingFor('user-a').values.single;
      final exercise = (pending['exercises'] as List).single as Map;
      expect(exercise['type'], 'cardio');
      expect(exercise['lap_seconds'], [300]);
      expect(exercise.containsKey('cardio_timer'), isFalse);
    });

    test('drops a cardio with no time but keeps the rest', () async {
      await notifier().restoreActiveWorkout();
      await notifier().startWorkout();
      await notifier().startExercise('Squat');
      await notifier().addSet(weight: 100, reps: 5);
      await notifier().endExercise();
      await notifier()
          .startExercise('Treadmill run', type: ExerciseType.cardio);

      final result = await endWorkout();

      expect(
        result.workout!.exercises.values.map((e) => e.name),
        ['Squat'],
      );
    });

    test('with only a cardio with no time, nothing is kept', () async {
      await addCardio();
      final result = await endWorkout();
      expect(result.outcome, EndWorkoutOutcome.discarded);
      expect(store.pendingFor('user-a'), isEmpty);
    });
  });

  group('after the app is killed', () {
    Future<void> restart() async {
      container.dispose();
      container = newContainer();
      await notifier().restoreActiveWorkout();
    }

    test('a running timer has kept counting', () async {
      await addCardio();
      await notifier().startCardio();
      wait(120);
      await notifier().startNewLap();
      wait(30);

      await restart();
      wait(30);

      final timer = state().currentExercise!.cardio;
      expect(timer.status, CardioStatus.running);
      expect(timer.lapSeconds(now), [120, 60]);
    });

    test('a paused timer is still paused, with its pause time', () async {
      await addCardio();
      await notifier().startCardio();
      wait(120);
      await notifier().pauseCardio();

      wait(600);
      await restart();

      final timer = state().currentExercise!.cardio;
      expect(timer.status, CardioStatus.paused);
      expect(timer.activeTime(now), const Duration(minutes: 2));
      expect(timer.pausedFor(now), const Duration(minutes: 10));
    });

    test('a timer not started yet is still not started', () async {
      await addCardio();
      wait(600);
      await restart();
      expect(
        state().currentExercise!.cardio.status,
        CardioStatus.notStarted,
      );
    });

    test('past 12 hours, only time up to the last tap is kept', () async {
      await addCardio();
      await notifier().startCardio();
      wait(600);
      await notifier().startNewLap();
      final lastTap = now;
      wait(13 * 3600);

      container.dispose();
      container = newContainer();
      final ended = await notifier().restoreActiveWorkout();

      final saved = ended!.exercises.values.single;
      expect(saved.cardio.lapSeconds(now), [600]);
      expect(saved.endTime, lastTap);
      expect(ended.endTime, lastTap);
    });

    test('past 12 hours, a timer on its first stretch is dropped', () async {
      await addCardio();
      await notifier().startCardio();
      wait(13 * 3600);

      container.dispose();
      container = newContainer();
      expect(await notifier().restoreActiveWorkout(), isNull);
      expect(store.pendingFor('user-a'), isEmpty);
    });
  });

  group('storage', () {
    final start = DateTime.utc(2026, 11, 21, 9);

    test('a finished workout round-trips its type and laps', () {
      final run = Exercise(
        'Run',
        {},
        1,
        start,
        type: ExerciseType.cardio,
        cardio: CardioTimer.fromLapSeconds(const [612, 540]),
      )..setEndTime(start.add(const Duration(minutes: 20)));
      final json = encodeWorkout(
        Workout('w', start, start.add(const Duration(hours: 1)), {1: run}),
        userId: 'u',
      );
      final decoded = decodeWorkout(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      ).exercises[1]!;
      expect(decoded.isCardio, isTrue);
      expect(decoded.activeTime, const Duration(minutes: 19, seconds: 12));
      expect(decoded.cardio.laps, hasLength(2));
    });

    test('an exercise from before types is strength with no laps', () {
      final json = {
        'version': workoutJsonVersion,
        'user_id': 'u',
        'id': 'w',
        'start_time': start.toIso8601String(),
        'end_time': start.toIso8601String(),
        'exercises': [
          {
            'id': 1,
            'name': 'Squat',
            'start_time': start.toIso8601String(),
            'end_time': start.toIso8601String(),
            'sets': const [],
          },
        ],
      };
      final exercise = decodeWorkout(json).exercises[1]!;
      expect(exercise.type, ExerciseType.strength);
      expect(exercise.cardio.laps, isEmpty);
    });

    test('server rows carry the type and laps', () {
      final workouts = mapWorkoutRows(
        workoutRows: [
          {
            'id': 'w',
            'start_time': start.toIso8601String(),
            'end_time': start.toIso8601String(),
          },
        ],
        exerciseRows: [
          {
            'id': 1,
            'workout_id': 'w',
            'name': 'Run',
            'start_time': start.toIso8601String(),
            'end_time': start.toIso8601String(),
            'type': 'cardio',
            'lap_seconds': [612, 540],
          },
          {
            'id': 2,
            'workout_id': 'w',
            'name': 'Squat',
            'start_time': start.toIso8601String(),
            'end_time': start.toIso8601String(),
          },
        ],
        setRows: const [],
      );
      final exercises = workouts.single.exercises;
      expect(exercises[1]!.isCardio, isTrue);
      expect(exercises[1]!.activeTime, const Duration(seconds: 1152));
      expect(exercises[2]!.type, ExerciseType.strength);
    });
  });

  group('totals', () {
    final start = DateTime(2026, 11, 21, 9);
    Exercise run() => Exercise(
          'Run',
          {},
          1,
          start,
          type: ExerciseType.cardio,
          cardio: CardioTimer.fromLapSeconds(const [600]),
        )..setEndTime(start);

    test('cardio counts as an exercise but adds no sets, reps or volume', () {
      final squat = Exercise('Squat', {2: ExerciseSet(100, 5, 2)}, 3, start);
      final totals = workoutTotals([squat, run()]);
      expect(totals.exercises, 2);
      expect(totals.sets, 1);
      expect(totals.reps, 5);
      expect(totals.volume, 500);
    });

    test('a cardio-only workout still counts on the Tracker', () {
      final days = buildTrackerDays(
        workouts: [
          Workout('w', start, start, {1: run()}),
        ],
        manualWorkouts: const [],
      );
      expect(days[dayOf(start)], hasLength(1));
      expect(heatLevel(days[dayOf(start)]), 2);
    });

    test('a live workout counts once its cardio timer has started', () {
      final notCounted = buildTrackerDays(
        workouts: const [],
        manualWorkouts: const [],
        liveStart: start,
        liveTotals: workoutTotals(const []),
      );
      expect(notCounted, isEmpty);

      final counted = buildTrackerDays(
        workouts: const [],
        manualWorkouts: const [],
        liveStart: start,
        liveTotals: workoutTotals([run()]),
        liveHasCardio: true,
      );
      expect(counted[dayOf(start)], hasLength(1));
    });
  });
}
