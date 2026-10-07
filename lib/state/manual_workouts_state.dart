import 'dart:developer';

import 'package:gym_tracker_app/data/manual_workout_mapper.dart';
import 'package:gym_tracker_app/data/supabase_client_provider.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';
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
}
