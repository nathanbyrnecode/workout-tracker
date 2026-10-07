import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/location_mapper.dart';
import 'package:gym_tracker_app/data/manual_workout_mapper.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/place.dart';

void main() {
  test('maps manual workouts, including several on one date', () {
    final workouts = mapManualWorkoutRows([
      {
        'id': 1,
        'date': '2026-09-21',
        'title': 'Morning run',
        'location_type': 'Park',
        'place_name': 'Mayfield Park',
        'place_address': 'Baring St, Manchester M1 2PY',
        'place_lat': 53.4751,
        'place_lng': -2.2262,
      },
      {
        'id': 2,
        'date': '2026-09-21',
        'title': 'Evening stretch',
        'location_type': 'Home',
        'place_name': null,
        'place_address': null,
        'place_lat': null,
        'place_lng': null,
      },
    ]);

    expect(workouts, hasLength(2));
    expect(workouts.first.id, 1);
    expect(workouts.first.title, 'Morning run');
    expect(workouts.first.locationType, LocationType.park);
    expect(workouts.first.place?.name, 'Mayfield Park');
    expect(workouts.first.place?.lat, 53.4751);
    expect(workouts.last.locationType, LocationType.home);
    expect(workouts.last.place, isNull);
    expect(workouts.first.date, workouts.last.date);
  });

  test('the date is a local calendar day, not a UTC instant', () {
    final workout = mapManualWorkoutRows([
      {
        'id': 1,
        'date': '2026-09-21',
        'title': 'Swim',
        'location_type': 'Other',
      },
    ]).single;

    expect(workout.date, DateTime(2026, 9, 21));
    expect(workout.date.isUtc, isFalse);
    expect(formatCalendarDate(workout.date), '2026-09-21');
  });

  test('rows without a date or title are skipped', () {
    final workouts = mapManualWorkoutRows([
      {'id': 1, 'date': null, 'title': 'Swim', 'location_type': 'Gym'},
      {'id': 2, 'date': '2026-09-21', 'title': '', 'location_type': 'Gym'},
      {'id': 3, 'date': 'not a date', 'title': 'Run', 'location_type': 'Gym'},
    ]);

    expect(workouts, isEmpty);
  });

  test('an unknown location type falls back to Gym', () {
    final workout = mapManualWorkoutRows([
      {'id': 1, 'date': '2026-09-21', 'title': 'Swim', 'location_type': 'Pool'},
    ]).single;

    expect(workout.locationType, LocationType.gym);
  });

  test('location columns clear the place when there is none', () {
    expect(locationToColumns(LocationType.home, null), {
      'location_type': 'Home',
      'place_name': null,
      'place_address': null,
      'place_lat': null,
      'place_lng': null,
    });
    expect(
      locationToColumns(
        LocationType.gym,
        const Place(name: 'PureGym', address: '1 Ducie St', lat: 1.5, lng: 2),
      ),
      {
        'location_type': 'Gym',
        'place_name': 'PureGym',
        'place_address': '1 Ducie St',
        'place_lat': 1.5,
        'place_lng': 2.0,
      },
    );
  });

  test('every location type round-trips through its label', () {
    for (final type in LocationType.values) {
      expect(LocationType.fromLabel(type.label), type);
    }
    expect(LocationType.fromLabel(null), isNull);
  });
}
