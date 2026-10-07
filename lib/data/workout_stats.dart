import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';

typedef WorkoutTotals = ({int exercises, int sets, int reps, double volume});

/// Volume of a group of sets: the sum of weight × reps, in kilograms.
double setsVolume(Iterable<ExerciseSet> sets) =>
    sets.fold(0, (total, set) => total + set.weight * set.reps);

/// Totals across [exercises]. Pass the active exercise too if it should count.
WorkoutTotals workoutTotals(Iterable<Exercise> exercises) {
  var count = 0;
  var sets = 0;
  var reps = 0;
  var volume = 0.0;
  for (final exercise in exercises) {
    count++;
    sets += exercise.sets.length;
    for (final set in exercise.sets.values) {
      reps += set.reps;
    }
    volume += setsVolume(exercise.sets.values);
  }
  return (exercises: count, sets: sets, reps: reps, volume: volume);
}

/// The heaviest set; between sets of the same weight, the one with more reps.
/// Null when there are no sets.
ExerciseSet? topSet(Iterable<ExerciseSet> sets) {
  ExerciseSet? top;
  for (final set in sets) {
    if (top == null ||
        set.weight > top.weight ||
        (set.weight == top.weight && set.reps > top.reps)) {
      top = set;
    }
  }
  return top;
}

/// Average weight per rep: volume ÷ total reps, rounded to one decimal place.
/// Zero when there are no reps.
double averageWeight(Iterable<ExerciseSet> sets) {
  final reps = sets.fold(0, (total, set) => total + set.reps);
  if (reps == 0) {
    return 0;
  }
  return (setsVolume(sets) / reps * 10).round() / 10;
}

/// When the most recent set was saved, which is where the rest timer counts
/// from. Null when there are no sets or the last one has no timestamp.
DateTime? lastSetSavedAt(Iterable<ExerciseSet> sets) =>
    sets.isEmpty ? null : sets.last.savedAt;
