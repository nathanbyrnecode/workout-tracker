import 'package:gym_tracker_app/data/place_search/place_search_service.dart';
import 'package:gym_tracker_app/data/theme_mode_storage.dart';
import 'package:gym_tracker_app/models/app_notification.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/manual_workouts_state.dart';
import 'package:gym_tracker_app/state/notifications_state.dart';
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
  final removedSetIds = <int>[];
  final startedExercises = <String>[];
  final addedSets = <({double weight, int reps})>[];
  final updatedSets = <({int id, double weight, int reps})>[];

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

  /// What the next [endWorkout] reports.
  EndWorkoutOutcome endOutcome = EndWorkoutOutcome.saved;
  final endedWith = <({String title, LocationType type, Place? place})>[];

  @override
  Future<EndWorkoutResult> endWorkout({
    required String title,
    required LocationType locationType,
    Place? place,
  }) async {
    endedWorkouts++;
    endedWith.add((title: title, type: locationType, place: place));
    return (
      outcome: endOutcome,
      workout: endOutcome == EndWorkoutOutcome.saved
          ? Workout(
              1,
              startedAt,
              startedAt?.add(const Duration(minutes: 5)),
              {for (final exercise in exercises) exercise.id: exercise},
              title: title,
              locationType: locationType,
              place: place,
            )
          : null,
    );
  }

  @override
  Future<void> endExercise() async => endedExercises++;

  @override
  Future<void> removeSetFromCurrentExercise(int setId) async =>
      removedSetIds.add(setId);

  @override
  Future<void> startExercise(String name) async => startedExercises.add(name);

  @override
  Future<void> addSet({required double weight, required int reps}) async =>
      addedSets.add((weight: weight, reps: reps));

  @override
  Future<void> updateSet(
    int setId, {
    required double weight,
    required int reps,
  }) async =>
      updatedSets.add((id: setId, weight: weight, reps: reps));
}

/// A user with an optional first name, signed in unless told otherwise.
/// Sign-in, sign-out and deletion are counted instead of performed.
class FakeAuthNotifier extends UserAuthenticationNotifier {
  FakeAuthNotifier([
    this.firstName = 'Nathan',
    this.status = AuthStatus.signedIn,
  ]);

  final String? firstName;
  final AuthStatus status;

  int appleSignIns = 0;
  int googleSignIns = 0;
  int signOuts = 0;
  int deletions = 0;

  /// Set to make the next account deletion fail.
  bool failDeletion = false;

  @override
  UserAuthenticationStateData build() =>
      (isSignedIn: status, firstName: firstName);

  @override
  Future<void> signInWithApple() async => appleSignIns++;

  @override
  Future<void> signInWithGoogle({bool silentOnly = false}) async =>
      googleSignIns++;

  @override
  Future<void> signOut() async => signOuts++;

  @override
  Future<void> deleteAccount() async {
    deletions++;
    if (failDeletion) {
      throw StateError('deletion failed');
    }
  }
}

/// Manual workouts that are already loaded. Edits and deletes change the
/// list, as the real notifier does on success.
class FakeManualWorkoutsNotifier extends ManualWorkoutsNotifier {
  FakeManualWorkoutsNotifier([this.workouts = const []]);

  final List<ManualWorkout> workouts;
  final deletedIds = <int>[];

  @override
  ManualWorkoutsStateData build() => (workouts: workouts);

  @override
  Future<void> getManualWorkoutsFromRemote() async {}

  @override
  Future<bool> updateManualWorkout(
    int id, {
    required String title,
    required LocationType locationType,
    Place? place,
  }) async {
    state = (
      workouts: [
        for (final workout in state.workouts)
          if (workout.id == id)
            ManualWorkout(
              id: id,
              date: workout.date,
              title: title,
              locationType: locationType,
              place: place,
            )
          else
            workout,
      ],
    );
    return true;
  }

  @override
  Future<bool> deleteManualWorkout(int id) async {
    deletedIds.add(id);
    state = (workouts: state.workouts.where((w) => w.id != id).toList());
    return true;
  }
}

/// A place search over a fixed list, like the design's demo data: with no
/// query it returns everything nearest first, otherwise matches on name or
/// address.
class FakePlaceSearchService implements PlaceSearchService {
  FakePlaceSearchService({this.places = demoPlaces});

  final List<PlaceResult> places;
  final searches = <String>[];
  int currentLocationRequests = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<List<PlaceResult>> nearby() async => [...places]
    ..sort((a, b) => a.distanceMeters!.compareTo(b.distanceMeters!));

  @override
  Future<List<PlaceResult>> search(String query) async {
    searches.add(query);
    final needle = query.toLowerCase();
    return [
      for (final result in places)
        if ('${result.place.name} ${result.place.address}'
            .toLowerCase()
            .contains(needle))
          result,
    ];
  }

  @override
  Future<PlaceResult?> currentLocation() async {
    currentLocationRequests++;
    return const PlaceResult(
      Place(
        name: 'Current location',
        address: 'Near Piccadilly, Manchester M1',
      ),
    );
  }
}

const demoPlaces = [
  PlaceResult(
    Place(name: 'Mayfield Park', address: 'Baring St, Manchester M1 2PY'),
    distanceMeters: 805,
  ),
  PlaceResult(
    Place(
      name: 'PureGym Manchester Piccadilly',
      address: '1 Ducie St, Manchester M1 2JN',
    ),
    distanceMeters: 644,
  ),
  PlaceResult(
    Place(
      name: 'The Gym Group Manchester Central',
      address: '2 Oxford Rd, Manchester M1 5QA',
    ),
    distanceMeters: 1287,
  ),
  PlaceResult(
    Place(name: 'Whitworth Park', address: 'Oxford Rd, Manchester M14 4PW'),
    distanceMeters: 2900,
  ),
];

/// Notifications seeded with a list; the real notifier always starts empty.
class FakeNotificationsNotifier extends NotificationsNotifier {
  FakeNotificationsNotifier([this.seed = const []]);

  final List<AppNotification> seed;

  @override
  NotificationsStateData build() => (notifications: seed);
}

/// Keeps the appearance choice in memory.
class FakeThemeModeStorage implements ThemeModeStorage {
  FakeThemeModeStorage([this.value]);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

/// A finished workout for tests. Each exercise is a name and its sets as
/// (weight, reps).
Workout testWorkout(
  int id,
  DateTime start, {
  String? title,
  LocationType? type,
  Place? place,
  Duration duration = const Duration(minutes: 2, seconds: 27),
  Map<String, List<(double, int)>> exercises = const {
    'Bench press': [(60, 8), (65, 6), (70, 6)],
  },
}) {
  var exerciseId = id * 100;
  var setId = id * 1000;
  return Workout(
    id,
    start,
    start.add(duration),
    {
      for (final MapEntry(key: name, value: sets) in exercises.entries)
        ++exerciseId: Exercise(
          name,
          {
            for (final set in sets) ++setId: ExerciseSet(set.$1, set.$2, setId),
          },
          exerciseId,
          start,
        )..setEndTime(start.add(const Duration(minutes: 1, seconds: 18))),
    },
    title: title,
    locationType: type,
    place: place,
  );
}

/// History that is already loaded and never calls Supabase. Edits and
/// deletes change the list, as the real notifier does on success.
class FakePastWorkoutsNotifier extends PastWorkoutsNotifier {
  FakePastWorkoutsNotifier([this.workouts = const []]);

  final List<Workout> workouts;

  /// Set to make edits and deletes report failure.
  bool failWrites = false;
  final deletedIds = <int>[];

  @override
  PastWorkoutsStateData build() => (workouts: workouts);

  @override
  Future<void> getWorkoutsFromRemote() async {}

  @override
  Future<bool> updateWorkout(
    int workoutId, {
    required String title,
    required LocationType locationType,
    Place? place,
  }) async {
    if (failWrites) {
      return false;
    }
    state = (
      workouts: [
        for (final workout in state.workouts)
          if (workout.id == workoutId)
            Workout(
              workout.id,
              workout.startTime,
              workout.endTime,
              workout.exercises,
              title: title,
              locationType: locationType,
              place: place,
            )
          else
            workout,
      ],
    );
    return true;
  }

  @override
  Future<bool> deleteWorkout(int workoutId) async {
    if (failWrites) {
      return false;
    }
    deletedIds.add(workoutId);
    state =
        (workouts: state.workouts.where((w) => w.id != workoutId).toList(),);
    return true;
  }
}
