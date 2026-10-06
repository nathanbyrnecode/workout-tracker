import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/supabase_client_provider.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

Map<String, dynamic> activeWorkout() => {
      'id': 42,
      'start_time': DateTime.now()
          .subtract(const Duration(hours: 8))
          .toUtc()
          .toIso8601String(),
      'end_time': null,
      'exercises': [
        {
          'id': 20,
          'name': 'Bench press',
          'start_time': DateTime.now()
              .subtract(const Duration(hours: 7))
              .toUtc()
              .toIso8601String(),
          'end_time': null,
          'exercise_sets': [
            {'id': 100, 'set_number': 0, 'reps': 8, 'weight': 80},
          ],
        },
      ],
    };

http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
      jsonEncode(data),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  late SupabaseClient client;
  late ProviderContainer container;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) respond;

  setUp(() async {
    requests = [];
    respond = (_) async => jsonResponse([activeWorkout()]);
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
    ]);
  });

  tearDown(() async {
    container.dispose();
    await client.dispose();
  });

  test('reads only the latest user workout and blocks start while loading',
      () async {
    final response = Completer<http.Response>();
    respond = (_) => response.future;
    final notifier = container.read(currentWorkoutProvider.notifier);
    await notifier.startWorkout();
    expect(requests, isEmpty);
    final recovery = notifier.restoreActiveWorkout();
    expect(container.read(currentWorkoutProvider).recoveryStatus,
        WorkoutRecoveryStatus.loading);
    await notifier.startWorkout();
    await notifier.restoreActiveWorkout();
    await Future<void>.delayed(Duration.zero);
    expect(requests, hasLength(1));
    final query = requests.single.url.queryParameters;
    expect(query['user_id'], 'eq.user-a');
    expect(query['limit'], '1');
    expect(query['order'], 'start_time.desc.nullslast,id.desc.nullslast');
    expect(query.containsKey('end_time'), isFalse);
    expect(query.containsKey('start_time'), isFalse);
    expect(query['select'], contains('exercise_sets'));
    response.complete(jsonResponse([activeWorkout()]));
    await recovery;
    expect(container.read(currentWorkoutProvider).workoutId, 42);
    await notifier.startWorkout();
    expect(requests, hasLength(1));
  });

  test('a completed latest workout does not trigger a search for older ones',
      () async {
    respond = (_) async => jsonResponse([
          activeWorkout()
            ..['end_time'] = DateTime.now().toUtc().toIso8601String(),
        ]);
    await container
        .read(currentWorkoutProvider.notifier)
        .restoreActiveWorkout();
    expect(requests, hasLength(1));
    expect(container.read(currentWorkoutProvider).isInProgress, isFalse);
    expect(container.read(currentWorkoutProvider).recoveryStatus,
        WorkoutRecoveryStatus.ready);
  });

  test('an empty account enables start after recovery', () async {
    respond = (_) async => jsonResponse([]);
    await container
        .read(currentWorkoutProvider.notifier)
        .restoreActiveWorkout();
    expect(container.read(currentWorkoutProvider).workoutId, isNull);
    expect(container.read(currentWorkoutProvider).recoveryStatus,
        WorkoutRecoveryStatus.ready);
  });

  test('failed recovery blocks start and can be retried', () async {
    respond = (_) async => jsonResponse({'message': 'unavailable'}, 400);
    final notifier = container.read(currentWorkoutProvider.notifier);
    await notifier.restoreActiveWorkout();
    expect(container.read(currentWorkoutProvider).recoveryStatus,
        WorkoutRecoveryStatus.failed);
    await notifier.startWorkout();
    expect(requests, hasLength(1));
    respond = (_) async => jsonResponse([activeWorkout()]);
    await notifier.restoreActiveWorkout();
    expect(
        container
            .read(currentWorkoutProvider)
            .currentExercise
            ?.sets[100]
            ?.weight,
        80);
    expect(container.read(currentWorkoutProvider).recoveryStatus,
        WorkoutRecoveryStatus.ready);
  });

  test('late recovery cannot repopulate state after sign-out reset', () async {
    final response = Completer<http.Response>();
    respond = (_) => response.future;
    final notifier = container.read(currentWorkoutProvider.notifier);
    final recovery = notifier.restoreActiveWorkout();
    await Future<void>.delayed(Duration.zero);
    notifier.resetState();
    response.complete(jsonResponse([activeWorkout()]));
    await recovery;
    expect(
        container.read(currentWorkoutProvider), initialCurrentWorkoutStateData);
  });

  test('late recovery cannot overwrite a different signed-in account',
      () async {
    final response = Completer<http.Response>();
    respond = (_) => response.future;
    final recovery =
        container.read(currentWorkoutProvider.notifier).restoreActiveWorkout();
    await Future<void>.delayed(Duration.zero);
    container.read(currentWorkoutProvider.notifier).resetState();
    await signIn(client, 'user-b');
    response.complete(jsonResponse([activeWorkout()]));
    await recovery;
    expect(container.read(currentWorkoutProvider).workoutId, isNull);
    expect(container.read(currentWorkoutProvider).recoveryStatus,
        WorkoutRecoveryStatus.pending);
  });

  test('restored sets can be removed and new sets continue the saved exercise',
      () async {
    final notifier = container.read(currentWorkoutProvider.notifier);
    await notifier.restoreActiveWorkout();
    respond = (request) async {
      if (request.method == 'DELETE') {
        return jsonResponse([
          {'id': 100}
        ]);
      }
      if (request.method == 'POST') {
        return jsonResponse({'id': 101, 'created_at': '2026-09-30T09:30:00Z'});
      }
      return jsonResponse([]);
    };
    await notifier.removeSetFromCurrentExercise(100);
    expect(
        container.read(currentWorkoutProvider).currentExercise?.sets, isEmpty);
    await notifier.addSetToCurrentExercise('6', '82.5');
    expect(
        container
            .read(currentWorkoutProvider)
            .currentExercise
            ?.sets[101]
            ?.weight,
        82.5);
    expect(
        container
            .read(currentWorkoutProvider)
            .currentExercise
            ?.sets[101]
            ?.savedAt
            ?.toUtc(),
        DateTime.utc(2026, 9, 30, 9, 30));
    final insertion = requests.last;
    expect(jsonDecode(insertion.body), {
      'exercise_id': 20,
      'set_number': 0,
      'reps': 6,
      'weight': 82.5,
    });
  });

  test('history excludes unfinished workouts at the query boundary', () async {
    respond = (_) async => jsonResponse([]);
    await container.read(pastWorkoutsProvider.notifier).getWorkoutsFromRemote();
    expect(requests, hasLength(1));
    expect(requests.single.url.queryParameters['end_time'], 'not.is.null');
    expect(requests.single.url.queryParameters['user_id'], 'eq.user-a');
    final columns = requests.single.url.queryParameters['select']!;
    for (final column in [
      'title',
      'location_type',
      'place_name',
      'place_address',
      'place_lat',
      'place_lng',
    ]) {
      expect(columns, contains(column));
    }
  });

  test('new workout starts only once after a successful empty recovery',
      () async {
    respond = (_) async => jsonResponse([]);
    final notifier = container.read(currentWorkoutProvider.notifier);
    await notifier.restoreActiveWorkout();
    final response = Completer<http.Response>();
    respond = (_) => response.future;
    final start = notifier.startWorkout();
    await notifier.startWorkout();
    await Future<void>.delayed(Duration.zero);
    expect(requests.where((request) => request.method == 'POST'), hasLength(1));
    response.complete(jsonResponse({'id': 43}));
    await start;
    expect(container.read(currentWorkoutProvider).workoutId, 43);
    expect(container.read(currentWorkoutProvider).isStartingWorkout, isFalse);
  });
}
