import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';

/// A workout notifier that starts in a given state and never calls Supabase.
/// Calls are counted so tests can check what a widget asked for.
class FakeWorkoutNotifier extends CurrentWorkoutNotifier {
  FakeWorkoutNotifier({
    this.startedAt,
    this.exercises = const [],
    this.currentExercise,
    this.recoveryStatus = WorkoutRecoveryStatus.ready,
  });

  /// Null means no workout is in progress.
  final DateTime? startedAt;
  final List<Exercise> exercises;
  final Exercise? currentExercise;
  final WorkoutRecoveryStatus recoveryStatus;

  int starts = 0;
  int retries = 0;
  int endedWorkouts = 0;
  int endedExercises = 0;

  @override
  CurrentWorkoutStateData build() => (
        workoutId: startedAt == null ? null : 1,
        workoutStartDateTime: startedAt,
        workoutEndDateTime: null,
        isInProgress: startedAt != null,
        exercises: exercises,
        currentExercise: currentExercise,
        recoveryStatus: recoveryStatus,
        isStartingWorkout: false,
      );

  @override
  Future<void> startWorkout() async => starts++;

  @override
  Future<void> restoreActiveWorkout() async => retries++;

  @override
  Future<void> endWorkout() async => endedWorkouts++;

  @override
  Future<void> endExercise() async => endedExercises++;
}

/// A signed-in user with an optional first name.
class FakeAuthNotifier extends UserAuthenticationNotifier {
  FakeAuthNotifier([this.firstName = 'Nathan']);

  final String? firstName;

  @override
  UserAuthenticationStateData build() =>
      (isSignedIn: AuthStatus.signedIn, firstName: firstName);
}

/// History that is already loaded and never calls Supabase.
class FakePastWorkoutsNotifier extends PastWorkoutsNotifier {
  FakePastWorkoutsNotifier([this.workouts = const []]);

  final List<Workout> workouts;

  @override
  PastWorkoutsStateData build() => (workouts: workouts);

  @override
  Future<void> getWorkoutsFromRemote() async {}
}
