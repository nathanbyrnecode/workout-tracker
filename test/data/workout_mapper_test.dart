import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';

void main() {
  test('unfinished workouts never enter history even if supplied by the server',
      () {
    final workouts = mapWorkoutRows(
      workoutRows: [
        {'id': 1, 'start_time': '2026-07-25T09:00:00Z', 'end_time': null},
        {
          'id': 2,
          'start_time': '2026-07-25T09:00:00Z',
          'end_time': '2026-07-25T10:00:00Z'
        },
      ],
      exerciseRows: [],
      setRows: [],
    );
    expect(workouts.map((workout) => workout.id).toList(), [2]);
  });
  test('maps Supabase workout rows into the existing workout model', () {
    final workouts = mapWorkoutRows(
      workoutRows: [
        {
          'id': 1,
          'start_time': '2026-07-25T09:00:00Z',
          'end_time': '2026-07-25T10:00:00Z',
        },
      ],
      exerciseRows: [
        {
          'id': 2,
          'workout_id': 1,
          'name': 'Squat',
          'start_time': '2026-07-25T09:05:00Z',
          'end_time': '2026-07-25T09:20:00Z',
        },
      ],
      setRows: [
        {
          'id': 3,
          'exercise_id': 2,
          'weight': 100.0,
          'reps': 5,
        },
      ],
    );

    expect(workouts, hasLength(1));
    expect(workouts.single.id, 1);
    expect(workouts.single.startTime?.toUtc(), DateTime.utc(2026, 7, 25, 9));
    expect(workouts.single.endTime?.toUtc(), DateTime.utc(2026, 7, 25, 10));

    final exercise = workouts.single.exercises[2];
    expect(exercise?.name, 'Squat');
    expect(exercise?.sets[3]?.weight, 100);
    expect(exercise?.sets[3]?.reps, 5);
  });

  test('maps title, location and set timestamps', () {
    final workouts = mapWorkoutRows(
      workoutRows: [
        {
          'id': 1,
          'start_time': '2026-07-25T09:00:00Z',
          'end_time': '2026-07-25T10:00:00Z',
          'title': 'Push day',
          'location_type': 'Park',
          'place_name': 'Mayfield Park',
          'place_address': 'Baring St, Manchester M1 2PY',
          'place_lat': 53.4751,
          'place_lng': -2.2262,
        },
      ],
      exerciseRows: [
        {
          'id': 2,
          'workout_id': 1,
          'name': 'Squat',
          'start_time': '2026-07-25T09:05:00Z',
          'end_time': '2026-07-25T09:20:00Z',
        },
      ],
      setRows: [
        {
          'id': 3,
          'exercise_id': 2,
          'weight': 82.5,
          'reps': 5,
          'created_at': '2026-07-25T09:06:30Z',
        },
      ],
    );

    final workout = workouts.single;
    expect(workout.title, 'Push day');
    expect(workout.displayTitle, 'Push day');
    expect(workout.locationType, LocationType.park);
    expect(workout.place?.name, 'Mayfield Park');
    expect(workout.place?.address, 'Baring St, Manchester M1 2PY');
    expect(workout.place?.lat, 53.4751);
    expect(workout.place?.lng, -2.2262);

    final set = workout.exercises[2]?.sets[3];
    expect(set?.weight, 82.5);
    expect(set?.savedAt?.toUtc(), DateTime.utc(2026, 7, 25, 9, 6, 30));
  });

  test('a workout with a type but no place has a null place', () {
    final workout = mapWorkoutRows(
      workoutRows: [
        {
          'id': 1,
          'start_time': '2026-07-25T09:00:00Z',
          'end_time': '2026-07-25T10:00:00Z',
          'title': 'Legs',
          'location_type': 'Home',
          'place_name': null,
          'place_address': null,
          'place_lat': null,
          'place_lng': null,
        },
      ],
      exerciseRows: [],
      setRows: [],
    ).single;

    expect(workout.locationType, LocationType.home);
    expect(workout.place, isNull);
  });

  test('legacy rows with no title or location fall back for display', () {
    final workouts = mapWorkoutRows(
      workoutRows: [
        {
          'id': 1,
          'start_time': '2026-07-25T09:00:00Z',
          'end_time': '2026-07-25T10:00:00Z',
        },
        {
          'id': 2,
          'start_time': '2026-07-26T09:00:00Z',
          'end_time': '2026-07-26T10:00:00Z',
          'title': '  ',
          'location_type': 'Somewhere else',
        },
      ],
      exerciseRows: [
        {
          'id': 2,
          'workout_id': 1,
          'name': 'Squat',
          'start_time': '2026-07-25T09:05:00Z',
          'end_time': '2026-07-25T09:20:00Z',
        },
      ],
      setRows: [
        {'id': 3, 'exercise_id': 2, 'weight': 100, 'reps': 5},
      ],
    );

    for (final workout in workouts) {
      expect(workout.locationType, isNull);
      expect(workout.place, isNull);
      expect(workout.displayTitle, 'Workout');
      expect(workout.displayLocationType, LocationType.gym);
    }
    expect(workouts.first.title, isNull);
    expect(workouts.first.exercises[2]?.sets[3]?.savedAt, isNull);
  });

  test('sets come out in set order even when the rows arrive newest first',
      () {
    final workout = mapWorkoutRows(
      workoutRows: [
        {
          'id': 1,
          'start_time': '2026-10-31T12:50:00Z',
          'end_time': '2026-10-31T14:10:00Z',
        },
      ],
      exerciseRows: [
        {
          'id': 2,
          'workout_id': 1,
          'name': 'Bench Press',
          'start_time': '2026-10-31T12:52:00Z',
          'end_time': '2026-10-31T13:18:00Z',
        },
      ],
      setRows: [
        {'id': 7, 'exercise_id': 2, 'set_number': 2, 'weight': 80, 'reps': 8},
        {'id': 6, 'exercise_id': 2, 'set_number': 1, 'weight': 60, 'reps': 8},
        {'id': 5, 'exercise_id': 2, 'set_number': 0, 'weight': 60, 'reps': 10},
      ],
    ).single;

    final sets = workout.exercises[2]!.sets.values.toList();
    expect(sets.map((set) => set.id).toList(), [5, 6, 7]);
    expect(sets.first.reps, 10);
  });

  test('sets without a set number fall back to id order', () {
    final workout = mapWorkoutRows(
      workoutRows: [
        {
          'id': 1,
          'start_time': '2026-07-25T09:00:00Z',
          'end_time': '2026-07-25T10:00:00Z',
        },
      ],
      exerciseRows: [
        {
          'id': 2,
          'workout_id': 1,
          'name': 'Squat',
          'start_time': '2026-07-25T09:05:00Z',
          'end_time': '2026-07-25T09:20:00Z',
        },
      ],
      setRows: [
        {'id': 4, 'exercise_id': 2, 'weight': 100, 'reps': 3},
        {'id': 3, 'exercise_id': 2, 'weight': 100, 'reps': 5},
      ],
    ).single;

    expect(workout.exercises[2]!.sets.keys.toList(), [3, 4]);
  });

  test('exercises come out in the order they were started', () {
    final workout = mapWorkoutRows(
      workoutRows: [
        {
          'id': 1,
          'start_time': '2026-07-25T09:00:00Z',
          'end_time': '2026-07-25T10:00:00Z',
        },
      ],
      exerciseRows: [
        {
          'id': 3,
          'workout_id': 1,
          'name': 'Dips',
          'start_time': '2026-07-25T09:30:00Z',
          'end_time': '2026-07-25T09:40:00Z',
        },
        {
          'id': 2,
          'workout_id': 1,
          'name': 'Bench Press',
          'start_time': '2026-07-25T09:05:00Z',
          'end_time': '2026-07-25T09:25:00Z',
        },
      ],
      setRows: [],
    ).single;

    expect(
      workout.exercises.values.map((exercise) => exercise.name).toList(),
      ['Bench Press', 'Dips'],
    );
  });
}
