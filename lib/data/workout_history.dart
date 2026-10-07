import 'package:gym_tracker_app/models/workout.dart';

typedef WorkoutMonth = ({int month, List<Workout> workouts});
typedef WorkoutYear = ({int year, List<WorkoutMonth> months});

/// Groups finished workouts by year, then month, newest first at every level.
/// Months and years with no workouts do not appear. Workouts with no start
/// time are left out.
List<WorkoutYear> groupWorkoutsByMonth(Iterable<Workout> workouts) {
  final dated = [
    for (final workout in workouts)
      if (workout.startTime != null) workout,
  ]..sort((a, b) {
      final byTime = b.startTime!.compareTo(a.startTime!);
      return byTime != 0 ? byTime : b.id.compareTo(a.id);
    });

  final years = <WorkoutYear>[];
  for (final workout in dated) {
    final start = workout.startTime!;
    if (years.isEmpty || years.last.year != start.year) {
      years.add((year: start.year, months: []));
    }
    final months = years.last.months;
    if (months.isEmpty || months.last.month != start.month) {
      months.add((month: start.month, workouts: []));
    }
    months.last.workouts.add(workout);
  }
  return years;
}
