import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:gym_tracker_app/models/workout.dart';

import 'fakes.dart';

/// "Now" in the design's screenshots: Tuesday 6 October 2026, 09:41.
final demoNow = DateTime(2026, 10, 6, 9, 41);

const pureGym = Place(
  name: 'PureGym Manchester Piccadilly',
  address: '1 Ducie St, Manchester M1 2JN',
);
const gymGroup = Place(
  name: 'The Gym Group Manchester Central',
  address: '2 Oxford Rd, Manchester M1 5QA',
);
const mayfieldPark = Place(
  name: 'Mayfield Park',
  address: 'Baring St, Manchester M1 2PY',
);

List<(double, int)> _sets(int count, double weight, int reps) =>
    [for (var i = 0; i < count; i++) (weight, reps)];

/// History shaped like the design's: three workouts in October and a run of
/// them through September, plus one from the year before.
List<Workout> demoHistory() => [
      testWorkout(
        1,
        DateTime(2026, 10, 6, 7, 30),
        title: 'Push day',
        type: LocationType.gym,
        place: pureGym,
        exercises: {
          'Bench press': [(60, 8), (65, 6), (70, 6)],
          'Incline DB press': [(22, 10), (24, 8)],
        },
      ),
      testWorkout(
        2,
        DateTime(2026, 10, 5, 18, 5),
        title: 'Pull day',
        type: LocationType.gym,
        place: gymGroup,
        exercises: {'Deadlift': _sets(3, 120, 8)},
      ),
      testWorkout(
        3,
        DateTime(2026, 10, 3, 10),
        title: 'Legs',
        type: LocationType.home,
        exercises: {
          'Goblet squat': _sets(4, 24, 12),
          'Lunge': _sets(3, 16, 10)
        },
      ),
      testWorkout(
        4,
        DateTime(2026, 9, 27, 9),
        title: 'Full body',
        type: LocationType.gym,
        exercises: {
          'Squat': _sets(4, 90, 8),
          'Bench press': _sets(4, 70, 8),
          'Row': _sets(3, 60, 10),
        },
      ),
      testWorkout(
        5,
        DateTime(2026, 9, 26, 9),
        title: 'Park circuit',
        type: LocationType.park,
        place: mayfieldPark,
        exercises: {'Pull-up': _sets(4, 80, 6), 'Dip': _sets(3, 80, 8)},
      ),
      testWorkout(
        6,
        DateTime(2026, 9, 25, 9),
        title: 'Quick session',
        type: LocationType.home,
        exercises: {'Curl': _sets(3, 16, 9)},
      ),
      testWorkout(
        7,
        DateTime(2026, 9, 24, 9),
        title: 'Upper',
        type: LocationType.gym,
        place: pureGym,
        exercises: {
          'Overhead press': _sets(3, 40, 8),
          'Row': _sets(3, 60, 9),
          'Fly': _sets(2, 14, 9),
        },
      ),
      // Saved before titles and locations existed.
      testWorkout(8, DateTime(2026, 9, 22, 9), exercises: {
        'Squat': _sets(5, 100, 5),
      }),
      testWorkout(
        9,
        DateTime(2025, 12, 30, 9),
        title: 'Year end',
        type: LocationType.other,
        exercises: {'Row': _sets(3, 50, 10)},
      ),
    ];

List<ManualWorkout> demoManualWorkouts() => [
      ManualWorkout(
        id: 1,
        date: DateTime(2026, 10, 4),
        title: 'Morning run',
        locationType: LocationType.park,
        place: mayfieldPark,
      ),
      ManualWorkout(
        id: 2,
        date: DateTime(2026, 10, 4),
        title: 'Evening stretch and mobility',
        locationType: LocationType.home,
      ),
      ManualWorkout(
        id: 3,
        date: DateTime(2026, 9, 30),
        title: 'Swim',
        locationType: LocationType.other,
      ),
    ];
