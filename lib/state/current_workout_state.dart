import 'dart:developer';

import 'package:gym_tracker_app/data/local_workout_store.dart';
import 'package:gym_tracker_app/data/supabase_client_provider.dart';
import 'package:gym_tracker_app/data/workout_history.dart';
import 'package:gym_tracker_app/data/workout_json.dart';
import 'package:gym_tracker_app/data/workout_upload.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/workout_sync_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'current_workout_state.g.dart';

/// Whether the device copy of the active workout has been read yet. Workout
/// actions wait for [ready].
enum WorkoutRecoveryStatus { pending, loading, ready }

enum EndWorkoutOutcome {
  /// The server has it.
  saved,

  /// It is kept on the device and will be uploaded later.
  savedLocally,

  /// It had no exercises, so nothing was kept.
  discarded,

  /// It could not even be kept on the device. The workout is still active.
  failed,
}

/// What ending a workout did. [workout] is set when it was kept.
typedef EndWorkoutResult = ({EndWorkoutOutcome outcome, Workout? workout});

const workoutRecoveryWindow = Duration(hours: 12);

typedef CurrentWorkoutStateData = ({
  String? workoutId,
  DateTime? workoutStartDateTime,
  DateTime? workoutEndDateTime,
  bool isInProgress,
  List<Exercise> exercises,
  Exercise? currentExercise,
  WorkoutRecoveryStatus recoveryStatus,
});

const CurrentWorkoutStateData initialCurrentWorkoutStateData = (
  workoutId: null,
  workoutStartDateTime: null,
  workoutEndDateTime: null,
  isInProgress: false,
  exercises: [],
  currentExercise: null,
  recoveryStatus: WorkoutRecoveryStatus.pending,
);

const CurrentWorkoutStateData _readyWithNoWorkout = (
  workoutId: null,
  workoutStartDateTime: null,
  workoutEndDateTime: null,
  isInProgress: false,
  exercises: [],
  currentExercise: null,
  recoveryStatus: WorkoutRecoveryStatus.ready,
);

/// The workout in progress. It lives on the device only: every change is
/// written to the user's `active.json` (`dev/decisions.md` 21), so nothing
/// here needs the network until the workout is ended.
@Riverpod(keepAlive: true)
class CurrentWorkoutNotifier extends _$CurrentWorkoutNotifier {
  int _recoveryGeneration = 0;

  @override
  CurrentWorkoutStateData build() {
    ref.onDispose(() => _recoveryGeneration++);
    return initialCurrentWorkoutStateData;
  }

  LocalWorkoutStore get _store => ref.read(localWorkoutStoreProvider);

  String? get _userId => ref.read(supabaseClientProvider).auth.currentUser?.id;

  DateTime _now() => ref.read(clockProvider)();

  /// Exercise and set IDs only have to be unique within the workout.
  int _nextLocalId() {
    var highest = 0;
    for (final exercise in [
      ...state.exercises,
      if (state.currentExercise != null) state.currentExercise!,
    ]) {
      if (exercise.id > highest) highest = exercise.id;
      for (final setId in exercise.sets.keys) {
        if (setId > highest) highest = setId;
      }
    }
    return highest + 1;
  }

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
    String? workoutId,
    DateTime? workoutStartDateTime,
    bool? isInProgress,
    List<Exercise>? exercises,
    Exercise? currentExercise,
    bool clearCurrentExercise = false,
    WorkoutRecoveryStatus? recoveryStatus,
  }) {
    state = (
      workoutId: workoutId ?? state.workoutId,
      workoutStartDateTime: workoutStartDateTime ?? state.workoutStartDateTime,
      workoutEndDateTime: state.workoutEndDateTime,
      isInProgress: isInProgress ?? state.isInProgress,
      exercises: exercises ?? state.exercises,
      currentExercise: clearCurrentExercise
          ? null
          : currentExercise ?? state.currentExercise,
      recoveryStatus: recoveryStatus ?? state.recoveryStatus,
    );
  }

  /// Writes the workout as it is now. A failed write is logged; the workout
  /// carries on in memory and the next change tries again.
  Future<void> _persist() async {
    final userId = _userId;
    final workoutId = state.workoutId;
    final startTime = state.workoutStartDateTime;
    if (userId == null || workoutId == null || startTime == null) {
      return;
    }
    try {
      await _store.writeActive(
        userId,
        encodeActiveWorkout(
          userId: userId,
          id: workoutId,
          startTime: startTime,
          exercises: state.exercises,
          currentExercise: state.currentExercise,
        ),
      );
    } catch (error, stackTrace) {
      log('Failed to keep the active workout on the device.',
          error: error, stackTrace: stackTrace);
    }
  }

  /// Forgets the workout in memory. Its file stays, so the same user gets it
  /// back after signing in again.
  void resetState() {
    _recoveryGeneration++;
    state = initialCurrentWorkoutStateData;
  }

  /// Reads the signed-in user's active workout from the device.
  ///
  /// A workout that started [workoutRecoveryWindow] or more ago is ended
  /// instead, at the last thing recorded in it, and kept for upload (see
  /// [finishExpiredWorkout]); one with no exercises is dropped. Returns the
  /// workout that was ended this way, if any.
  Future<Workout?> restoreActiveWorkout() async {
    if (state.recoveryStatus == WorkoutRecoveryStatus.loading ||
        state.isInProgress) {
      return null;
    }
    final userId = _userId;
    if (userId == null) {
      resetState();
      return null;
    }

    final generation = ++_recoveryGeneration;
    _setState(recoveryStatus: WorkoutRecoveryStatus.loading);
    bool isCurrentRequest() =>
        ref.mounted && generation == _recoveryGeneration && _userId == userId;

    try {
      final json = await _store.readActive(userId);
      if (!isCurrentRequest()) {
        return null;
      }
      if (json == null || storedUserId(json) != userId) {
        state = _readyWithNoWorkout;
        return null;
      }
      final active = decodeActiveWorkout(json);

      // Ending writes the finished copy before removing the active one, so a
      // crash in between leaves both. The finished copy wins.
      final pending = await _store.readPending(userId, PendingKind.workout);
      if (!isCurrentRequest()) {
        return null;
      }
      if (pending.any((entry) => entry['id'] == active.id)) {
        await _store.deleteActive(userId);
        state = _readyWithNoWorkout;
        return null;
      }

      if (_now().difference(active.startTime) >= workoutRecoveryWindow) {
        final finished = finishExpiredWorkout(
          active,
          locationType: defaultLocationType(ref.read(allWorkoutsProvider)),
        );
        if (finished != null) {
          await ref.read(workoutSyncProvider.notifier).keepWorkout(finished);
        }
        await _store.deleteActive(userId);
        if (isCurrentRequest()) {
          state = _readyWithNoWorkout;
        }
        return finished;
      }

      state = (
        workoutId: active.id,
        workoutStartDateTime: active.startTime,
        workoutEndDateTime: null,
        isInProgress: true,
        exercises: active.exercises,
        currentExercise: active.currentExercise,
        recoveryStatus: WorkoutRecoveryStatus.ready,
      );
      return null;
    } catch (error, stackTrace) {
      log('Could not read the active workout on the device.',
          error: error, stackTrace: stackTrace);
      if (isCurrentRequest()) {
        state = _readyWithNoWorkout;
      }
      return null;
    }
  }

  Future<void> startWorkout() async {
    if (state.recoveryStatus != WorkoutRecoveryStatus.ready ||
        state.isInProgress ||
        _userId == null) {
      return;
    }
    _setState(
      workoutId: const Uuid().v4(),
      workoutStartDateTime: _now(),
      isInProgress: true,
      exercises: const [],
      clearCurrentExercise: true,
    );
    await _persist();
  }

  /// Ends the workout with its title and location and keeps it on the device,
  /// then tries to upload it (see `WorkoutSyncNotifier`).
  ///
  /// A workout with no finished exercises has nothing worth keeping, so it is
  /// dropped and the outcome is [EndWorkoutOutcome.discarded]. If it cannot be
  /// kept on the device the workout stays in progress so the user can try
  /// again.
  Future<EndWorkoutResult> endWorkout({
    required String title,
    required LocationType locationType,
    Place? place,
  }) async {
    final userId = _userId;
    final workoutId = state.workoutId;
    final startTime = state.workoutStartDateTime;
    if (userId == null || workoutId == null || startTime == null) {
      return (outcome: EndWorkoutOutcome.failed, workout: null);
    }

    if (state.exercises.isEmpty) {
      return await discardWorkout()
          ? (outcome: EndWorkoutOutcome.discarded, workout: null)
          : (outcome: EndWorkoutOutcome.failed, workout: null);
    }

    final workout = Workout(
      workoutId,
      startTime,
      _now(),
      {for (final exercise in state.exercises) exercise.id: exercise},
      title: title.trim(),
      locationType: locationType,
      place: place,
      synced: false,
    );
    final sync = ref.read(workoutSyncProvider.notifier);
    try {
      await sync.keepWorkout(workout);
      await _store.deleteActive(userId);
    } catch (error, stackTrace) {
      log('Failed to keep the finished workout on the device.',
          error: error, stackTrace: stackTrace);
      return (outcome: EndWorkoutOutcome.failed, workout: null);
    }
    _recoveryGeneration++;
    state = _readyWithNoWorkout;

    if (await sync.uploadWorkout(workoutId)) {
      return (
        outcome: EndWorkoutOutcome.saved,
        workout: Workout(
          workout.id,
          workout.startTime,
          workout.endTime,
          workout.exercises,
          title: workout.title,
          locationType: workout.locationType,
          place: workout.place,
        ),
      );
    }
    return (outcome: EndWorkoutOutcome.savedLocally, workout: workout);
  }

  /// Throws the workout away: nothing reaches history or the tracker.
  /// Returns whether it was discarded; on failure the workout stays in
  /// progress.
  Future<bool> discardWorkout() async {
    final userId = _userId;
    if (userId == null || state.workoutId == null) {
      return false;
    }
    try {
      await _store.deleteActive(userId);
    } catch (error, stackTrace) {
      log('Failed to discard the workout.',
          error: error, stackTrace: stackTrace);
      return false;
    }
    _recoveryGeneration++;
    state = _readyWithNoWorkout;
    return true;
  }

  Future<void> startExercise(String name) async {
    if (!state.isInProgress || state.currentExercise != null) {
      return;
    }
    _setState(
      currentExercise: Exercise(name, {}, _nextLocalId(), _now()),
    );
    await _persist();
  }

  /// Finishes the exercise in progress. One with no sets is dropped.
  Future<void> endExercise() async {
    final currentExercise = state.currentExercise;
    if (currentExercise == null) {
      return;
    }
    if (currentExercise.sets.isNotEmpty) {
      final finished =
          _cloneExerciseWithSets(currentExercise, currentExercise.sets)
            ..setEndTime(_now());
      _setState(
        exercises: [...state.exercises, finished],
        clearCurrentExercise: true,
      );
    } else {
      _setState(clearCurrentExercise: true);
    }
    await _persist();
  }

  Future<void> addSet({required double weight, required int reps}) async {
    final currentExercise = state.currentExercise;
    if (reps < 0 || weight < 0 || !weight.isFinite || currentExercise == null) {
      return;
    }
    final setId = _nextLocalId();
    final updatedSets = Map<int, ExerciseSet>.from(currentExercise.sets);
    updatedSets[setId] = ExerciseSet(weight, reps, setId, savedAt: _now());
    _setState(
      currentExercise: _cloneExerciseWithSets(currentExercise, updatedSets),
    );
    await _persist();
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
    final existing = currentExercise?.sets[setId];
    if (!state.isInProgress ||
        currentExercise == null ||
        currentExercise.endTime != null ||
        existing == null ||
        reps < 0 ||
        weight < 0 ||
        !weight.isFinite) {
      return;
    }
    // Replacing the value under the same key keeps the set's position.
    final updatedSets = Map<int, ExerciseSet>.from(currentExercise.sets);
    updatedSets[setId] =
        ExerciseSet(weight, reps, setId, savedAt: existing.savedAt);
    _setState(
      currentExercise: _cloneExerciseWithSets(currentExercise, updatedSets),
    );
    await _persist();
  }

  Future<void> removeSetFromCurrentExercise(int setId) async {
    final currentExercise = state.currentExercise;
    if (!state.isInProgress ||
        currentExercise == null ||
        currentExercise.endTime != null ||
        !currentExercise.sets.containsKey(setId)) {
      return;
    }
    final updatedSets = Map<int, ExerciseSet>.from(currentExercise.sets)
      ..remove(setId);
    _setState(
      currentExercise: _cloneExerciseWithSets(currentExercise, updatedSets),
    );
    await _persist();
  }
}
