import 'package:flutter_test/flutter_test.dart';
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
    expect(exercise?.sets[3]?.weight, '100');
    expect(exercise?.sets[3]?.reps, '5');
  });
}
