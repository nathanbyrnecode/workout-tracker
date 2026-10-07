import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';

Exercise exercise(int id, List<(double, int)> sets) => Exercise(
      'Exercise $id',
      {
        for (var i = 0; i < sets.length; i++)
          id * 100 + i: ExerciseSet(sets[i].$1, sets[i].$2, id * 100 + i),
      },
      id,
      DateTime(2026, 10, 7, 9),
    );

void main() {
  test('an empty workout totals zero', () {
    expect(workoutTotals([]), (exercises: 0, sets: 0, reps: 0, volume: 0.0));
  });

  test('totals count exercises, sets and reps and sum weight × reps', () {
    // The design's demo workout: 2 exercises, 5 sets, 1,732 kg.
    final totals = workoutTotals([
      exercise(1, [(60, 8), (65, 6), (70, 6)]),
      exercise(2, [(22, 10), (24, 8)]),
    ]);
    expect(totals.exercises, 2);
    expect(totals.sets, 5);
    expect(totals.reps, 38);
    expect(totals.volume, 60 * 8 + 65 * 6 + 70 * 6 + 22 * 10 + 24 * 8);
    expect(totals.volume, 1702);
  });

  test('an exercise with no sets still counts as an exercise', () {
    final totals = workoutTotals([exercise(1, [])]);
    expect(totals, (exercises: 1, sets: 0, reps: 0, volume: 0.0));
  });

  test('fractional weights keep their fraction', () {
    expect(setsVolume(exercise(1, [(22.5, 3)]).sets.values), 67.5);
  });
}
