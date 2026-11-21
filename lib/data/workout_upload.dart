import 'package:gym_tracker_app/data/workout_json.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sends a finished workout's JSON to `save_workout`, which saves it with its
/// exercises and sets in one transaction. Completing without an error means
/// the server has it, including when an earlier attempt already saved it.
Future<void> uploadWorkout(SupabaseClient client, Map<String, dynamic> json) =>
    client.rpc<void>('save_workout', params: {'payload': json});

/// Inserts a logged workout's row. A row with the same ID is left as it is,
/// so a retry after a lost response does not fail or duplicate it.
Future<void> uploadManualWorkout(
  SupabaseClient client,
  Map<String, dynamic> json,
) =>
    client.from('manual_workouts').upsert(
          manualWorkoutRow(json),
          onConflict: 'id',
          ignoreDuplicates: true,
        );

/// What an active workout becomes when it is found more than
/// `workoutRecoveryWindow` after it started: it ends at the last thing
/// recorded in it. An exercise still in progress is kept, ending at its last
/// set, if it has sets, and dropped otherwise. A cardio exercise still in
/// progress keeps the time up to the last tap on its timer, because nobody
/// knows when an open stretch really stopped, and is dropped if that is no
/// time at all. Returns null when nothing is left to keep.
Workout? finishExpiredWorkout(
  ActiveWorkoutJson active, {
  required LocationType locationType,
}) {
  final exercises = [...active.exercises];
  final current = active.currentExercise;
  if (current != null && current.isCardio) {
    final timer = current.cardio.abandoned;
    if (timer.laps.isNotEmpty) {
      exercises.add(
        Exercise(
          current.name,
          current.sets,
          current.id,
          current.startTime,
          type: current.type,
          cardio: timer,
        )..setEndTime(_lastRecorded(current, current.startTime)),
      );
    }
  } else if (current != null && current.sets.isNotEmpty) {
    exercises
        .add(current..setEndTime(_lastRecorded(current, current.startTime)));
  }
  if (exercises.isEmpty) {
    return null;
  }

  var end = active.startTime;
  for (final exercise in exercises) {
    end = _lastRecorded(exercise, end);
  }
  return Workout(
    active.id,
    active.startTime,
    end,
    {for (final exercise in exercises) exercise.id: exercise},
    title: Workout.fallbackTitle,
    locationType: locationType,
    synced: false,
  );
}

DateTime _lastRecorded(Exercise exercise, DateTime since) {
  var latest = since;
  for (final time in [
    exercise.startTime,
    exercise.endTime,
    exercise.cardio.runningSince,
    exercise.cardio.pausedAt,
    for (final set in exercise.sets.values) set.savedAt,
  ]) {
    if (time != null && time.isAfter(latest)) {
      latest = time;
    }
  }
  return latest;
}
