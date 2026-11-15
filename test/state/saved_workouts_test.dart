import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/supabase_client_provider.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:gym_tracker_app/state/manual_workouts_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
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
    respond = (_) async => jsonResponse([]);
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

  group('logging a manual workout', () {
    test('inserts a row for the calendar day and adds it to the list',
        () async {
      respond = (request) async => jsonResponse({
            'id': testId(9),
            'date': '2026-10-01',
            'title': 'Morning run',
            'location_type': 'Park',
            'place_name': 'Mayfield Park',
            'place_address': null,
            'place_lat': null,
            'place_lng': null,
          });
      final notifier = container.read(manualWorkoutsProvider.notifier);
      final added = await notifier.addManualWorkout(
        // A time late in the day must not move it to the next day.
        date: DateTime(2026, 10, 1, 23, 30),
        title: ' Morning run ',
        locationType: LocationType.park,
        place: const Place(name: 'Mayfield Park'),
      );

      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.url.path, endsWith('/manual_workouts'));
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(Uuid.isValidUUID(fromString: body.remove('id') as String), isTrue);
      expect(body, {
        'user_id': 'user-a',
        'date': '2026-10-01',
        'title': 'Morning run',
        'location_type': 'Park',
        'place_name': 'Mayfield Park',
        'place_address': null,
        'place_lat': null,
        'place_lng': null,
      });
      expect(added?.id, testId(9));
      expect(added?.date, DateTime(2026, 10, 1));
      expect(container.read(manualWorkoutsProvider).workouts.single.title,
          'Morning run');
    });

    test('two adds on one day make two entries', () async {
      var hour = 0;
      respond = (request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse(
            {...body, 'created_at': '2026-10-01T1${++hour}:00:00Z'});
      };
      final notifier = container.read(manualWorkoutsProvider.notifier);
      for (final title in ['Morning run', 'Evening swim']) {
        await notifier.addManualWorkout(
          date: DateTime(2026, 10, 1),
          title: title,
          locationType: LocationType.other,
        );
      }

      expect(requests, hasLength(2));
      final workouts = container.read(manualWorkoutsProvider).workouts;
      expect(workouts, hasLength(2));
      expect(workouts.map((workout) => workout.date).toSet(),
          {DateTime(2026, 10, 1)});
      // Newest entry first within a day.
      expect(workouts.map((workout) => workout.title),
          ['Evening swim', 'Morning run']);
    });

    test('an empty name or a failed save adds nothing', () async {
      final notifier = container.read(manualWorkoutsProvider.notifier);
      expect(
        await notifier.addManualWorkout(
          date: DateTime(2026, 10, 1),
          title: '  ',
          locationType: LocationType.gym,
        ),
        isNull,
      );
      expect(requests, isEmpty);

      respond = (_) async => jsonResponse({'message': 'unavailable'}, 500);
      expect(
        await notifier.addManualWorkout(
          date: DateTime(2026, 10, 1),
          title: 'Run',
          locationType: LocationType.gym,
        ),
        isNull,
      );
      expect(container.read(manualWorkoutsProvider).workouts, isEmpty);
    });
  });

  group('editing and deleting saved workouts', () {
    Future<void> loadHistory() async {
      respond = (request) async {
        if (request.url.path.endsWith('/workouts')) {
          return jsonResponse([
            {
              'id': testId(7),
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
            {'id': testId(7)}
          ]);
      final saved =
          await container.read(pastWorkoutsProvider.notifier).updateWorkout(
                testId(7),
                title: ' Back and biceps ',
                locationType: LocationType.home,
              );

      expect(saved, isTrue);
      final update = requests.single;
      expect(update.method, 'PATCH');
      expect(update.url.queryParameters['id'], 'eq.${testId(7)}');
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
        await notifier.updateWorkout(testId(7),
            title: 'New', locationType: LocationType.home),
        isFalse,
      );
      expect(container.read(pastWorkoutsProvider).workouts.single.title,
          'Pull day');

      // An empty title never reaches the server.
      requests.clear();
      expect(
        await notifier.updateWorkout(testId(7),
            title: '   ', locationType: LocationType.home),
        isFalse,
      );
      expect(requests, isEmpty);
    });

    test('a delete removes the workout and reports it', () async {
      await loadHistory();
      respond = (_) async => jsonResponse([
            {'id': testId(7)}
          ]);
      expect(
        await container
            .read(pastWorkoutsProvider.notifier)
            .deleteWorkout(testId(7)),
        isTrue,
      );
      expect(requests.single.method, 'DELETE');
      expect(container.read(pastWorkoutsProvider).workouts, isEmpty);
    });

    test('manual workouts can be edited and deleted', () async {
      respond = (_) async => jsonResponse([
            {
              'id': testId(2),
              'date': '2026-10-05',
              'title': 'Morning run',
              'location_type': 'Park',
            },
          ]);
      final notifier = container.read(manualWorkoutsProvider.notifier);
      await notifier.getManualWorkoutsFromRemote();
      requests.clear();

      respond = (_) async => jsonResponse([
            {'id': testId(2)}
          ]);
      expect(
        await notifier.updateManualWorkout(
          testId(2),
          title: 'Evening run',
          locationType: LocationType.other,
          place: const Place(name: 'Canal path'),
        ),
        isTrue,
      );
      final update = requests.single;
      expect(update.method, 'PATCH');
      expect(update.url.path, endsWith('/manual_workouts'));
      expect(update.url.queryParameters['id'], 'eq.${testId(2)}');
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
      expect(await notifier.deleteManualWorkout(testId(2)), isTrue);
      expect(requests.single.method, 'DELETE');
      expect(container.read(manualWorkoutsProvider).workouts, isEmpty);
    });
  });

  test('manual workouts load for the signed-in user, newest day first',
      () async {
    respond = (_) async => jsonResponse([
          {
            'id': testId(2),
            'date': '2026-10-05',
            'title': 'Morning run',
            'location_type': 'Park',
            'place_name': 'Mayfield Park',
            'place_address': 'Baring St',
            'place_lat': null,
            'place_lng': null,
          },
          {
            'id': testId(1),
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
    expect(request.url.queryParameters['order'], 'date.desc.nullslast');

    final workouts = container.read(manualWorkoutsProvider).workouts;
    expect(workouts.map((workout) => workout.id), [testId(2), testId(1)]);
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
}
