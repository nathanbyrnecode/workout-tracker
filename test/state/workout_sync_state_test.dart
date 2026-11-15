import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/local_workout_store.dart';
import 'package:gym_tracker_app/data/supabase_client_provider.dart';
import 'package:gym_tracker_app/data/workout_json.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/state/workout_sync_state.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

Workout unsynced(int n, {String title = 'Legs'}) {
  final start = DateTime(2026, 11, n, 9);
  return Workout(
    testId(n),
    start,
    start.add(const Duration(hours: 1)),
    {
      1: Exercise(
          'Squat', {2: ExerciseSet(100, 5, 2, savedAt: start)}, 1, start)
        ..setEndTime(start.add(const Duration(minutes: 10))),
    },
    title: title,
    locationType: LocationType.gym,
    synced: false,
  );
}

ManualWorkout unsyncedManual(int n) => ManualWorkout(
      id: testId(100 + n),
      date: DateTime(2026, 11, n),
      title: 'Swim',
      locationType: LocationType.other,
      createdAt: DateTime(2026, 11, n, 20),
      synced: false,
    );

void main() {
  late SupabaseClient client;
  late ProviderContainer container;
  late MemoryWorkoutStore store;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) respond;

  Future<http.Response> offline(http.Request _) async =>
      throw const SocketException('No route to host');

  /// Workouts the fake server has saved, as their upload payloads.
  late List<Map<String, dynamic>> server;

  /// The server accepts every upload and returns what it has saved.
  Future<http.Response> online(http.Request request) async {
    if (request.url.path.endsWith('/save_workout')) {
      final payload =
          (jsonDecode(request.body) as Map)['payload'] as Map<String, dynamic>;
      server.add(payload);
      return jsonResponse(payload['id']);
    }
    if (request.method == 'GET' && request.url.path.endsWith('/workouts')) {
      return jsonResponse([
        for (final payload in server)
          {
            for (final key in const [
              'id',
              'start_time',
              'end_time',
              'title',
              'location_type',
            ])
              key: payload[key],
          },
      ]);
    }
    return request.method == 'GET' ? jsonResponse([]) : http.Response('', 201);
  }

  setUp(() async {
    requests = [];
    server = [];
    respond = offline;
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
    ]);
  });

  tearDown(() async {
    container.dispose();
    await client.dispose();
  });

  WorkoutSyncNotifier sync() => container.read(workoutSyncProvider.notifier);
  WorkoutSyncStateData state() => container.read(workoutSyncProvider);
  List<http.Request> uploads() => [
        for (final request in requests)
          if (request.method == 'POST') request,
      ];

  test('loads only the signed-in user\'s unsynced entries', () async {
    await store.writePending('user-a', PendingKind.workout, testId(1),
        encodeWorkout(unsynced(1), userId: 'user-a'));
    await store.writePending('user-a', PendingKind.manualWorkout, testId(101),
        encodeManualWorkout(unsyncedManual(1), userId: 'user-a'));
    // In user-a's folder but written for someone else: never shown.
    await store.writePending('user-a', PendingKind.workout, testId(2),
        encodeWorkout(unsynced(2), userId: 'user-b'));
    await store.writePending('user-b', PendingKind.workout, testId(3),
        encodeWorkout(unsynced(3), userId: 'user-b'));
    // Unreadable entries are skipped.
    await store
        .writePending('user-a', PendingKind.workout, 'broken', {'version': 1});

    await sync().load();

    expect(state().pendingWorkouts.map((w) => w.id), [testId(1)]);
    expect(state().pendingWorkouts.single.synced, isFalse);
    expect(state().pendingManualWorkouts.map((w) => w.id), [testId(101)]);
    expect(requests, isEmpty);
  });

  test('unsynced entries are listed with the server\'s, once each', () async {
    await sync().keepWorkout(unsynced(1));
    await sync().keepWorkout(unsynced(2));
    await sync().keepManualWorkout(unsyncedManual(1));
    final server = unsynced(2, title: 'From the server');
    container.read(pastWorkoutsProvider.notifier).addSavedWorkout(Workout(
          server.id,
          server.startTime,
          server.endTime,
          server.exercises,
          title: server.title,
        ));

    final all = container.read(allWorkoutsProvider);
    expect(all.map((w) => w.id).toSet(), {testId(1), testId(2)});
    expect(all.firstWhere((w) => w.id == testId(2)).title, 'From the server');
    expect(container.read(allManualWorkoutsProvider).single.synced, isFalse);
  });

  group('syncing', () {
    setUp(() async {
      await sync().keepWorkout(unsynced(1));
      await sync().keepWorkout(unsynced(2));
      await sync().keepManualWorkout(unsyncedManual(1));
    });

    test('uploads everything waiting and moves it to the server list',
        () async {
      respond = online;

      expect(await sync().syncAll(), 0);
      await pumpEventQueue();

      final paths = uploads().map((r) => r.url.path).toList();
      expect(paths.where((p) => p.endsWith('/rpc/save_workout')), hasLength(2));
      expect(paths.where((p) => p.endsWith('/manual_workouts')), hasLength(1));
      expect(state().pendingWorkouts, isEmpty);
      expect(state().pendingManualWorkouts, isEmpty);
      expect(state().isSyncing, isFalse);
      expect(store.pendingFor('user-a'), isEmpty);
      expect(store.pendingFor('user-a', PendingKind.manualWorkout), isEmpty);
      final all = container.read(allWorkoutsProvider);
      expect(all.map((w) => w.id).toSet(), {testId(1), testId(2)});
      expect(all.every((w) => w.synced), isTrue);
    });

    test('with no network everything stays on the device', () async {
      expect(await sync().syncAll(), 3);
      expect(state().pendingWorkouts, hasLength(2));
      expect(store.pendingFor('user-a'), hasLength(2));
      expect(state().uploading, isEmpty);
    });

    test('a server error on one entry does not stop the others', () async {
      respond = (request) async =>
          (jsonDecode(request.body) as Map)['payload']?['id'] == testId(1)
              ? jsonResponse({'message': 'boom'}, 500)
              : await online(request);

      expect(await sync().syncAll(), 1);
      expect(state().pendingWorkouts.map((w) => w.id), [testId(1)]);
      expect(state().pendingManualWorkouts, isEmpty);
    });

    test('the same workout is never uploaded twice at once', () async {
      final gate = Completer<void>();
      respond = (request) async {
        await gate.future;
        return online(request);
      };

      final first = sync().uploadWorkout(testId(1));
      final second = sync().uploadWorkout(testId(1));
      final all = sync().syncAll();
      await pumpEventQueue();
      expect(state().uploading, contains(testId(1)));
      gate.complete();

      expect(await first, isTrue);
      expect(await second, isTrue);
      await all;
      final ids = [
        for (final request in uploads())
          if (request.url.path.endsWith('/save_workout'))
            (jsonDecode(request.body) as Map)['payload']['id'],
      ];
      expect(ids.where((id) => id == testId(1)), hasLength(1));
    });

    test('an upload that finishes after sign-out still drops the device copy',
        () async {
      final gate = Completer<void>();
      respond = (request) async {
        await gate.future;
        return online(request);
      };
      final upload = sync().uploadWorkout(testId(1));
      await pumpEventQueue();
      sync().resetState();
      gate.complete();

      expect(await upload, isTrue);
      expect(store.pendingFor('user-a').keys, [testId(2)]);
      // Nothing comes back into the signed-out state.
      expect(state().pendingWorkouts, isEmpty);
    });
  });

  group('waiting for an upload', () {
    const wait = Duration(milliseconds: 50);

    test('a quick success counts as saved', () async {
      expect(await waitForUpload(Future.value(true), wait: wait),
          (saved: true, stillUploading: null));
    });

    test('a quick failure counts as not saved, with nothing left running',
        () async {
      expect(await waitForUpload(Future.value(false), wait: wait),
          (saved: false, stillUploading: null));
    });

    test('a slow upload is handed back to finish later', () async {
      final upload = Completer<bool>();
      final attempt = await waitForUpload(upload.future, wait: wait);
      expect(attempt.saved, isFalse);
      expect(attempt.stillUploading, isNotNull);
      upload.complete(true);
      expect(await attempt.stillUploading, isTrue);
    });

    test('the user waits five seconds', () {
      expect(uploadWait, const Duration(seconds: 5));
    });
  });

  group('editing and deleting', () {
    test('an unsynced workout is edited on the device', () async {
      await sync().keepWorkout(unsynced(1));

      expect(
        await sync().updateWorkout(testId(1),
            title: ' Back day ', locationType: LocationType.home),
        isTrue,
      );

      expect(requests, isEmpty);
      expect(state().pendingWorkouts.single.title, 'Back day');
      expect(state().pendingWorkouts.single.locationType, LocationType.home);
      expect(store.pendingFor('user-a')[testId(1)]!['title'], 'Back day');
      // Its exercises are untouched.
      expect(state().pendingWorkouts.single.exercises.length, 1);
    });

    test('an unsynced workout is deleted from the device', () async {
      await sync().keepWorkout(unsynced(1));
      expect(await sync().deleteWorkout(testId(1)), isTrue);
      expect(requests, isEmpty);
      expect(state().pendingWorkouts, isEmpty);
      expect(store.pendingFor('user-a'), isEmpty);
    });

    test('unsynced logged workouts are edited and deleted on the device',
        () async {
      await sync().keepManualWorkout(unsyncedManual(1));
      expect(
        await sync().updateManualWorkout(testId(101),
            title: 'Pool', locationType: LocationType.gym),
        isTrue,
      );
      expect(state().pendingManualWorkouts.single.title, 'Pool');
      expect(state().pendingManualWorkouts.single.createdAt,
          DateTime(2026, 11, 1, 20));
      expect(await sync().deleteManualWorkout(testId(101)), isTrue);
      expect(state().pendingManualWorkouts, isEmpty);
      expect(requests, isEmpty);
    });

    test('a synced workout is edited on the server', () async {
      respond = (_) async => jsonResponse([
            {'id': testId(7)}
          ]);
      await sync().updateWorkout(testId(7),
          title: 'Back day', locationType: LocationType.home);
      expect(requests.single.method, 'PATCH');
      expect(requests.single.url.path, endsWith('/workouts'));
    });

    test('an edit made during an upload waits, then goes to the server',
        () async {
      await sync().keepWorkout(unsynced(1));
      final gate = Completer<void>();
      respond = (request) async {
        if (request.url.path.endsWith('/save_workout')) {
          await gate.future;
        }
        return request.method == 'PATCH'
            ? jsonResponse([
                {'id': testId(1)}
              ])
            : online(request);
      };

      final upload = sync().uploadWorkout(testId(1));
      final edit = sync().updateWorkout(testId(1),
          title: 'Back day', locationType: LocationType.home);
      await pumpEventQueue();
      expect(requests.where((r) => r.method == 'PATCH'), isEmpty);
      gate.complete();

      expect(await upload, isTrue);
      expect(await edit, isTrue);
      expect(requests.where((r) => r.method == 'PATCH'), hasLength(1));
      expect(store.pendingFor('user-a'), isEmpty);
    });
  });
}
