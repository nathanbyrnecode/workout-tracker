import 'dart:developer';

import 'package:gym_tracker_app/data/location_mapper.dart';
import 'package:gym_tracker_app/data/manual_workout_mapper.dart';
import 'package:gym_tracker_app/data/supabase_client_provider.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
          .order('date', ascending: false)
          .order('id', ascending: false);
      if (!ref.mounted ||
          generation != _requestGeneration ||
          client.auth.currentUser?.id != user.id) {
        return;
      }
      state = (workouts: mapManualWorkoutRows(rows));
    } catch (error, stackTrace) {
      log(
        'Failed to retrieve manual workouts from Supabase.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Changes a manual workout's title and location. Returns whether the
  /// change was saved.
  Future<bool> updateManualWorkout(
    int id, {
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
  Future<bool> deleteManualWorkout(int id) async {
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
