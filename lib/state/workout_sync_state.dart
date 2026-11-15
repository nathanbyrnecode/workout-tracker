import 'dart:async';
import 'dart:developer';

import 'package:gym_tracker_app/data/local_workout_store.dart';
import 'package:gym_tracker_app/data/manual_workout_mapper.dart';
import 'package:gym_tracker_app/data/supabase_client_provider.dart';
import 'package:gym_tracker_app/data/workout_json.dart';
import 'package:gym_tracker_app/data/workout_upload.dart' as upload;
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/state/manual_workouts_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workout_sync_state.g.dart';

/// How long one upload may take before it counts as failed. The request may
/// still reach the server; that is safe, because a retry of a saved workout
/// changes nothing (`dev/decisions.md` 22).
const uploadTimeout = Duration(seconds: 30);

/// How long the user waits for an upload after ending or logging a workout.
/// The upload carries on after that; see [waitForUpload].
const uploadWait = Duration(seconds: 5);

/// The result of waiting up to [uploadWait] for an upload. [saved] is whether
/// the server had it in time. [stillUploading] is set when the wait ran out
/// first, and completes with the final result.
typedef UploadAttempt = ({bool saved, Future<bool>? stillUploading});

Future<UploadAttempt> waitForUpload(
  Future<bool> upload, {
  Duration wait = uploadWait,
}) async {
  final result = await upload
      .then<bool?>((saved) => saved)
      .timeout(wait, onTimeout: () => null);
  return result == null
      ? (saved: false, stillUploading: upload)
      : (saved: result, stillUploading: null);
}

typedef WorkoutSyncStateData = ({
  /// Finished workouts kept on the device that have not reached the server.
  List<Workout> pendingWorkouts,

  /// Logged workouts kept on the device that have not reached the server.
  List<ManualWorkout> pendingManualWorkouts,

  /// IDs being uploaded right now.
  Set<String> uploading,

  /// Whether [WorkoutSyncNotifier.syncAll] is running.
  bool isSyncing,
});

const WorkoutSyncStateData initialWorkoutSyncStateData = (
  pendingWorkouts: [],
  pendingManualWorkouts: [],
  uploading: {},
  isSyncing: false,
);

/// The workouts and logged workouts that are on the device but not on the
/// server yet, and their uploads.
///
/// Each one is a file in the signed-in user's folder (see
/// `LocalWorkoutStore`). Uploads are single-flight per ID, so the Sync
/// button, the automatic sync and ending a workout never send the same one
/// twice at once. After a successful upload the file is deleted and the
/// workout moves to the server-backed list.
@Riverpod(keepAlive: true)
class WorkoutSyncNotifier extends _$WorkoutSyncNotifier {
  int _generation = 0;
  final _inFlight = <String, Future<bool>>{};

  @override
  WorkoutSyncStateData build() {
    ref.onDispose(() => _generation++);
    return initialWorkoutSyncStateData;
  }

  LocalWorkoutStore get _store => ref.read(localWorkoutStoreProvider);

  String? get _userId => ref.read(supabaseClientProvider).auth.currentUser?.id;

  void _setState({
    List<Workout>? pendingWorkouts,
    List<ManualWorkout>? pendingManualWorkouts,
    Set<String>? uploading,
    bool? isSyncing,
  }) {
    state = (
      pendingWorkouts: pendingWorkouts ?? state.pendingWorkouts,
      pendingManualWorkouts:
          pendingManualWorkouts ?? state.pendingManualWorkouts,
      uploading: uploading ?? state.uploading,
      isSyncing: isSyncing ?? state.isSyncing,
    );
  }

  /// Forgets the list in memory, for sign-out. The files stay, so the same
  /// user's workouts sync after they sign in again.
  void resetState() {
    _generation++;
    _inFlight.clear();
    state = initialWorkoutSyncStateData;
  }

  /// Reads the signed-in user's unsynced workouts from the device.
  Future<void> load() async {
    final userId = _userId;
    if (userId == null) {
      resetState();
      return;
    }
    final generation = _generation;
    try {
      final workouts = await _readAll(
        userId,
        PendingKind.workout,
        decodeWorkout,
      );
      final manual = await _readAll(
        userId,
        PendingKind.manualWorkout,
        decodeManualWorkout,
      );
      if (!_isCurrent(generation, userId)) {
        return;
      }
      _setState(
        pendingWorkouts: workouts
          ..sort((a, b) => b.startTime!.compareTo(a.startTime!)),
        pendingManualWorkouts: manual..sort(compareManualWorkouts),
      );
    } catch (error, stackTrace) {
      log('Could not read unsynced workouts on the device.',
          error: error, stackTrace: stackTrace);
    }
  }

  Future<List<T>> _readAll<T>(
    String userId,
    PendingKind kind,
    T Function(Map<String, dynamic>) decode,
  ) async {
    final entries = <T>[];
    for (final json in await _store.readPending(userId, kind)) {
      if (storedUserId(json) != userId) {
        continue;
      }
      try {
        entries.add(decode(json));
      } on FormatException catch (error) {
        log('Skipped an unsynced entry that could not be read.', error: error);
      }
    }
    return entries;
  }

  bool _isCurrent(int generation, String userId) =>
      ref.mounted && generation == _generation && _userId == userId;

  /// Keeps a finished workout on the device until it uploads. Throws if it
  /// cannot be written.
  Future<void> keepWorkout(Workout workout) async {
    final userId = _userId;
    if (userId == null) {
      throw StateError('No user is signed in.');
    }
    await _store.writePending(
      userId,
      PendingKind.workout,
      workout.id,
      encodeWorkout(workout, userId: userId),
    );
    _setState(pendingWorkouts: [
      workout,
      for (final other in state.pendingWorkouts)
        if (other.id != workout.id) other,
    ]);
  }

  /// Keeps a logged workout on the device until it uploads. Throws if it
  /// cannot be written.
  Future<void> keepManualWorkout(ManualWorkout workout) async {
    final userId = _userId;
    if (userId == null) {
      throw StateError('No user is signed in.');
    }
    await _store.writePending(
      userId,
      PendingKind.manualWorkout,
      workout.id,
      encodeManualWorkout(workout, userId: userId),
    );
    _setState(
      pendingManualWorkouts: [
        workout,
        for (final other in state.pendingManualWorkouts)
          if (other.id != workout.id) other,
      ]..sort(compareManualWorkouts),
    );
  }

  /// Uploads one unsynced workout. Completes with whether the server has it.
  Future<bool> uploadWorkout(String id) => _upload(PendingKind.workout, id);

  /// Uploads one unsynced logged workout. Completes with whether the server
  /// has it.
  Future<bool> uploadManualWorkout(String id) =>
      _upload(PendingKind.manualWorkout, id);

  Future<bool> _upload(PendingKind kind, String id) {
    final key = '${kind.folder}/$id';
    final running = _inFlight[key];
    if (running != null) {
      return running;
    }
    final upload = _runUpload(kind, id);
    _inFlight[key] = upload;
    upload.whenComplete(() {
      if (identical(_inFlight[key], upload)) {
        _inFlight.remove(key);
      }
    }).ignore();
    return upload;
  }

  Future<bool> _runUpload(PendingKind kind, String id) async {
    final userId = _userId;
    if (userId == null) {
      return false;
    }
    final generation = _generation;
    _setState(uploading: {...state.uploading, id});
    try {
      final json = (await _store.readPending(userId, kind))
          .where((entry) => entry['id'] == id && storedUserId(entry) == userId)
          .firstOrNull;
      if (json == null) {
        return false;
      }

      final client = ref.read(supabaseClientProvider);
      final session = client.auth.currentSession;
      if (session != null && session.isExpired) {
        await client.auth.refreshSession().timeout(uploadTimeout);
      }
      switch (kind) {
        case PendingKind.workout:
          await upload.uploadWorkout(client, json).timeout(uploadTimeout);
        case PendingKind.manualWorkout:
          await upload.uploadManualWorkout(client, json).timeout(uploadTimeout);
      }

      // The server has it: the device copy is no longer needed.
      await _store.deletePending(userId, kind, id);
      if (_isCurrent(generation, userId)) {
        _moveToServerList(kind, json);
      }
      return true;
    } catch (error, stackTrace) {
      log('Could not upload $id; it stays on the device.',
          error: error, stackTrace: stackTrace);
      return false;
    } finally {
      if (_isCurrent(generation, userId)) {
        _setState(uploading: {...state.uploading}..remove(id));
      }
    }
  }

  void _moveToServerList(PendingKind kind, Map<String, dynamic> json) {
    switch (kind) {
      case PendingKind.workout:
        final saved = decodeWorkout(json);
        _setState(pendingWorkouts: [
          for (final workout in state.pendingWorkouts)
            if (workout.id != saved.id) workout,
        ]);
        ref
            .read(pastWorkoutsProvider.notifier)
            .addSavedWorkout(_markedSynced(saved));
        unawaited(
          ref.read(pastWorkoutsProvider.notifier).getWorkoutsFromRemote(),
        );
      case PendingKind.manualWorkout:
        final saved = decodeManualWorkout(json);
        _setState(pendingManualWorkouts: [
          for (final workout in state.pendingManualWorkouts)
            if (workout.id != saved.id) workout,
        ]);
        ref
            .read(manualWorkoutsProvider.notifier)
            .addSavedManualWorkout(_manualMarkedSynced(saved));
    }
  }

  /// Uploads everything waiting, one at a time. Does nothing while a sync is
  /// already running. Completes with how many could not be uploaded.
  Future<int> syncAll() async {
    if (state.isSyncing || _userId == null) {
      return state.pendingWorkouts.length + state.pendingManualWorkouts.length;
    }
    final generation = _generation;
    _setState(isSyncing: true);
    var failed = 0;
    try {
      for (final workout in [...state.pendingWorkouts]) {
        if (!await uploadWorkout(workout.id)) failed++;
        if (generation != _generation) return failed;
      }
      for (final workout in [...state.pendingManualWorkouts]) {
        if (!await uploadManualWorkout(workout.id)) failed++;
        if (generation != _generation) return failed;
      }
    } finally {
      if (ref.mounted && generation == _generation) {
        _setState(isSyncing: false);
      }
    }
    return failed;
  }

  /// Waits for an upload of [id] that is already running, so an edit or
  /// delete never races it.
  Future<void> _settle(PendingKind kind, String id) async {
    final running = _inFlight['${kind.folder}/$id'];
    if (running != null) {
      await running;
    }
  }

  /// Changes a workout's title and location, on the device if it has not
  /// synced and on the server if it has. Returns whether it was saved.
  Future<bool> updateWorkout(
    String id, {
    required String title,
    required LocationType locationType,
    Place? place,
  }) async {
    await _settle(PendingKind.workout, id);
    final pending = state.pendingWorkouts.where((w) => w.id == id).firstOrNull;
    if (pending == null) {
      return ref.read(pastWorkoutsProvider.notifier).updateWorkout(
            id,
            title: title,
            locationType: locationType,
            place: place,
          );
    }
    if (title.trim().isEmpty) {
      return false;
    }
    try {
      await keepWorkout(Workout(
        pending.id,
        pending.startTime,
        pending.endTime,
        pending.exercises,
        title: title.trim(),
        locationType: locationType,
        place: place,
        synced: false,
      ));
      return true;
    } catch (error, stackTrace) {
      log('Failed to edit the unsynced workout.',
          error: error, stackTrace: stackTrace);
      return false;
    }
  }

  /// Deletes a workout, from the device if it has not synced and from the
  /// server if it has. Returns whether it was deleted.
  Future<bool> deleteWorkout(String id) async {
    await _settle(PendingKind.workout, id);
    if (!state.pendingWorkouts.any((w) => w.id == id)) {
      return ref.read(pastWorkoutsProvider.notifier).deleteWorkout(id);
    }
    return _deletePending(PendingKind.workout, id);
  }

  /// Changes a logged workout's title and location, on the device if it has
  /// not synced and on the server if it has. Returns whether it was saved.
  Future<bool> updateManualWorkout(
    String id, {
    required String title,
    required LocationType locationType,
    Place? place,
  }) async {
    await _settle(PendingKind.manualWorkout, id);
    final pending =
        state.pendingManualWorkouts.where((w) => w.id == id).firstOrNull;
    if (pending == null) {
      return ref.read(manualWorkoutsProvider.notifier).updateManualWorkout(
            id,
            title: title,
            locationType: locationType,
            place: place,
          );
    }
    if (title.trim().isEmpty) {
      return false;
    }
    try {
      await keepManualWorkout(ManualWorkout(
        id: pending.id,
        date: pending.date,
        title: title.trim(),
        locationType: locationType,
        place: place,
        createdAt: pending.createdAt,
        synced: false,
      ));
      return true;
    } catch (error, stackTrace) {
      log('Failed to edit the unsynced logged workout.',
          error: error, stackTrace: stackTrace);
      return false;
    }
  }

  /// Deletes a logged workout, from the device if it has not synced and from
  /// the server if it has. Returns whether it was deleted.
  Future<bool> deleteManualWorkout(String id) async {
    await _settle(PendingKind.manualWorkout, id);
    if (!state.pendingManualWorkouts.any((w) => w.id == id)) {
      return ref.read(manualWorkoutsProvider.notifier).deleteManualWorkout(id);
    }
    return _deletePending(PendingKind.manualWorkout, id);
  }

  Future<bool> _deletePending(PendingKind kind, String id) async {
    final userId = _userId;
    if (userId == null) {
      return false;
    }
    try {
      await _store.deletePending(userId, kind, id);
    } catch (error, stackTrace) {
      log('Failed to delete the unsynced entry.',
          error: error, stackTrace: stackTrace);
      return false;
    }
    switch (kind) {
      case PendingKind.workout:
        _setState(pendingWorkouts: [
          for (final workout in state.pendingWorkouts)
            if (workout.id != id) workout,
        ]);
      case PendingKind.manualWorkout:
        _setState(pendingManualWorkouts: [
          for (final workout in state.pendingManualWorkouts)
            if (workout.id != id) workout,
        ]);
    }
    return true;
  }
}

Workout _markedSynced(Workout workout) => Workout(
      workout.id,
      workout.startTime,
      workout.endTime,
      workout.exercises,
      title: workout.title,
      locationType: workout.locationType,
      place: workout.place,
    );

ManualWorkout _manualMarkedSynced(ManualWorkout workout) => ManualWorkout(
      id: workout.id,
      date: workout.date,
      title: workout.title,
      locationType: workout.locationType,
      place: workout.place,
      createdAt: workout.createdAt,
    );

/// Every finished workout to show: the server's, plus those still on the
/// device. A workout in both lists is shown once, from the server.
@Riverpod(keepAlive: true)
List<Workout> allWorkouts(Ref ref) {
  final saved = ref.watch(pastWorkoutsProvider).workouts;
  final pending = ref.watch(workoutSyncProvider).pendingWorkouts;
  if (pending.isEmpty) {
    return saved;
  }
  final savedIds = {for (final workout in saved) workout.id};
  return [
    ...saved,
    for (final workout in pending)
      if (!savedIds.contains(workout.id)) workout,
  ];
}

/// Every logged workout to show, newest day first: the server's, plus those
/// still on the device.
@Riverpod(keepAlive: true)
List<ManualWorkout> allManualWorkouts(Ref ref) {
  final saved = ref.watch(manualWorkoutsProvider).workouts;
  final pending = ref.watch(workoutSyncProvider).pendingManualWorkouts;
  if (pending.isEmpty) {
    return saved;
  }
  final savedIds = {for (final workout in saved) workout.id};
  return [
    ...saved,
    for (final workout in pending)
      if (!savedIds.contains(workout.id)) workout,
  ]..sort(compareManualWorkouts);
}
