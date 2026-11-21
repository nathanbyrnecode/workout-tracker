import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/workout_history.dart';
import 'package:gym_tracker_app/data/workout_json.dart';
import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/models/weight_unit.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';

void main() {
  group('converting', () {
    test('kg to lb rounds to the nearest 0.5', () {
      expect(WeightUnit.kg.convert(24, WeightUnit.lb), 53);
      expect(WeightUnit.kg.convert(20, WeightUnit.lb), 44);
      expect(WeightUnit.kg.convert(60, WeightUnit.lb), 132.5);
      expect(WeightUnit.kg.convert(0, WeightUnit.lb), 0);
    });

    test('lb to kg rounds to the nearest 0.5', () {
      expect(WeightUnit.lb.convert(53, WeightUnit.kg), 24);
      expect(WeightUnit.lb.convert(46, WeightUnit.kg), 21);
      expect(WeightUnit.lb.convert(135, WeightUnit.kg), 61);
    });

    test('to the same unit leaves the value alone', () {
      expect(WeightUnit.kg.convert(62.3, WeightUnit.kg), 62.3);
      expect(WeightUnit.lb.convert(53.2, WeightUnit.lb), 53.2);
    });

    test('toKg is exact, because volume is worked out from it', () {
      expect(WeightUnit.kg.toKg(60), 60);
      expect(WeightUnit.lb.toKg(220.462), closeTo(100, 1e-9));
    });

    test('steps are 2.5 kg and 5 lb', () {
      expect(WeightUnit.kg.step, 2.5);
      expect(WeightUnit.lb.step, 5);
    });

    test('a stored unit reads back, and a missing one is kg', () {
      expect(WeightUnit.fromName('lb'), WeightUnit.lb);
      expect(WeightUnit.fromName('kg'), WeightUnit.kg);
      expect(WeightUnit.fromName(null), WeightUnit.kg);
    });
  });

  group('volume with mixed units', () {
    final sets = [
      ExerciseSet(100, 5, 1),
      ExerciseSet(220.462, 2, 2, unit: WeightUnit.lb),
    ];

    test('is always in kg', () {
      expect(setsVolume(sets), closeTo(700, 1e-6));
    });

    test('totals convert lb sets', () {
      final exercise = Exercise(
        'Squat',
        {for (final set in sets) set.id: set},
        1,
        DateTime(2026),
      );
      final totals = workoutTotals([exercise]);
      expect(totals.sets, 2);
      expect(totals.reps, 7);
      expect(totals.volume, closeTo(700, 1e-6));
    });

    test('the top set compares in kg and keeps its own unit', () {
      final top = topSet([
        ExerciseSet(100, 5, 1),
        ExerciseSet(225, 3, 2, unit: WeightUnit.lb),
        ExerciseSet(135, 8, 3, unit: WeightUnit.lb),
      ])!;
      expect(top.weight, 225);
      expect(top.unit, WeightUnit.lb);
    });

    test('the average is in kg', () {
      expect(averageWeight(sets), closeTo(100, 0.05));
    });
  });

  group('the unit a first set starts in', () {
    Exercise exercise(WeightUnit unit, int id) => Exercise(
          'Row',
          {id: ExerciseSet(50, 5, id, unit: unit)},
          id,
          DateTime(2026),
        );

    Workout workout(DateTime start, WeightUnit unit, int id) =>
        Workout('w$id', start, start, {id: exercise(unit, id)});

    test('is kg with nothing to go on', () {
      expect(defaultWeightUnit(current: [], history: []), WeightUnit.kg);
    });

    test('follows the latest set in this workout first', () {
      expect(
        defaultWeightUnit(
          current: [exercise(WeightUnit.kg, 1), exercise(WeightUnit.lb, 2)],
          history: [workout(DateTime(2026, 1), WeightUnit.kg, 3)],
        ),
        WeightUnit.lb,
      );
    });

    test('then the most recent past workout', () {
      expect(
        defaultWeightUnit(
          current: [],
          history: [
            workout(DateTime(2026, 1), WeightUnit.kg, 1),
            workout(DateTime(2026, 2), WeightUnit.lb, 2),
          ],
        ),
        WeightUnit.lb,
      );
    });
  });

  group('storage', () {
    final start = DateTime.utc(2026, 11, 21, 9);

    test('the unit survives the device file', () {
      final squat = Exercise(
        'Squat',
        {1: ExerciseSet(53, 8, 1, unit: WeightUnit.lb)},
        2,
        start,
      );
      final json = encodeActiveWorkout(
        userId: 'u',
        id: 'w',
        startTime: start,
        exercises: const [],
        currentExercise: squat,
      );
      final set = decodeActiveWorkout(json).currentExercise!.sets[1]!;
      expect(set.weight, 53);
      expect(set.unit, WeightUnit.lb);
    });

    test('a device file from before units reads as kg', () {
      final json = {
        'version': workoutJsonVersion,
        'user_id': 'u',
        'id': 'w',
        'start_time': start.toIso8601String(),
        'exercises': const [],
        'current_exercise': {
          'id': 2,
          'name': 'Squat',
          'start_time': start.toIso8601String(),
          'end_time': null,
          'sets': [
            {'id': 1, 'weight': 60, 'reps': 8, 'created_at': null},
          ],
        },
      };
      final set = decodeActiveWorkout(json).currentExercise!.sets[1]!;
      expect(set.unit, WeightUnit.kg);
    });

    test('server rows carry the unit, and a missing one is kg', () {
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
            'id': 2,
            'workout_id': 'w',
            'name': 'Squat',
            'start_time': start.toIso8601String(),
            'end_time': start.toIso8601String(),
          },
        ],
        setRows: [
          {
            'id': 1,
            'exercise_id': 2,
            'set_number': 0,
            'weight': 53,
            'reps': 8,
            'unit': 'lb',
          },
          {'id': 3, 'exercise_id': 2, 'set_number': 1, 'weight': 60, 'reps': 8},
        ],
      );
      final sets = workouts.single.exercises[2]!.sets;
      expect(sets[1]!.unit, WeightUnit.lb);
      expect(sets[3]!.unit, WeightUnit.kg);
    });
  });
}
