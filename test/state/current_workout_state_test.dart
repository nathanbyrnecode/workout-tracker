import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/local_workout_store.dart';
import 'package:gym_tracker_app/data/supabase_client_provider.dart';
import 'package:gym_tracker_app/data/workout_json.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../helpers/fakes.dart';

Future<void> signIn(SupabaseClient client, [String userId = 'user-a']) =>
    client.auth.recoverSession(jsonEncode({
      'access_token': 'test-token',
      'token_type': 'bearer',
      'user': {
        'id': userId,
        'app_metadata': {},
        'user_metadata': {},
        'aud': 'authenticated',
        'created_at': '2026-01-01T00:00:00Z',
      },
    }));

http.Response jsonResponse(Object? data, [int status = 200]) => http.Response(
      jsonEncode(data),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  late SupabaseClient client;
  late ProviderContainer container;
  late MemoryWorkoutStore store;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) respond;
  late DateTime now;

  /// No signal: every request fails before reaching a server.
  Future<http.Response> offline(http.Request _) async =>
      throw const SocketException('No route to host');

  setUp(() async {
    requests = [];
    respond = offline;
    now = DateTime(2026, 11, 15, 9);
    store = MemoryWorkoutStore();
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await respond(request);
        return http.Response.bytes(response.bodyBytes, response.statusCode,
            headers: response.headers, request: request);
      }),
    );
    await signIn(client);
    container = ProviderContainer(overrides: [
      supabaseClientProvider.overrideWithValue(client),
      localWorkoutStoreProvider.overrideWithValue(store),
      clockProvider.overrideWithValue(() => now),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await client.dispose();
  });

  CurrentWorkoutNotifier notifier() =>
      container.read(currentWorkoutProvider.notifier);
  CurrentWorkoutStateData state() => container.read(currentWorkoutProvider);

  /// Starts a workout and records one finished exercise with two sets.
  Future<void> recordWorkout() async {
    await notifier().restoreActiveWorkout();
    await notifier().startWorkout();
    now = now.add(const Duration(minutes: 1));
    await notifier().startExercise('Squat');
    now = now.add(const Duration(minutes: 1));
    await notifier().addSet(weight: 100, reps: 5);
    now = now.add(const Duration(minutes: 2));
    await notifier().addSet(weight: 105, reps: 5);
    now = now.add(const Duration(minutes: 1));
    await notifier().endExercise();
  }

  group('with no network', () {
    test('a workout starts, records and is kept on the device', () async {
      await notifier().restoreActiveWorkout();
      expect(state().recoveryStatus, WorkoutRecoveryStatus.ready);

      await recordWorkout();

      expect(requests, isEmpty);
      expect(state().isInProgress, isTrue);
      expect(Uuid.isValidUUID(fromString: state().workoutId!), isTrue);
      final squat = state().exercises.single;
      expect(squat.sets.values.map((set) => set.weight), [100, 105]);
      expect(squat.sets.values.first.savedAt, DateTime(2026, 11, 15, 9, 2));

      final saved = decodeActiveWorkout((await store.readActive('user-a'))!);
      expect(saved.id, state().workoutId);
      expect(saved.exercises.single.sets.length, 2);
      expect(saved.currentExercise, isNull);
    });

    test('ending keeps the finished workout for upload', () async {
      await recordWorkout();
      final id = state().workoutId!;

      final result = await notifier().endWorkout(
        title: ' Leg day ',
        locationType: LocationType.park,
        place: const Place(name: 'Mayfield Park'),
      );

      expect(result.outcome, EndWorkoutOutcome.savedLocally);
      expect(result.workout?.id, id);
      expect(result.workout?.synced, isFalse);
      expect(result.workout?.title, 'Leg day');
      expect(state().isInProgress, isFalse);
      expect(state().recoveryStatus, WorkoutRecoveryStatus.ready);
      expect(await store.readActive('user-a'), isNull);
      final pending = store.pendingFor('user-a')[id]!;
      expect(pending['title'], 'Leg day');
      expect(pending['place_name'], 'Mayfield Park');
      expect(pending['end_time'], now.toUtc().toIso8601String());
    });
  });

  test('ending uploads with save_workout and drops the device copy', () async {
    await recordWorkout();
    final id = state().workoutId!;
    respond = (request) async => request.url.path.endsWith('/save_workout')
        ? jsonResponse(id)
        : jsonResponse([]);

    final result = await notifier().endWorkout(
      title: 'Leg day',
      locationType: LocationType.gym,
    );

    expect(result.outcome, EndWorkoutOutcome.saved);
    expect(result.workout?.synced, isTrue);
    final upload =
        requests.firstWhere((r) => r.url.path.endsWith('/rpc/save_workout'));
    expect(upload.method, 'POST');
    final payload = (jsonDecode(upload.body) as Map)['payload'] as Map;
    expect(payload['id'], id);
    expect(payload['location_type'], 'Gym');
    final exercises = payload['exercises'] as List;
    expect(((exercises.single as Map)['sets'] as List).length, 2);
    expect(store.pendingFor('user-a'), isEmpty);
    // History is reloaded so the workout shows there.
    expect(requests.any((r) => r.url.path.endsWith('/workouts')), isTrue);
  });

  test('a server error keeps the workout on the device', () async {
    await recordWorkout();
    respond = (_) async => jsonResponse({'message': 'boom'}, 500);

    final result = await notifier().endWorkout(
      title: 'Leg day',
      locationType: LocationType.gym,
    );

    expect(result.outcome, EndWorkoutOutcome.savedLocally);
    expect(store.pendingFor('user-a'), hasLength(1));
  });

  test('if the device copy cannot be written, the workout stays active',
      () async {
    await recordWorkout();
    store.failWrites.on = true;

    final result = await notifier().endWorkout(
      title: 'Leg day',
      locationType: LocationType.gym,
    );

    expect(result.outcome, EndWorkoutOutcome.failed);
    expect(state().isInProgress, isTrue);
  });

  test('ending with no finished exercises keeps nothing', () async {
    await notifier().restoreActiveWorkout();
    await notifier().startWorkout();
    await notifier().startExercise('Squat');
    await notifier().endExercise(); // no sets, so dropped

    final result = await notifier().endWorkout(
      title: 'Nothing',
      locationType: LocationType.gym,
    );

    expect(result.outcome, EndWorkoutOutcome.discarded);
    expect(await store.readActive('user-a'), isNull);
    expect(store.pendingFor('user-a'), isEmpty);
    expect(requests, isEmpty);
  });

  test('discarding removes the device copy', () async {
    await recordWorkout();
    expect(await notifier().discardWorkout(), isTrue);
    expect(state().isInProgress, isFalse);
    expect(await store.readActive('user-a'), isNull);
    expect(store.pendingFor('user-a'), isEmpty);
  });

  group('sets in the active exercise', () {
    setUp(() async {
      await notifier().restoreActiveWorkout();
      await notifier().startWorkout();
      await notifier().startExercise('Bench press');
      await notifier().addSet(weight: 80, reps: 8);
      now = now.add(const Duration(minutes: 3));
      await notifier().addSet(weight: 85, reps: 6);
    });

    test('an edit keeps the set in place with its time', () async {
      final first = state().currentExercise!.sets.values.first;
      now = now.add(const Duration(minutes: 3));
      await notifier().updateSet(first.id, weight: 82.5, reps: 7);

      final sets = state().currentExercise!.sets.values.toList();
      expect(sets.map((set) => set.weight), [82.5, 85]);
      expect(sets.first.savedAt, first.savedAt);
      final saved = decodeActiveWorkout((await store.readActive('user-a'))!);
      expect(saved.currentExercise!.sets.values.first.reps, 7);
    });

    test('a removed set is gone, and new sets get fresh IDs', () async {
      final ids = state().currentExercise!.sets.keys.toList();
      await notifier().removeSetFromCurrentExercise(ids.first);
      await notifier().addSet(weight: 90, reps: 4);

      final sets = state().currentExercise!.sets;
      expect(sets.values.map((set) => set.weight), [85, 90]);
      expect(sets.keys.toSet(), hasLength(2));
      final saved = decodeActiveWorkout((await store.readActive('user-a'))!);
      expect(saved.currentExercise!.sets.values.map((s) => s.weight), [85, 90]);
    });
  });

  group('recovery', () {
    test('restores the workout from the device after a restart', () async {
      await recordWorkout();
      await notifier().startExercise('Bench press');
      await notifier().addSet(weight: 80, reps: 8);
      final id = state().workoutId;

      // A fresh app: same device, same user.
      container.dispose();
      container = ProviderContainer(overrides: [
        supabaseClientProvider.overrideWithValue(client),
        localWorkoutStoreProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => now),
      ]);
      expect(await notifier().restoreActiveWorkout(), isNull);

      expect(state().isInProgress, isTrue);
      expect(state().workoutId, id);
      expect(state().workoutStartDateTime, DateTime(2026, 11, 15, 9));
      expect(state().exercises.single.name, 'Squat');
      expect(state().currentExercise?.name, 'Bench press');
      expect(state().currentExercise?.sets.length, 1);
      expect(requests, isEmpty);
    });

    test('with nothing on the device, Start is available', () async {
      await notifier().restoreActiveWorkout();
      expect(state().recoveryStatus, WorkoutRecoveryStatus.ready);
      expect(state().isInProgress, isFalse);
    });

    test('another user\'s workout is never restored', () async {
      await store.writeActive('user-a', {
        ...encodeActiveWorkout(
          userId: 'user-b',
          id: 'w1',
          startTime: now,
          exercises: const [],
          currentExercise: null,
        ),
      });
      await notifier().restoreActiveWorkout();
      expect(state().isInProgress, isFalse);
    });

    test('a file that cannot be read leaves Start available', () async {
      await store.writeActive('user-a', {'version': 99});
      await notifier().restoreActiveWorkout();
      expect(state().recoveryStatus, WorkoutRecoveryStatus.ready);
      expect(state().isInProgress, isFalse);
    });

    test('a workout already kept as finished is not restored again', () async {
      await recordWorkout();
      final id = state().workoutId!;
      final active = (await store.readActive('user-a'))!;
      await notifier()
          .endWorkout(title: 'Legs', locationType: LocationType.gym);
      // As if the app died between writing the finished copy and removing the
      // active one.
      await store.writeActive('user-a', active);

      notifier().resetState();
      await notifier().restoreActiveWorkout();

      expect(state().isInProgress, isFalse);
      expect(await store.readActive('user-a'), isNull);
      expect(store.pendingFor('user-a').keys, [id]);
    });

    test('just under 12 hours, the workout resumes', () async {
      await recordWorkout();
      notifier().resetState();
      now = DateTime(2026, 11, 15, 20, 59, 59);
      await notifier().restoreActiveWorkout();
      expect(state().isInProgress, isTrue);
    });

    test('after 12 hours, it is ended at its last set and kept for upload',
        () async {
      await recordWorkout();
      await notifier().startExercise('Bench press');
      now = now.add(const Duration(minutes: 3));
      await notifier().addSet(weight: 80, reps: 8);
      final lastSet = now;
      final id = state().workoutId!;

      notifier().resetState();
      now = DateTime(2026, 11, 15, 21);
      final ended = await notifier().restoreActiveWorkout();

      expect(ended?.id, id);
      expect(ended?.endTime, lastSet);
      expect(ended?.title, 'Workout');
      expect(ended?.exercises.length, 2);
      expect(state().isInProgress, isFalse);
      expect(state().recoveryStatus, WorkoutRecoveryStatus.ready);
      expect(await store.readActive('user-a'), isNull);
      final pending = store.pendingFor('user-a')[id]!;
      expect(pending['end_time'], lastSet.toUtc().toIso8601String());
      expect(pending['location_type'], 'Gym');
    });

    test('after 12 hours with nothing recorded, it is dropped', () async {
      await notifier().restoreActiveWorkout();
      await notifier().startWorkout();
      await notifier().startExercise('Squat');

      notifier().resetState();
      now = now.add(const Duration(hours: 13));
      expect(await notifier().restoreActiveWorkout(), isNull);

      expect(await store.readActive('user-a'), isNull);
      expect(store.pendingFor('user-a'), isEmpty);
    });

    test('a result that arrives after sign-out is dropped', () async {
      await recordWorkout();
      notifier().resetState();

      final restoring = notifier().restoreActiveWorkout();
      notifier().resetState();
      await restoring;

      expect(state().recoveryStatus, WorkoutRecoveryStatus.pending);
      expect(state().isInProgress, isFalse);
    });
  });

  test('a workout is only started once', () async {
    await notifier().restoreActiveWorkout();
    await Future.wait([notifier().startWorkout(), notifier().startWorkout()]);
    final id = state().workoutId;
    await notifier().startWorkout();
    expect(state().workoutId, id);
  });

  test('pending files from before stay where they are', () async {
    await store.writePending(
        'user-a', PendingKind.workout, 'old', {'version': workoutJsonVersion});
    await recordWorkout();
    expect(store.pendingFor('user-a').keys, ['old']);
  });
}
