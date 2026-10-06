import 'dart:developer';

import 'package:gym_tracker_app/data/location_mapper.dart';
import 'package:gym_tracker_app/data/supabase_client_provider.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'past_workouts_state.g.dart';

typedef PastWorkoutsStateData = ({
  List<Workout> workouts,
});

const PastWorkoutsStateData initialPastWorkoutsStateData = (workouts: [],);

@Riverpod(keepAlive: true)
class PastWorkoutsNotifier extends _$PastWorkoutsNotifier {
  int _requestGeneration = 0;
  @override
  PastWorkoutsStateData build() => initialPastWorkoutsStateData;

  void _setState({
    List<Workout>? workouts,
  }) {
    state = (workouts: workouts ?? state.workouts,);
  }

  void resetState() {
    _requestGeneration++;
    state = initialPastWorkoutsStateData;
  }

  Future<void> getWorkoutsFromRemote() async {
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;
    if (user == null) {
      resetState();
      return;
    }

    final generation = ++_requestGeneration;
    try {
      final workoutRows = await client
          .from('workouts')
          .select('id, start_time, end_time, title, $locationColumns')
          .eq('user_id', user.id)
          .not('end_time', 'is', null)
          .order('start_time', ascending: false);
      if (!ref.mounted ||
          generation != _requestGeneration ||
          client.auth.currentUser?.id != user.id) {
        return;
      }
      if (workoutRows.isEmpty) {
        _setState(workouts: []);
        return;
      }
      final exerciseRows = await client
          .from('exercises')
          .select('id, workout_id, name, start_time, end_time')
          .inFilter('workout_id', workoutRows.map((row) => row['id']).toList())
          .order('start_time');
      final setRows = exerciseRows.isEmpty
          ? <Map<String, dynamic>>[]
          : await client
              .from('exercise_sets')
              .select('id, exercise_id, weight, reps, created_at')
              .inFilter(
                  'exercise_id', exerciseRows.map((row) => row['id']).toList())
              .order('id');

      if (!ref.mounted ||
          generation != _requestGeneration ||
          client.auth.currentUser?.id != user.id) {
        return;
      }

      _setState(
        workouts: mapWorkoutRows(
          workoutRows: workoutRows,
          exerciseRows: exerciseRows,
          setRows: setRows,
        ),
      );
    } catch (error, stackTrace) {
      log(
        'Failed to retrieve workouts from Supabase.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> deleteWorkout(int workoutId) async {
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      final deletedRows = await client
          .from('workouts')
          .delete()
          .eq('id', workoutId)
          .eq('user_id', user.id)
          .select('id');
      if (deletedRows.isNotEmpty) {
        final updatedWorkouts =
            state.workouts.where((workout) => workout.id != workoutId).toList();
        _setState(workouts: updatedWorkouts);
      }
    } catch (error, stackTrace) {
      log(
        'Failed to delete the workout.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

List<Workout> mapWorkoutRows({
  required List<Map<String, dynamic>> workoutRows,
  required List<Map<String, dynamic>> exerciseRows,
  required List<Map<String, dynamic>> setRows,
}) {
  final Map<int, Workout> workouts = {};

  for (final row in workoutRows) {
    if (row['end_time'] == null) {
      continue;
    }
    final workoutId = (row['id'] as num).toInt();
    workouts[workoutId] = Workout(
      workoutId,
      _parseDateTime(row['start_time']),
      _parseDateTime(row['end_time']),
      {},
      title: row['title'] as String?,
      locationType: LocationType.fromLabel(row['location_type']),
      place: mapPlaceColumns(row),
    );
  }

  final Map<int, Exercise> exercises = {};
  for (final row in exerciseRows) {
    final workoutId = (row['workout_id'] as num).toInt();
    final workout = workouts[workoutId];
    final exerciseName = row['name'] as String?;
    final exerciseStart = _parseDateTime(row['start_time']);
    final exerciseEnd = _parseDateTime(row['end_time']);
    if (workout == null ||
        exerciseName == null ||
        exerciseStart == null ||
        exerciseEnd == null) {
      continue;
    }

    final exerciseId = (row['id'] as num).toInt();
    final exercise = Exercise(
      exerciseName,
      {},
      exerciseId,
      exerciseStart,
    )..setEndTime(exerciseEnd);
    exercises[exerciseId] = exercise;
    workout.addExercise(exercise);
  }

  for (final row in setRows) {
    final exerciseId = (row['exercise_id'] as num).toInt();
    final exercise = exercises[exerciseId];
    final weight = row['weight'];
    final reps = row['reps'];
    if (exercise == null || weight is! num || reps is! num) {
      continue;
    }

    final setId = (row['id'] as num).toInt();
    exercise.addSet(
      ExerciseSet(
        weight.toDouble(),
        reps.toInt(),
        setId,
        savedAt: _parseDateTime(row['created_at']),
      ),
    );
  }

  return workouts.values.toList();
}

DateTime? _parseDateTime(Object? value) {
  if (value is! String) {
    return null;
  }

  return DateTime.parse(value).toLocal();
}
