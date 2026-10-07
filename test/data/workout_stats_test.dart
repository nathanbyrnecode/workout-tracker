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

  group('top set', () {
    test('is the heaviest set', () {
      final top = topSet(exercise(1, [(60, 8), (70, 6), (65, 6)]).sets.values);
      expect((top?.weight, top?.reps), (70, 6));
    });

    test('more reps breaks a tie on weight', () {
      final top = topSet(exercise(1, [(70, 5), (70, 8), (70, 6)]).sets.values);
      expect((top?.weight, top?.reps), (70, 8));
    });

    test('the first of two identical sets wins', () {
      final sets = exercise(1, [(70, 6), (70, 6)]).sets.values;
      expect(topSet(sets), same(sets.first));
    });

    test('is null with no sets', () {
      expect(topSet(const []), isNull);
    });
  });

  group('average weight', () {
    test('is volume divided by total reps, to one decimal place', () {
      // The design's example: 60×8, 65×6, 70×6 → 1,290 ÷ 20 = 64.5.
      expect(
        averageWeight(exercise(1, [(60, 8), (65, 6), (70, 6)]).sets.values),
        64.5,
      );
      // 100×3 + 50×4 = 500 ÷ 7 = 71.428… → 71.4.
      expect(
        averageWeight(exercise(1, [(100, 3), (50, 4)]).sets.values),
        71.4,
      );
    });

    test('is zero with no sets or no reps', () {
      expect(averageWeight(const []), 0);
      expect(averageWeight(exercise(1, [(60, 0)]).sets.values), 0);
    });
  });

  group('rest timer start', () {
    test('is when the last set was saved', () {
      final saved = DateTime(2026, 10, 7, 9, 30);
      expect(
        lastSetSavedAt([
          ExerciseSet(60, 8, 1, savedAt: DateTime(2026, 10, 7, 9, 20)),
          ExerciseSet(65, 6, 2, savedAt: saved),
        ]),
        saved,
      );
    });

    test('is null with no sets or an untimed last set', () {
      expect(lastSetSavedAt(const []), isNull);
      expect(
        lastSetSavedAt([
          ExerciseSet(60, 8, 1, savedAt: DateTime(2026, 10, 7, 9, 20)),
          ExerciseSet(65, 6, 2),
        ]),
        isNull,
      );
    });
  });
}
