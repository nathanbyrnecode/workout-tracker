import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gym_tracker_app/data/local_workout_store.dart';
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
import 'package:gym_tracker_app/state/workout_sync_state.dart';
import 'package:gym_tracker_app/widgets/app_messenger.dart';

/// Lets a test make a fake's next write fail. Notifiers expose only their
/// state, so switches like this live on a separate object.
class FailSwitch {
  bool on = false;
}

/// What a [FakeWorkoutNotifier] was asked to do, and how it should answer.
class WorkoutSpy {
  int starts = 0;
  int retries = 0;
  int endedWorkouts = 0;
  int endedExercises = 0;
  int discards = 0;

  /// What the next [FakeWorkoutNotifier.endWorkout] reports.
  EndWorkoutOutcome endOutcome = EndWorkoutOutcome.saved;

  /// When set with [EndWorkoutOutcome.savedLocally], the upload is still
  /// running when ending returns, and completes with this.
  Future<bool>? stillUploading;
}

/// What a [FakeAuthNotifier] was asked to do.
class AuthSpy {
  int appleSignIns = 0;
  int googleSignIns = 0;
  int signOuts = 0;
  int deletions = 0;
  int passwordResetCancels = 0;

  /// When set, email methods wait for it, so tests can see the busy state.
  Future<void>? emailGate;
}

/// A workout notifier that starts in a given state and never calls Supabase.
/// Calls are counted on [spy] so tests can check what a widget asked for.
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

  final spy = WorkoutSpy();
  final removedSetIds = <int>[];
  final startedExercises = <String>[];
  final addedSets = <({double weight, int reps})>[];
  final updatedSets = <({int id, double weight, int reps})>[];

  @override
  CurrentWorkoutStateData build() => (
        workoutId: startedAt == null ? null : testId(1),
        workoutStartDateTime: startedAt,
        workoutEndDateTime: null,
        isInProgress: startedAt != null,
        exercises: exercises,
        currentExercise: currentExercise,
        recoveryStatus: recoveryStatus,
      );

  @override
  Future<void> startWorkout() async => spy.starts++;

  @override
  Future<Workout?> restoreActiveWorkout() async {
    spy.retries++;
    return null;
  }

  /// Turn on to make the next discard fail.
  final failDiscard = FailSwitch();

  @override
  Future<bool> discardWorkout() async {
    spy.discards++;
    return !failDiscard.on;
  }

  final endedWith = <({String title, LocationType type, Place? place})>[];

  @override
  Future<EndWorkoutResult> endWorkout({
    required String title,
    required LocationType locationType,
    Place? place,
  }) async {
    spy.endedWorkouts++;
    endedWith.add((title: title, type: locationType, place: place));
    final kept = spy.endOutcome == EndWorkoutOutcome.saved ||
        spy.endOutcome == EndWorkoutOutcome.savedLocally;
    return (
      outcome: spy.endOutcome,
      workout: kept
          ? Workout(
              testId(1),
              startedAt,
              startedAt?.add(const Duration(minutes: 5)),
              {for (final exercise in exercises) exercise.id: exercise},
              title: title,
              locationType: locationType,
              place: place,
              synced: spy.endOutcome == EndWorkoutOutcome.saved,
            )
          : null,
      stillUploading: spy.stillUploading,
    );
  }

  @override
  Future<void> endExercise() async => spy.endedExercises++;

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
/// Sign-in, sign-out and deletion are counted on [spy] instead of performed.
class FakeAuthNotifier extends UserAuthenticationNotifier {
  FakeAuthNotifier([
    this.firstName = 'Nathan',
    this.status = AuthStatus.signedIn,
  ]);

  final String? firstName;
  final AuthStatus status;

  final spy = AuthSpy();

  /// Turn on to make the next account deletion fail.
  final failDeletion = FailSwitch();

  @override
  UserAuthenticationStateData build() =>
      (isSignedIn: status, firstName: firstName);

  @override
  Future<void> signInWithApple() async => spy.appleSignIns++;

  @override
  Future<void> signInWithGoogle({bool silentOnly = false}) async =>
      spy.googleSignIns++;

  @override
  Future<void> signOut() async => spy.signOuts++;

  /// What each email method reports, by name, such as `signInWithEmail`.
  /// Without an entry, sign-up and reset requests send a code and the rest
  /// sign in.
  final emailResults = <String, EmailAuthResult>{};

  /// Each email method called, with the arguments it was given.
  final emailCalls = <({String method, Map<String, String?> args})>[];

  Future<EmailAuthResult> _email(
    String method,
    Map<String, String?> args, {
    EmailAuthResult fallback = EmailAuthResult.signedIn,
  }) async {
    emailCalls.add((method: method, args: args));
    await spy.emailGate;
    return emailResults[method] ?? fallback;
  }

  @override
  Future<EmailAuthResult> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _email('signInWithEmail', {'email': email, 'password': password});

  @override
  Future<EmailAuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? firstName,
  }) =>
      _email(
        'signUpWithEmail',
        {'email': email, 'password': password, 'firstName': firstName},
        fallback: EmailAuthResult.codeSent,
      );

  @override
  Future<EmailAuthResult> confirmEmail({
    required String email,
    required String code,
  }) =>
      _email('confirmEmail', {'email': email, 'code': code});

  @override
  Future<EmailAuthResult> resendConfirmation({required String email}) => _email(
        'resendConfirmation',
        {'email': email},
        fallback: EmailAuthResult.codeSent,
      );

  @override
  Future<EmailAuthResult> sendPasswordReset({required String email}) => _email(
        'sendPasswordReset',
        {'email': email},
        fallback: EmailAuthResult.codeSent,
      );

  @override
  Future<EmailAuthResult> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      _email('resetPassword', {
        'email': email,
        'code': code,
        'newPassword': newPassword,
      });

  @override
  Future<void> cancelPasswordReset() async => spy.passwordResetCancels++;

  @override
  Future<void> deleteAccount() async {
    spy.deletions++;
    if (failDeletion.on) {
      throw StateError('deletion failed');
    }
  }
}

/// Manual workouts that are already loaded. Edits and deletes change the
/// list, as the real notifier does on success.
class FakeManualWorkoutsNotifier extends ManualWorkoutsNotifier {
  FakeManualWorkoutsNotifier([this.workouts = const []]);

  final List<ManualWorkout> workouts;
  final deletedIds = <String>[];
  final added = <ManualWorkout>[];

  /// Turn on to make adds fail.
  final failAdds = FailSwitch();

  /// Turn on to make adds keep the workout on the device only.
  final keepLocally = FailSwitch();

  /// Holds the still-running upload to return from the next add, if any.
  final stillUploading = <Future<bool>>[];

  @override
  ManualWorkoutsStateData build() => (workouts: workouts);

  @override
  Future<LogWorkoutResult> addManualWorkout({
    required DateTime date,
    required String title,
    required LocationType locationType,
    Place? place,
  }) async {
    if (failAdds.on) {
      return (workout: null, stillUploading: null);
    }
    final workout = ManualWorkout(
      id: testId(1000 + added.length),
      date: date,
      title: title.trim(),
      locationType: locationType,
      place: place,
      synced: !keepLocally.on,
    );
    added.add(workout);
    state = (workouts: [...state.workouts, workout]);
    return (
      workout: workout,
      stillUploading: stillUploading.isEmpty ? null : stillUploading.first,
    );
  }

  @override
  Future<void> getManualWorkoutsFromRemote() async {}

  @override
  Future<bool> updateManualWorkout(
    String id, {
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
  Future<bool> deleteManualWorkout(String id) async {
    deletedIds.add(id);
    state = (workouts: state.workouts.where((w) => w.id != id).toList());
    return true;
  }
}

/// A place search over a fixed list, like the design's demo data: with no
/// query it returns everything nearest first, otherwise matches on name or
/// address.
class FakePlaceSearchService implements PlaceSearchService {
  FakePlaceSearchService({this.places = demoPlaces, this.attribution});

  final List<PlaceResult> places;
  final searches = <String>[];
  int currentLocationRequests = 0;

  @override
  bool get isAvailable => true;

  @override
  final String? attribution;

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

/// A UUID-shaped workout ID for tests. IDs made from bigger numbers sort
/// after smaller ones, as the old numeric IDs did.
String testId(int n) =>
    '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';

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
    testId(id),
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

  /// Turn on to make edits and deletes report failure.
  final failWrites = FailSwitch();
  final deletedIds = <String>[];

  @override
  PastWorkoutsStateData build() => (workouts: workouts);

  @override
  Future<void> getWorkoutsFromRemote() async {}

  @override
  Future<bool> updateWorkout(
    String workoutId, {
    required String title,
    required LocationType locationType,
    Place? place,
  }) async {
    if (failWrites.on) {
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
  Future<bool> deleteWorkout(String workoutId) async {
    if (failWrites.on) {
      return false;
    }
    deletedIds.add(workoutId);
    state =
        (workouts: state.workouts.where((w) => w.id != workoutId).toList(),);
    return true;
  }
}

/// Keeps workouts in memory instead of files. Values go through JSON on the
/// way in and out, as they would on disk.
class MemoryWorkoutStore implements LocalWorkoutStore {
  final active = <String, String>{};
  final pending = <String, Map<String, String>>{};

  /// Turn on to make every write fail, like a full disk.
  final failWrites = FailSwitch();

  String _key(String userId, PendingKind kind) => '$userId/${kind.folder}';

  Map<String, dynamic> _decode(String text) =>
      jsonDecode(text) as Map<String, dynamic>;

  void _checkWrite() {
    if (failWrites.on) {
      throw const FileSystemLikeException();
    }
  }

  /// The pending entries of [kind] for [userId], by ID.
  Map<String, Map<String, dynamic>> pendingFor(
    String userId, [
    PendingKind kind = PendingKind.workout,
  ]) =>
      {
        for (final MapEntry(:key, :value)
            in (pending[_key(userId, kind)] ?? {}).entries)
          key: _decode(value),
      };

  @override
  Future<Map<String, dynamic>?> readActive(String userId) async {
    final text = active[userId];
    return text == null ? null : _decode(text);
  }

  @override
  Future<void> writeActive(String userId, Map<String, dynamic> json) async {
    _checkWrite();
    active[userId] = jsonEncode(json);
  }

  @override
  Future<void> deleteActive(String userId) async {
    _checkWrite();
    active.remove(userId);
  }

  @override
  Future<List<Map<String, dynamic>>> readPending(
    String userId,
    PendingKind kind,
  ) async =>
      pendingFor(userId, kind).values.toList();

  @override
  Future<void> writePending(
    String userId,
    PendingKind kind,
    String id,
    Map<String, dynamic> json,
  ) async {
    _checkWrite();
    (pending[_key(userId, kind)] ??= {})[id] = jsonEncode(json);
  }

  @override
  Future<void> deletePending(String userId, PendingKind kind, String id) async {
    _checkWrite();
    pending[_key(userId, kind)]?.remove(id);
  }

  @override
  Future<void> deleteUser(String userId) async {
    _checkWrite();
    active.remove(userId);
    pending.removeWhere((key, _) => key.startsWith('$userId/'));
  }
}

class FileSystemLikeException implements Exception {
  const FileSystemLikeException();

  @override
  String toString() => 'FileSystemLikeException: write failed';
}

/// Records the messages the app would show in a SnackBar.
class RecordingMessenger extends AppMessenger {
  RecordingMessenger() : super(GlobalKey<ScaffoldMessengerState>());

  final messages = <String>[];

  @override
  void show(String message) => messages.add(message);
}

/// Workouts waiting on the device, with a Sync that never touches the
/// network. A successful sync moves them all to [synced].
class FakeWorkoutSyncNotifier extends WorkoutSyncNotifier {
  FakeWorkoutSyncNotifier({
    this.workouts = const [],
    this.manualWorkouts = const [],
  });

  final List<Workout> workouts;
  final List<ManualWorkout> manualWorkouts;

  /// Turn on to make Sync fail for everything waiting.
  final failSync = FailSwitch();

  /// How many times Sync ran.
  final syncs = <int>[];

  @override
  WorkoutSyncStateData build() => (
        pendingWorkouts: workouts,
        pendingManualWorkouts: manualWorkouts,
        uploading: const {},
        isSyncing: false,
      );

  @override
  Future<void> load() async {}

  @override
  Future<int> syncAll() async {
    final waiting =
        state.pendingWorkouts.length + state.pendingManualWorkouts.length;
    syncs.add(waiting);
    if (failSync.on) {
      return waiting;
    }
    state = (
      pendingWorkouts: const [],
      pendingManualWorkouts: const [],
      uploading: const {},
      isSyncing: false,
    );
    return 0;
  }
}

/// [workout] as it is before it reaches the server.
Workout notSynced(Workout workout) => Workout(
      workout.id,
      workout.startTime,
      workout.endTime,
      workout.exercises,
      title: workout.title,
      locationType: workout.locationType,
      place: workout.place,
      synced: false,
    );
