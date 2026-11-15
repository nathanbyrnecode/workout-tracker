import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/workout_json.dart';
import 'package:gym_tracker_app/data/workout_upload.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:gym_tracker_app/models/workout.dart';

final start = DateTime(2026, 11, 15, 9);

Exercise exercise(
  int id,
  String name,
  int startMinute,
  List<(double, int, int)> sets, {
  int? endMinute,
}) {
  final exercise = Exercise(
    name,
    {
      for (final (weight, reps, minute) in sets)
        id * 10 + minute: ExerciseSet(
          weight,
          reps,
          id * 10 + minute,
          savedAt: start.add(Duration(minutes: minute)),
        ),
    },
    id,
    start.add(Duration(minutes: startMinute)),
  );
  if (endMinute != null) {
    exercise.setEndTime(start.add(Duration(minutes: endMinute)));
  }
  return exercise;
}

void main() {
  group('active workout', () {
    test('round-trips finished and current exercises, in order', () {
      final json = encodeActiveWorkout(
        userId: 'user-a',
        id: 'w1',
        startTime: start,
        exercises: [
          exercise(1, 'Squat', 1, [(100, 5, 2), (105, 5, 4)], endMinute: 5),
        ],
        currentExercise: exercise(2, 'Bench press', 6, [(80, 8, 7)]),
      );
      expect(json['version'], workoutJsonVersion);
      expect(storedUserId(json), 'user-a');
      expect(json['start_time'], start.toUtc().toIso8601String());

      final active = decodeActiveWorkout(json);
      expect(active.id, 'w1');
      expect(active.startTime, start);
      expect(active.exercises.single.name, 'Squat');
      expect(active.exercises.single.endTime,
          start.add(const Duration(minutes: 5)));
      expect(active.exercises.single.sets.values.map((set) => set.weight),
          [100, 105]);
      expect(active.currentExercise?.name, 'Bench press');
      expect(active.currentExercise?.endTime, isNull);
      expect(active.currentExercise?.sets.values.single.savedAt,
          start.add(const Duration(minutes: 7)));
    });

    test('an unknown version or missing fields are refused', () {
      final json = encodeActiveWorkout(
        userId: 'user-a',
        id: 'w1',
        startTime: start,
        exercises: const [],
        currentExercise: null,
      );
      expect(() => decodeActiveWorkout({...json, 'version': 2}),
          throwsFormatException);
      expect(() => decodeActiveWorkout({...json, 'start_time': null}),
          throwsFormatException);
      expect(
        () => decodeActiveWorkout({
          ...json,
          'exercises': [
            {'id': 1, 'name': 'Squat'}
          ],
        }),
        throwsFormatException,
      );
    });
  });

  group('finished workout', () {
    test('is the save_workout payload, exercises in the order done', () {
      final workout = Workout(
        'w1',
        start,
        start.add(const Duration(hours: 1)),
        {
          // Out of order on purpose.
          2: exercise(2, 'Bench press', 20, [(80, 8, 21)], endMinute: 25),
          1: exercise(1, 'Squat', 1, [(100, 5, 2), (105, 5, 4)], endMinute: 5),
        },
        title: 'Leg day',
        locationType: LocationType.park,
        place: const Place(name: 'Mayfield Park', lat: 53.47, lng: -2.22),
      );
      final json = encodeWorkout(workout, userId: 'user-a');

      expect(json['id'], 'w1');
      expect(json['end_time'],
          start.add(const Duration(hours: 1)).toUtc().toIso8601String());
      expect(json['title'], 'Leg day');
      expect(json['location_type'], 'Park');
      expect(json['place_name'], 'Mayfield Park');
      expect(json['place_lat'], 53.47);
      final exercises = json['exercises'] as List;
      expect(
          exercises.map((e) => (e as Map)['name']), ['Squat', 'Bench press']);
      final squatSets = (exercises.first as Map)['sets'] as List;
      expect(squatSets.map((s) => (s as Map)['weight']), [100, 105]);
      expect((squatSets.first as Map)['created_at'],
          start.add(const Duration(minutes: 2)).toUtc().toIso8601String());

      final decoded = decodeWorkout(json);
      expect(decoded.id, 'w1');
      expect(decoded.synced, isFalse);
      expect(decoded.title, 'Leg day');
      expect(decoded.locationType, LocationType.park);
      expect(decoded.place?.name, 'Mayfield Park');
      expect(decoded.exercises.values.map((e) => e.name),
          ['Squat', 'Bench press']);
      expect(decoded.exercises[1]?.sets.length, 2);
    });

    test('an unfinished workout cannot be encoded', () {
      expect(
        () => encodeWorkout(Workout('w1', start, null, {}), userId: 'user-a'),
        throwsArgumentError,
      );
    });
  });

  group('logged workout', () {
    test('round-trips and gives the row to insert', () {
      final logged = ManualWorkout(
        id: 'm1',
        date: DateTime(2026, 11, 14),
        title: 'Swim',
        locationType: LocationType.other,
        createdAt: DateTime.utc(2026, 11, 15, 8).toLocal(),
      );
      final json = encodeManualWorkout(logged, userId: 'user-a');
      expect(manualWorkoutRow(json), {
        'user_id': 'user-a',
        'id': 'm1',
        'date': '2026-11-14',
        'title': 'Swim',
        'location_type': 'Other',
        'place_name': null,
        'place_address': null,
        'place_lat': null,
        'place_lng': null,
        'created_at': '2026-11-15T08:00:00.000Z',
      });

      final decoded = decodeManualWorkout(json);
      expect(decoded.id, 'm1');
      expect(decoded.date, DateTime(2026, 11, 14));
      expect(decoded.synced, isFalse);
      expect(decoded.createdAt?.toUtc(), DateTime.utc(2026, 11, 15, 8));
    });
  });

  group('a workout found after 12 hours', () {
    ActiveWorkoutJson active({
      List<Exercise> exercises = const [],
      Exercise? current,
    }) =>
        (
          id: 'w1',
          startTime: start,
          exercises: exercises,
          currentExercise: current,
        );

    test('ends at the last set of the exercise still in progress', () {
      final finished = finishExpiredWorkout(
        active(
          exercises: [
            exercise(1, 'Squat', 1, [(100, 5, 2)], endMinute: 10),
          ],
          current: exercise(2, 'Bench press', 12, [(80, 8, 15), (80, 8, 18)]),
        ),
        locationType: LocationType.home,
      )!;
      expect(finished.id, 'w1');
      expect(finished.endTime, start.add(const Duration(minutes: 18)));
      expect(finished.exercises[2]?.endTime,
          start.add(const Duration(minutes: 18)));
      expect(finished.title, 'Workout');
      expect(finished.locationType, LocationType.home);
      expect(finished.synced, isFalse);
    });

    test('drops an exercise in progress with no sets', () {
      final finished = finishExpiredWorkout(
        active(
          exercises: [
            exercise(1, 'Squat', 1, [(100, 5, 2)], endMinute: 10),
          ],
          current: exercise(2, 'Bench press', 40, []),
        ),
        locationType: LocationType.gym,
      )!;
      expect(finished.exercises.keys, [1]);
      expect(finished.endTime, start.add(const Duration(minutes: 10)));
    });

    test('with nothing recorded, is dropped', () {
      expect(
        finishExpiredWorkout(
          active(current: exercise(2, 'Bench press', 40, [])),
          locationType: LocationType.gym,
        ),
        isNull,
      );
    });
  });
}
