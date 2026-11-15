import 'dart:developer';

import 'package:gym_tracker_app/data/location_mapper.dart';
import 'package:gym_tracker_app/data/manual_workout_mapper.dart';
import 'package:gym_tracker_app/data/supabase_client_provider.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/workout_sync_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'manual_workouts_state.g.dart';

typedef ManualWorkoutsStateData = ({
  List<ManualWorkout> workouts,
});

const ManualWorkoutsStateData initialManualWorkoutsStateData = (workouts: [],);

/// Workouts the user logged after the fact, newest day first.
@Riverpod(keepAlive: true)
class ManualWorkoutsNotifier extends _$ManualWorkoutsNotifier {
  int _requestGeneration = 0;

  @override
  ManualWorkoutsStateData build() => initialManualWorkoutsStateData;

  void resetState() {
    _requestGeneration++;
    state = initialManualWorkoutsStateData;
  }

  /// Adds a logged workout that has just been uploaded, so it shows straight
  /// away even before the next load from the server.
  void addSavedManualWorkout(ManualWorkout workout) {
    if (state.workouts.any((existing) => existing.id == workout.id)) {
      return;
    }
    state =
        (workouts: [...state.workouts, workout]..sort(compareManualWorkouts),);
  }

  Future<void> getManualWorkoutsFromRemote() async {
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;
    if (user == null) {
      resetState();
      return;
    }

    final generation = ++_requestGeneration;
    try {
      final rows = await client
          .from('manual_workouts')
          .select(manualWorkoutColumns)
          .eq('user_id', user.id)
          .order('date', ascending: false);
      if (!ref.mounted ||
          generation != _requestGeneration ||
          client.auth.currentUser?.id != user.id) {
        return;
      }
      state =
          (workouts: mapManualWorkoutRows(rows)..sort(compareManualWorkouts),);
    } catch (error, stackTrace) {
      log(
        'Failed to retrieve manual workouts from Supabase.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Logs a workout for [date]. A day can have any number of them.
  ///
  /// It is kept on the device first, so it is never lost, then uploaded (see
  /// `WorkoutSyncNotifier`). Returns the new workout, with `synced` saying
  /// whether the server has it yet, or null if it could not be kept at all.
  Future<ManualWorkout?> addManualWorkout({
    required DateTime date,
    required String title,
    required LocationType locationType,
    Place? place,
  }) async {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null || title.trim().isEmpty) {
      return null;
    }

    final workout = ManualWorkout(
      id: const Uuid().v4(),
      date: DateTime(date.year, date.month, date.day),
      title: title.trim(),
      locationType: locationType,
      place: place,
      createdAt: ref.read(clockProvider)(),
      synced: false,
    );
    final sync = ref.read(workoutSyncProvider.notifier);
    try {
      await sync.keepManualWorkout(workout);
    } catch (error, stackTrace) {
      log(
        'Failed to keep the logged workout on the device.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
    if (!await sync.uploadManualWorkout(workout.id)) {
      return workout;
    }
    return ManualWorkout(
      id: workout.id,
      date: workout.date,
      title: workout.title,
      locationType: workout.locationType,
      place: workout.place,
      createdAt: workout.createdAt,
    );
  }

  /// Changes a manual workout's title and location. Returns whether the
  /// change was saved.
  Future<bool> updateManualWorkout(
    String id, {
    required String title,
    required LocationType locationType,
    Place? place,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;
    if (user == null || title.trim().isEmpty) {
      return false;
    }

    try {
      final updatedRows = await client
          .from('manual_workouts')
          .update({
            'title': title.trim(),
            ...locationToColumns(locationType, place),
          })
          .eq('id', id)
          .eq('user_id', user.id)
          .select('id');
      if (updatedRows.isEmpty) {
        return false;
      }
      state = (
        workouts: [
          for (final workout in state.workouts)
            if (workout.id == id)
              ManualWorkout(
                id: id,
                date: workout.date,
                createdAt: workout.createdAt,
                title: title.trim(),
                locationType: locationType,
                place: place,
              )
            else
              workout,
        ],
      );
      return true;
    } catch (error, stackTrace) {
      log(
        'Failed to update the manual workout.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Deletes a manual workout. Returns whether it was deleted.
  Future<bool> deleteManualWorkout(String id) async {
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;
    if (user == null) {
      return false;
    }

    try {
      final deletedRows = await client
          .from('manual_workouts')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id)
          .select('id');
      if (deletedRows.isEmpty) {
        return false;
      }
      state = (
        workouts: state.workouts.where((workout) => workout.id != id).toList(),
      );
      return true;
    } catch (error, stackTrace) {
      log(
        'Failed to delete the manual workout.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
