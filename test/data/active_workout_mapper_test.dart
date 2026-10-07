import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';

Map<String, dynamic> savedWorkout({String? endTime}) => {
      'id': 42,
      'start_time': '2026-09-30T09:00:00Z',
      'end_time': endTime,
      'exercises': [
        {
          'id': 20,
          'name': 'Bench press',
          'start_time': '2026-09-30T09:20:00Z',
          'end_time': null,
          'exercise_sets': [
            {'id': 102, 'set_number': 1, 'weight': 82.5, 'reps': 6},
            {'id': 103, 'set_number': 0, 'weight': 80.0, 'reps': 8},
          ],
        },
        {
          'id': 10,
          'name': 'Squat',
          'start_time': '2026-09-30T09:05:00Z',
          'end_time': '2026-09-30T09:15:00Z',
          'exercise_sets': [
            {
              'id': 100,
              'set_number': 0,
              'weight': 100.0,
              'reps': 5,
              'created_at': '2026-09-30T09:10:00Z',
            },
          ],
        },
      ],
    };

void main() {
  final now = DateTime.utc(2026, 9, 30, 17);

  test('restores completed and active exercises, saved set order and timers',
      () {
    final state = mapActiveWorkoutRow(savedWorkout(), now: now);
    expect(state.recoveryStatus, WorkoutRecoveryStatus.ready);
    expect(state.isInProgress, isTrue);
    expect(state.workoutId, 42);
    expect(state.workoutStartDateTime?.toUtc(), DateTime.utc(2026, 9, 30, 9));
    expect(
        now.difference(state.workoutStartDateTime!), const Duration(hours: 8));
    expect(state.exercises.single.name, 'Squat');
    expect(state.exercises.single.endTime?.toUtc(),
        DateTime.utc(2026, 9, 30, 9, 15));
    expect(state.exercises.single.sets[100]?.weight, 100);
    final active = state.currentExercise!;
    expect(active.id, 20);
    expect(active.endTime, isNull);
    expect(active.startTime.toUtc(), DateTime.utc(2026, 9, 30, 9, 20));
    expect(active.sets.keys.toList(), [103, 102]);
    expect(active.sets[102]?.weight, 82.5);
    expect(active.sets[103]?.reps, 8);
    expect(state.exercises.single.sets[100]?.savedAt?.toUtc(),
        DateTime.utc(2026, 9, 30, 9, 10));
    // Sets saved before timestamps existed have none.
    expect(active.sets[102]?.savedAt, isNull);
  });

  test('does not resume a completed latest workout', () {
    final state = mapActiveWorkoutRow(
      savedWorkout(endTime: '2026-09-30T10:00:00Z'),
      now: now,
    );
    expect(state.isInProgress, isFalse);
    expect(state.workoutId, isNull);
    expect(state.recoveryStatus, WorkoutRecoveryStatus.ready);
  });

  test('strictly excludes workouts at or beyond 12 hours', () {
    for (final age in [const Duration(hours: 12), const Duration(hours: 13)]) {
      expect(
          mapActiveWorkoutRow(savedWorkout(),
                  now: DateTime.utc(2026, 9, 30, 9).add(age))
              .isInProgress,
          isFalse);
    }
    expect(
        mapActiveWorkoutRow(savedWorkout(),
                now: DateTime.utc(2026, 9, 30, 21)
                    .subtract(const Duration(microseconds: 1)))
            .isInProgress,
        isTrue);
  });

  test('ignores missing, invalid and future start timestamps', () {
    expect(mapActiveWorkoutRow(null, now: now).isInProgress, isFalse);
    for (final start in [null, 'invalid', '2026-09-30T18:00:00Z']) {
      final row = savedWorkout()..['start_time'] = start;
      expect(mapActiveWorkoutRow(row, now: now).isInProgress, isFalse);
    }
  });

  test('compares timestamps by instant across time zones', () {
    final row = savedWorkout()..['start_time'] = '2026-09-30T10:00:00+01:00';
    expect(mapActiveWorkoutRow(row, now: now).workoutStartDateTime?.toUtc(),
        DateTime.utc(2026, 9, 30, 9));
  });

  test('restores a workout with no exercises and an exercise with no sets', () {
    final row = savedWorkout()..['exercises'] = <Map<String, dynamic>>[];
    final emptyWorkout = mapActiveWorkoutRow(row, now: now);
    expect(emptyWorkout.isInProgress, isTrue);
    expect(emptyWorkout.currentExercise, isNull);
    row['exercises'] = [
      {
        'id': 20,
        'name': 'Bench press',
        'start_time': '2026-09-30T09:20:00Z',
        'end_time': null,
        'exercise_sets': <Map<String, dynamic>>[]
      },
    ];
    expect(mapActiveWorkoutRow(row, now: now).currentExercise?.sets, isEmpty);
  });

  test('restores completed exercises in chronological order', () {
    final row = savedWorkout();
    final exercises = row['exercises'] as List;
    exercises.first['end_time'] = '2026-09-30T09:30:00Z';
    final state = mapActiveWorkoutRow(row, now: now);
    expect(state.exercises.map((e) => e.id).toList(), [10, 20]);
    expect(state.currentExercise, isNull);
  });

  test('fails visibly rather than losing data from an invalid active exercise',
      () {
    final row = savedWorkout();
    final exercises = row['exercises'] as List;
    exercises[1] = <String, dynamic>{...exercises.last, 'end_time': null};
    expect(() => mapActiveWorkoutRow(row, now: now), throwsFormatException);
  });
}
