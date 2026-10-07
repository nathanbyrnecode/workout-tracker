import 'dart:developer';

import 'package:gym_tracker_app/data/location_mapper.dart';
import 'package:gym_tracker_app/data/supabase_client_provider.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'current_workout_state.g.dart';

enum WorkoutRecoveryStatus { pending, loading, ready, failed }

enum EndWorkoutOutcome { saved, discarded, failed }

/// What ending a workout did. [workout] is set only when it was saved.
typedef EndWorkoutResult = ({EndWorkoutOutcome outcome, Workout? workout});

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

  /// Ends the workout and saves its title and location.
  ///
  /// A workout with no finished exercises has nothing worth keeping, so its
  /// row is deleted and the outcome is [EndWorkoutOutcome.discarded]. On
  /// failure the workout stays in progress so the user can try again.
  Future<EndWorkoutResult> endWorkout({
    required String title,
    required LocationType locationType,
    Place? place,
  }) async {
    final user = _client.auth.currentUser;
    final workoutId = state.workoutId;
    final startTime = state.workoutStartDateTime;
    if (user == null || workoutId == null || startTime == null) {
      return (outcome: EndWorkoutOutcome.failed, workout: null);
    }

    try {
      final endTime = DateTime.now();
      final exercises = state.exercises;

      if (exercises.isEmpty) {
        await _client
            .from('workouts')
            .delete()
            .eq('id', workoutId)
            .eq('user_id', user.id);
        resetState();
        _setState(recoveryStatus: WorkoutRecoveryStatus.ready);
        return (outcome: EndWorkoutOutcome.discarded, workout: null);
      }

      await _client
          .from('workouts')
          .update({
            'end_time': endTime.toUtc().toIso8601String(),
            'title': title.trim(),
            ...locationToColumns(locationType, place),
          })
          .eq('id', workoutId)
          .eq('user_id', user.id);

      final saved = Workout(
        workoutId,
        startTime,
        endTime,
        {for (final exercise in exercises) exercise.id: exercise},
        title: title.trim(),
        locationType: locationType,
        place: place,
      );

      resetState();
      _setState(recoveryStatus: WorkoutRecoveryStatus.ready);
      await ref.read(pastWorkoutsProvider.notifier).getWorkoutsFromRemote();
      return (outcome: EndWorkoutOutcome.saved, workout: saved);
    } catch (error, stackTrace) {
      log(
        'Failed to end the workout.',
        error: error,
        stackTrace: stackTrace,
      );
      return (outcome: EndWorkoutOutcome.failed, workout: null);
    }
  }

  /// Throws the workout away: its row and everything recorded in it are
  /// deleted and nothing reaches history or the tracker. Returns whether it
  /// was discarded; on failure the workout stays in progress.
  Future<bool> discardWorkout() async {
    final user = _client.auth.currentUser;
    final workoutId = state.workoutId;
    if (user == null || workoutId == null) {
      return false;
    }

    try {
      // Exercises and sets go with the workout (cascade).
      await _client
          .from('workouts')
          .delete()
          .eq('id', workoutId)
          .eq('user_id', user.id);
      resetState();
      _setState(recoveryStatus: WorkoutRecoveryStatus.ready);
      return true;
    } catch (error, stackTrace) {
      log(
        'Failed to discard the workout.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
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

  Future<void> addSet({required double weight, required int reps}) async {
    final exerciseId = state.currentExercise?.id;
    if (reps < 0 || weight < 0 || !weight.isFinite || exerciseId == null) {
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
            'reps': reps,
            'weight': weight,
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
        weight,
        reps,
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

  /// Changes the weight and reps of a set in the active exercise. The set
  /// keeps its place and the time it was first saved, so the rest timer does
  /// not restart.
  Future<void> updateSet(
    int setId, {
    required double weight,
    required int reps,
  }) async {
    final currentExercise = state.currentExercise;
    if (_client.auth.currentUser == null ||
        !state.isInProgress ||
        currentExercise == null ||
        currentExercise.endTime != null ||
        !currentExercise.sets.containsKey(setId) ||
        reps < 0 ||
        weight < 0 ||
        !weight.isFinite) {
      return;
    }

    try {
      final updatedRows = await _client
          .from('exercise_sets')
          .update({'reps': reps, 'weight': weight})
          .eq('id', setId)
          .eq('exercise_id', currentExercise.id)
          .select('id');
      if (updatedRows.isEmpty) {
        return;
      }

      final latestExercise = state.currentExercise;
      final existing = latestExercise?.sets[setId];
      if (latestExercise == null ||
          latestExercise.id != currentExercise.id ||
          existing == null) {
        return;
      }

      // Replacing the value under the same key keeps the set's position.
      final updatedSets = Map<int, ExerciseSet>.from(latestExercise.sets);
      updatedSets[setId] =
          ExerciseSet(weight, reps, setId, savedAt: existing.savedAt);

      _setState(
        currentExercise: _cloneExerciseWithSets(latestExercise, updatedSets),
      );
    } catch (error, stackTrace) {
      log(
        'Failed to update the exercise set.',
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
