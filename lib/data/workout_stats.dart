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
