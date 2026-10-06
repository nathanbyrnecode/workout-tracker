import 'dart:developer';

import 'package:gym_tracker_app/data/supabase_client_provider.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'current_workout_state.g.dart';

enum WorkoutRecoveryStatus { pending, loading, ready, failed }

const workoutRecoveryWindow = Duration(hours: 12);

typedef CurrentWorkoutStateData = ({
  int? workoutId,
  DateTime? workoutStartDateTime,
  DateTime? workoutEndDateTime,
  bool isInProgress,
  List<Exercise> exercises,
  Exercise? currentExercise,
  WorkoutRecoveryStatus recoveryStatus,
  bool isStartingWorkout,
});

const CurrentWorkoutStateData initialCurrentWorkoutStateData = (
  workoutId: null,
  workoutStartDateTime: null,
  workoutEndDateTime: null,
  isInProgress: false,
  exercises: [],
  currentExercise: null,
  recoveryStatus: WorkoutRecoveryStatus.pending,
  isStartingWorkout: false,
);

@Riverpod(keepAlive: true)
class CurrentWorkoutNotifier extends _$CurrentWorkoutNotifier {
  int _recoveryGeneration = 0;

  @override
  CurrentWorkoutStateData build() {
    ref.onDispose(() => _recoveryGeneration++);
    return initialCurrentWorkoutStateData;
  }

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  Exercise _cloneExerciseWithSets(
      Exercise exercise, Map<int, ExerciseSet> sets) {
    final updated = Exercise(
      exercise.name,
      sets,
      exercise.id,
      exercise.startTime,
    );
    if (exercise.endTime != null) {
      updated.setEndTime(exercise.endTime!);
    }
    return updated;
  }

  void _setState({
    int? workoutId,
    DateTime? workoutStartDateTime,
    DateTime? workoutEndDateTime,
    bool? isInProgress,
    List<Exercise>? exercises,
    Exercise? currentExercise,
    WorkoutRecoveryStatus? recoveryStatus,
    bool? isStartingWorkout,
  }) {
    state = (
      workoutId: workoutId ?? state.workoutId,
      workoutStartDateTime: workoutStartDateTime ?? state.workoutStartDateTime,
      workoutEndDateTime: workoutEndDateTime ?? state.workoutEndDateTime,
      isInProgress: isInProgress ?? state.isInProgress,
      exercises: exercises ?? state.exercises,
      currentExercise: currentExercise ?? state.currentExercise,
      recoveryStatus: recoveryStatus ?? state.recoveryStatus,
      isStartingWorkout: isStartingWorkout ?? state.isStartingWorkout,
    );
  }

  // Provide "true" for the values that should be reset
  void _resetState({
    bool workoutId = false,
    bool workoutStartDateTime = false,
    bool workoutEndDateTime = false,
    bool isInProgress = false,
    bool exercises = false,
    bool currentExercise = false,
  }) {
    state = (
      workoutId: workoutId == true
          ? initialCurrentWorkoutStateData.workoutId
          : state.workoutId,
      workoutStartDateTime: workoutStartDateTime == true
          ? initialCurrentWorkoutStateData.workoutStartDateTime
          : state.workoutStartDateTime,
      workoutEndDateTime: workoutEndDateTime == true
          ? initialCurrentWorkoutStateData.workoutEndDateTime
          : state.workoutEndDateTime,
      isInProgress: isInProgress == true
          ? initialCurrentWorkoutStateData.isInProgress
          : state.isInProgress,
      exercises: exercises == true
          ? initialCurrentWorkoutStateData.exercises
          : state.exercises,
      currentExercise: currentExercise == true
          ? initialCurrentWorkoutStateData.currentExercise
          : state.currentExercise,
      recoveryStatus: state.recoveryStatus,
      isStartingWorkout: state.isStartingWorkout,
    );
  }

  void resetState() {
    _recoveryGeneration++;
    state = initialCurrentWorkoutStateData;
  }

  Future<void> restoreActiveWorkout() async {
    if (state.recoveryStatus == WorkoutRecoveryStatus.loading ||
        state.isInProgress ||
        state.isStartingWorkout) {
      return;
    }
    final client = _client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      resetState();
      return;
    }

    final generation = ++_recoveryGeneration;
    _setState(recoveryStatus: WorkoutRecoveryStatus.loading);
    bool isCurrentRequest() =>
        ref.mounted &&
        generation == _recoveryGeneration &&
        client.auth.currentUser?.id == userId;

    try {
      // Do not filter unfinished/age here: only the latest workout may resume.
      final row = await client
          .from('workouts')
          .select('''
            id, start_time, end_time,
            exercises (
              id, name, start_time, end_time,
              exercise_sets (id, set_number, reps, weight, created_at)
            )
          ''')
          .eq('user_id', userId)
          .order('start_time', ascending: false, nullsFirst: false)
          .order('id', ascending: false)
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));
      if (!isCurrentRequest()) {
        return;
      }
      state = mapActiveWorkoutRow(row, now: DateTime.now());
    } catch (error, stackTrace) {
      if (!isCurrentRequest()) {
        return;
      }
      _setState(recoveryStatus: WorkoutRecoveryStatus.failed);
      log('Failed to restore the active workout.',
          error: error, stackTrace: stackTrace);
    }
  }

  Future<void> startWorkout() async {
    if (state.recoveryStatus != WorkoutRecoveryStatus.ready ||
        state.isInProgress ||
        state.isStartingWorkout) {
      return;
    }
    final user = _client.auth.currentUser;
    if (user == null) {
      return;
    }

    final generation = _recoveryGeneration;
    _setState(isStartingWorkout: true);
    try {
      final startTime = DateTime.now();
      final row = await _client
          .from('workouts')
          .insert({
            'user_id': user.id,
            'start_time': startTime.toUtc().toIso8601String(),
            'created_at': startTime.toUtc().toIso8601String(),
          })
          .select('id')
          .single();
      final rowId = (row['id'] as num).toInt();

      if (!ref.mounted ||
          generation != _recoveryGeneration ||
          _client.auth.currentUser?.id != user.id) {
        return;
      }

      _setState(
        isInProgress: true,
        workoutStartDateTime: startTime,
        workoutId: rowId,
      );
    } catch (error, stackTrace) {
      log(
        'Failed to start the workout.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (ref.mounted && generation == _recoveryGeneration) {
        _setState(isStartingWorkout: false);
      }
    }
  }

  Future<void> endWorkout() async {
    final user = _client.auth.currentUser;
    final workoutId = state.workoutId;
    if (user == null || workoutId == null) {
      return;
    }

    try {
      final endTime = DateTime.now();

      if (state.exercises.isNotEmpty) {
        await _client
            .from('workouts')
            .update({'end_time': endTime.toUtc().toIso8601String()})
            .eq('id', workoutId)
            .eq('user_id', user.id);
      } else {
        await _client
            .from('workouts')
            .delete()
            .eq('id', workoutId)
            .eq('user_id', user.id);
      }

      resetState();
      _setState(recoveryStatus: WorkoutRecoveryStatus.ready);
      await ref.read(pastWorkoutsProvider.notifier).getWorkoutsFromRemote();
    } catch (error, stackTrace) {
      log(
        'Failed to end the workout.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> addExerciseToExerciseList(Exercise exercise) async {
    _setState(exercises: [...state.exercises, exercise]);
  }

  Future<void> startExercise(String name) async {
    final workoutId = state.workoutId;
    if (_client.auth.currentUser == null || workoutId == null) {
      return;
    }

    try {
      final startTime = DateTime.now();
      final row = await _client
          .from('exercises')
          .insert({
            'start_time': startTime.toUtc().toIso8601String(),
            'workout_id': workoutId,
            'name': name,
          })
          .select('id')
          .single();
      final rowId = (row['id'] as num).toInt();

      _setState(currentExercise: Exercise(name, {}, rowId, startTime));
    } catch (error, stackTrace) {
      log(
        'Failed to start the exercise.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> endExercise() async {
    final currentExercise = state.currentExercise;
    if (_client.auth.currentUser == null || currentExercise == null) {
      return;
    }

    try {
      final endTime = DateTime.now();

      if (currentExercise.sets.isNotEmpty) {
        await _client
            .from('exercises')
            .update({'end_time': endTime.toUtc().toIso8601String()}).eq(
                'id', currentExercise.id);
        currentExercise.setEndTime(endTime);
        _setState(exercises: [...state.exercises, currentExercise]);
      } else {
        await _client.from('exercises').delete().eq('id', currentExercise.id);
      }

      _resetState(currentExercise: true);
    } catch (error, stackTrace) {
      log(
        'Failed to end the exercise.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> addSetToCurrentExercise(String reps, String weight) async {
    var parsedReps = int.tryParse(reps);
    var parsedWeight = double.tryParse(weight);
    var exerciseId = state.currentExercise?.id;

    if (parsedReps == null ||
        parsedWeight == null ||
        parsedReps < 0 ||
        parsedWeight < 0 ||
        exerciseId == null) {
      return;
    }

    if (_client.auth.currentUser == null) {
      return;
    }

    try {
      final row = await _client
          .from('exercise_sets')
          .insert({
            'exercise_id': exerciseId,
            'set_number': state.currentExercise?.sets.length ?? 0,
            'reps': parsedReps,
            'weight': parsedWeight,
          })
          .select('id, created_at')
          .single();
      final rowId = (row['id'] as num).toInt();
      final savedAt = DateTime.tryParse(row['created_at'] as String? ?? '');

      final currentExercise = state.currentExercise;
      if (currentExercise == null) {
        return;
      }

      final updatedSets = Map<int, ExerciseSet>.from(currentExercise.sets);
      updatedSets[rowId] = ExerciseSet(
        parsedWeight,
        parsedReps,
        rowId,
        savedAt: (savedAt ?? DateTime.now()).toLocal(),
      );

      _setState(
        currentExercise: _cloneExerciseWithSets(currentExercise, updatedSets),
      );
    } catch (error, stackTrace) {
      log(
        'Failed to add the exercise set.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> removeSetFromCurrentExercise(int setId) async {
    final currentExercise = state.currentExercise;
    if (_client.auth.currentUser == null ||
        !state.isInProgress ||
        currentExercise == null ||
        currentExercise.endTime != null ||
        !currentExercise.sets.containsKey(setId)) {
      return;
    }

    try {
      final deletedRows = await _client
          .from('exercise_sets')
          .delete()
          .eq('id', setId)
          .eq('exercise_id', currentExercise.id)
          .select('id');

      if (deletedRows.isEmpty) {
        return;
      }

      final latestExercise = state.currentExercise;
      if (!state.isInProgress ||
          latestExercise == null ||
          latestExercise.id != currentExercise.id ||
          latestExercise.endTime != null) {
        return;
      }

      final updatedSets = Map<int, ExerciseSet>.from(latestExercise.sets)
        ..remove(setId);

      _setState(
        currentExercise: _cloneExerciseWithSets(latestExercise, updatedSets),
      );

      var setNumber = 0;
      for (final remainingSetId in updatedSets.keys) {
        await _client
            .from('exercise_sets')
            .update({'set_number': setNumber})
            .eq('id', remainingSetId)
            .eq('exercise_id', currentExercise.id);
        setNumber++;
      }
    } catch (error, stackTrace) {
      log(
        'Failed to remove the exercise set.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Reconstructs one snapshot without changing saved timestamps or finishing it.
CurrentWorkoutStateData mapActiveWorkoutRow(
  Map<String, dynamic>? row, {
  required DateTime now,
}) {
  final empty = (
    workoutId: initialCurrentWorkoutStateData.workoutId,
    workoutStartDateTime: initialCurrentWorkoutStateData.workoutStartDateTime,
    workoutEndDateTime: initialCurrentWorkoutStateData.workoutEndDateTime,
    isInProgress: false,
    exercises: <Exercise>[],
    currentExercise: initialCurrentWorkoutStateData.currentExercise,
    recoveryStatus: WorkoutRecoveryStatus.ready,
    isStartingWorkout: false,
  );
  if (row == null || row['end_time'] != null) {
    return empty;
  }
  final startTime = DateTime.tryParse(row['start_time'] as String? ?? '');
  if (startTime == null) {
    return empty;
  }
  final age = now.difference(startTime);
  if (age.isNegative || age >= workoutRecoveryWindow) {
    return empty;
  }

  final exerciseRows =
      List<Map<String, dynamic>>.from(row['exercises'] as List);
  exerciseRows.sort((a, b) {
    final timeOrder = DateTime.parse(a['start_time'] as String)
        .compareTo(DateTime.parse(b['start_time'] as String));
    return timeOrder != 0
        ? timeOrder
        : (a['id'] as num).compareTo(b['id'] as num);
  });
  final completedExercises = <Exercise>[];
  Exercise? currentExercise;
  for (final exerciseRow in exerciseRows) {
    final exercise = Exercise(
      exerciseRow['name'] as String,
      {},
      (exerciseRow['id'] as num).toInt(),
      DateTime.parse(exerciseRow['start_time'] as String).toLocal(),
    );
    final setRows =
        List<Map<String, dynamic>>.from(exerciseRow['exercise_sets'] as List);
    setRows.sort((a, b) {
      final order = ((a['set_number'] as num?) ?? 0)
          .compareTo((b['set_number'] as num?) ?? 0);
      return order != 0 ? order : (a['id'] as num).compareTo(b['id'] as num);
    });
    for (final setRow in setRows) {
      exercise.addSet(ExerciseSet(
        (setRow['weight'] as num).toDouble(),
        (setRow['reps'] as num).toInt(),
        (setRow['id'] as num).toInt(),
        savedAt:
            DateTime.tryParse(setRow['created_at'] as String? ?? '')?.toLocal(),
      ));
    }
    if (exerciseRow['end_time'] != null) {
      exercise.setEndTime(
          DateTime.parse(exerciseRow['end_time'] as String).toLocal());
      completedExercises.add(exercise);
    } else {
      if (currentExercise != null) {
        throw const FormatException('Workout has multiple active exercises.');
      }
      currentExercise = exercise;
    }
  }
  return (
    workoutId: (row['id'] as num).toInt(),
    workoutStartDateTime: startTime.toLocal(),
    workoutEndDateTime: null,
    isInProgress: true,
    exercises: completedExercises,
    currentExercise: currentExercise,
    recoveryStatus: WorkoutRecoveryStatus.ready,
    isStartingWorkout: false,
  );
}
