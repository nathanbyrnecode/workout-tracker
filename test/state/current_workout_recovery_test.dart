import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/supabase_client_provider.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/manual_workouts_state.dart';
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
    await notifier.addSet(weight: 82.5, reps: 6);
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

  test('editing a set updates its row and keeps its place and timestamp',
      () async {
    respond = (_) async => jsonResponse([
          activeWorkout()
            ..['exercises'][0]['exercise_sets'] = [
              {
                'id': 100,
                'set_number': 0,
                'reps': 8,
                'weight': 80,
                'created_at': '2026-09-30T09:25:00Z',
              },
              {'id': 101, 'set_number': 1, 'reps': 6, 'weight': 85},
            ],
        ]);
    final notifier = container.read(currentWorkoutProvider.notifier);
    await notifier.restoreActiveWorkout();

    respond = (request) async => jsonResponse([
          {'id': 100}
        ]);
    await notifier.updateSet(100, weight: 82.5, reps: 7);

    final update = requests.last;
    expect(update.method, 'PATCH');
    expect(update.url.path, endsWith('/exercise_sets'));
    expect(update.url.queryParameters['id'], 'eq.100');
    expect(update.url.queryParameters['exercise_id'], 'eq.20');
    expect(jsonDecode(update.body), {'reps': 7, 'weight': 82.5});

    final sets = container.read(currentWorkoutProvider).currentExercise!.sets;
    expect(sets.keys.toList(), [100, 101]);
    expect(sets[100]!.weight, 82.5);
    expect(sets[100]!.reps, 7);
    expect(sets[100]!.savedAt?.toUtc(), DateTime.utc(2026, 9, 30, 9, 25));
    expect(sets[101]!.weight, 85);
  });

  test('a set edit the server did not apply leaves the set unchanged',
      () async {
    final notifier = container.read(currentWorkoutProvider.notifier);
    await notifier.restoreActiveWorkout();

    respond = (_) async => jsonResponse([]);
    await notifier.updateSet(100, weight: 90, reps: 5);
    expect(
        container
            .read(currentWorkoutProvider)
            .currentExercise!
            .sets[100]!
            .weight,
        80);

    // Unknown sets and negative values never reach the server.
    final before = requests.length;
    await notifier.updateSet(999, weight: 90, reps: 5);
    await notifier.updateSet(100, weight: -1, reps: 5);
    expect(requests, hasLength(before));
  });

  group('ending a workout', () {
    Map<String, dynamic> finishedExerciseWorkout() => activeWorkout()
      ..['exercises'][0]['end_time'] = DateTime.now().toUtc().toIso8601String();

    test('saves the title, location and place, then reports the workout',
        () async {
      respond = (_) async => jsonResponse([finishedExerciseWorkout()]);
      final notifier = container.read(currentWorkoutProvider.notifier);
      await notifier.restoreActiveWorkout();

      respond = (_) async => jsonResponse([]);
      final result = await notifier.endWorkout(
        title: '  Push day ',
        locationType: LocationType.park,
        place: const Place(
          name: 'Mayfield Park',
          address: 'Baring St',
          lat: 53.47,
          lng: -2.22,
        ),
      );

      final update =
          requests.firstWhere((request) => request.method == 'PATCH');
      expect(update.url.path, endsWith('/workouts'));
      expect(update.url.queryParameters['id'], 'eq.42');
      expect(update.url.queryParameters['user_id'], 'eq.user-a');
      final body = jsonDecode(update.body) as Map<String, dynamic>;
      expect(body['title'], 'Push day');
      expect(body['location_type'], 'Park');
      expect(body['place_name'], 'Mayfield Park');
      expect(body['place_address'], 'Baring St');
      expect(body['place_lat'], 53.47);
      expect(body['place_lng'], -2.22);
      expect(DateTime.parse(body['end_time'] as String).isUtc, isTrue);

      expect(result.outcome, EndWorkoutOutcome.saved);
      expect(result.workout?.id, 42);
      expect(result.workout?.title, 'Push day');
      expect(result.workout?.locationType, LocationType.park);
      expect(result.workout?.place?.name, 'Mayfield Park');
      expect(result.workout?.exercises.values.single.name, 'Bench press');

      final state = container.read(currentWorkoutProvider);
      expect(state.isInProgress, isFalse);
      expect(state.recoveryStatus, WorkoutRecoveryStatus.ready);
    });

    test('with no place, clears the place columns', () async {
      respond = (_) async => jsonResponse([finishedExerciseWorkout()]);
      final notifier = container.read(currentWorkoutProvider.notifier);
      await notifier.restoreActiveWorkout();
      respond = (_) async => jsonResponse([]);
      await notifier.endWorkout(title: 'Legs', locationType: LocationType.home);

      final body = jsonDecode(
        requests.firstWhere((request) => request.method == 'PATCH').body,
      ) as Map<String, dynamic>;
      expect(body['location_type'], 'Home');
      expect(body.containsKey('place_name'), isTrue);
      expect(body['place_name'], isNull);
      expect(body['place_lat'], isNull);
    });

    test('with no finished exercises, deletes the row and saves nothing',
        () async {
      respond = (_) async => jsonResponse([
            activeWorkout()..['exercises'] = <Map<String, dynamic>>[],
          ]);
      final notifier = container.read(currentWorkoutProvider.notifier);
      await notifier.restoreActiveWorkout();
      respond = (_) async => jsonResponse([]);
      final result = await notifier.endWorkout(
        title: 'Nothing',
        locationType: LocationType.gym,
      );

      expect(result.outcome, EndWorkoutOutcome.discarded);
      expect(result.workout, isNull);
      expect(requests.last.method, 'DELETE');
      expect(requests.where((request) => request.method == 'PATCH'), isEmpty);
      expect(container.read(currentWorkoutProvider).isInProgress, isFalse);
    });

    test('a failed save leaves the workout in progress', () async {
      respond = (_) async => jsonResponse([finishedExerciseWorkout()]);
      final notifier = container.read(currentWorkoutProvider.notifier);
      await notifier.restoreActiveWorkout();
      respond = (_) async => jsonResponse({'message': 'unavailable'}, 500);
      final result = await notifier.endWorkout(
        title: 'Push day',
        locationType: LocationType.gym,
      );

      expect(result.outcome, EndWorkoutOutcome.failed);
      final state = container.read(currentWorkoutProvider);
      expect(state.isInProgress, isTrue);
      expect(state.workoutId, 42);
      expect(state.exercises, hasLength(1));
    });
  });

  group('editing and deleting saved workouts', () {
    Future<void> loadHistory() async {
      respond = (request) async {
        if (request.url.path.endsWith('/workouts')) {
          return jsonResponse([
            {
              'id': 7,
              'start_time': '2026-10-05T09:00:00Z',
              'end_time': '2026-10-05T10:00:00Z',
              'title': 'Pull day',
              'location_type': 'Gym',
            },
          ]);
        }
        return jsonResponse([]);
      };
      await container
          .read(pastWorkoutsProvider.notifier)
          .getWorkoutsFromRemote();
      requests.clear();
    }

    test('an edit writes the title and location and updates the list',
        () async {
      await loadHistory();
      respond = (_) async => jsonResponse([
            {'id': 7}
          ]);
      final saved =
          await container.read(pastWorkoutsProvider.notifier).updateWorkout(
                7,
                title: ' Back and biceps ',
                locationType: LocationType.home,
              );

      expect(saved, isTrue);
      final update = requests.single;
      expect(update.method, 'PATCH');
      expect(update.url.queryParameters['id'], 'eq.7');
      expect(update.url.queryParameters['user_id'], 'eq.user-a');
      final body = jsonDecode(update.body) as Map<String, dynamic>;
      expect(body['title'], 'Back and biceps');
      expect(body['location_type'], 'Home');
      expect(body['place_name'], isNull);
      expect(body.containsKey('end_time'), isFalse);

      final workout = container.read(pastWorkoutsProvider).workouts.single;
      expect(workout.title, 'Back and biceps');
      expect(workout.locationType, LocationType.home);
      expect(workout.startTime?.toUtc(), DateTime.utc(2026, 10, 5, 9));
    });

    test('an edit the server did not apply changes nothing', () async {
      await loadHistory();
      respond = (_) async => jsonResponse([]);
      final notifier = container.read(pastWorkoutsProvider.notifier);
      expect(
        await notifier.updateWorkout(7,
            title: 'New', locationType: LocationType.home),
        isFalse,
      );
      expect(container.read(pastWorkoutsProvider).workouts.single.title,
          'Pull day');

      // An empty title never reaches the server.
      requests.clear();
      expect(
        await notifier.updateWorkout(7,
            title: '   ', locationType: LocationType.home),
        isFalse,
      );
      expect(requests, isEmpty);
    });

    test('a delete removes the workout and reports it', () async {
      await loadHistory();
      respond = (_) async => jsonResponse([
            {'id': 7}
          ]);
      expect(
        await container.read(pastWorkoutsProvider.notifier).deleteWorkout(7),
        isTrue,
      );
      expect(requests.single.method, 'DELETE');
      expect(container.read(pastWorkoutsProvider).workouts, isEmpty);
    });

    test('manual workouts can be edited and deleted', () async {
      respond = (_) async => jsonResponse([
            {
              'id': 2,
              'date': '2026-10-05',
              'title': 'Morning run',
              'location_type': 'Park',
            },
          ]);
      final notifier = container.read(manualWorkoutsProvider.notifier);
      await notifier.getManualWorkoutsFromRemote();
      requests.clear();

      respond = (_) async => jsonResponse([
            {'id': 2}
          ]);
      expect(
        await notifier.updateManualWorkout(
          2,
          title: 'Evening run',
          locationType: LocationType.other,
          place: const Place(name: 'Canal path'),
        ),
        isTrue,
      );
      final update = requests.single;
      expect(update.method, 'PATCH');
      expect(update.url.path, endsWith('/manual_workouts'));
      expect(update.url.queryParameters['id'], 'eq.2');
      expect(jsonDecode(update.body), {
        'title': 'Evening run',
        'location_type': 'Other',
        'place_name': 'Canal path',
        'place_address': null,
        'place_lat': null,
        'place_lng': null,
      });
      final edited = container.read(manualWorkoutsProvider).workouts.single;
      expect(edited.title, 'Evening run');
      expect(edited.date, DateTime(2026, 10, 5));
      expect(edited.place?.name, 'Canal path');

      requests.clear();
      expect(await notifier.deleteManualWorkout(2), isTrue);
      expect(requests.single.method, 'DELETE');
      expect(container.read(manualWorkoutsProvider).workouts, isEmpty);
    });
  });

  test('manual workouts load for the signed-in user, newest day first',
      () async {
    respond = (_) async => jsonResponse([
          {
            'id': 2,
            'date': '2026-10-05',
            'title': 'Morning run',
            'location_type': 'Park',
            'place_name': 'Mayfield Park',
            'place_address': 'Baring St',
            'place_lat': null,
            'place_lng': null,
          },
          {
            'id': 1,
            'date': '2026-09-21',
            'title': 'Swim',
            'location_type': 'Other',
            'place_name': null,
            'place_address': null,
            'place_lat': null,
            'place_lng': null,
          },
        ]);
    await container
        .read(manualWorkoutsProvider.notifier)
        .getManualWorkoutsFromRemote();

    final request = requests.single;
    expect(request.url.path, endsWith('/manual_workouts'));
    expect(request.url.queryParameters['user_id'], 'eq.user-a');
    expect(request.url.queryParameters['order'],
        'date.desc.nullslast,id.desc.nullslast');

    final workouts = container.read(manualWorkoutsProvider).workouts;
    expect(workouts.map((workout) => workout.id), [2, 1]);
    expect(workouts.first.date, DateTime(2026, 10, 5));
    expect(workouts.first.place?.name, 'Mayfield Park');

    container.read(manualWorkoutsProvider.notifier).resetState();
    expect(container.read(manualWorkoutsProvider).workouts, isEmpty);
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
