import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/workout_history.dart';
import 'package:gym_tracker_app/models/workout.dart';

import '../helpers/fakes.dart';

void main() {
  test('groups by year then month, newest first at every level', () {
    final years = groupWorkoutsByMonth([
      testWorkout(1, DateTime(2026, 9, 27, 9)),
      testWorkout(2, DateTime(2026, 10, 6, 9)),
      testWorkout(3, DateTime(2025, 12, 31, 9)),
      testWorkout(4, DateTime(2026, 10, 5, 9)),
      testWorkout(5, DateTime(2026, 9, 28, 9)),
    ]);

    expect(years.map((year) => year.year), [2026, 2025]);
    expect(years[0].months.map((month) => month.month), [10, 9]);
    expect(years[0].months[0].workouts.map((w) => w.id), [2, 4]);
    expect(years[0].months[1].workouts.map((w) => w.id), [5, 1]);
    expect(years[1].months.single.month, 12);
    expect(years[1].months.single.workouts.single.id, 3);
  });

  test('months and years with no workouts do not appear', () {
    final years = groupWorkoutsByMonth([
      testWorkout(1, DateTime(2026, 10, 6)),
      testWorkout(2, DateTime(2026, 7, 1)),
      testWorkout(3, DateTime(2024, 2, 29)),
    ]);

    expect(years.map((year) => year.year), [2026, 2024]);
    expect(years[0].months.map((month) => month.month), [10, 7]);
  });

  test('a year boundary splits December from January', () {
    final years = groupWorkoutsByMonth([
      testWorkout(1, DateTime(2026, 1, 1, 0, 0)),
      testWorkout(2, DateTime(2025, 12, 31, 23, 59)),
    ]);

    expect(years.map((year) => year.year), [2026, 2025]);
    expect(years[0].months.single.month, 1);
    expect(years[1].months.single.month, 12);
  });

  test('workouts at the same time keep a stable order, newest id first', () {
    final same = DateTime(2026, 10, 6, 9);
    final month =
        groupWorkoutsByMonth([testWorkout(1, same), testWorkout(2, same)])
            .single
            .months
            .single;
    expect(month.workouts.map((w) => w.id), [2, 1]);
  });

  test('no workouts, or workouts with no start, give nothing', () {
    expect(groupWorkoutsByMonth([]), isEmpty);
    expect(groupWorkoutsByMonth([Workout(1, null, null, {})]), isEmpty);
  });
}
