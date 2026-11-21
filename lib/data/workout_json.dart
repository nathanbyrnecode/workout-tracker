import 'package:gym_tracker_app/data/location_mapper.dart';
import 'package:gym_tracker_app/data/manual_workout_mapper.dart';
import 'package:gym_tracker_app/models/cardio_timer.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';
import 'package:gym_tracker_app/models/weight_unit.dart';
import 'package:gym_tracker_app/models/workout.dart';

/// The JSON kept on the device for the active workout and for workouts that
/// have not reached the server yet (`dev/decisions.md` 21).
///
/// Keys match the server's column names, so a finished workout's JSON is
/// also the `save_workout` payload and a logged workout's JSON holds the
/// `manual_workouts` row. Times are stored in UTC and read back as local
/// time. Decoders throw [FormatException] for anything they cannot read.
const workoutJsonVersion = 1;

/// The active workout: its ID and start, the exercises already finished (in
/// the order they were done) and the one in progress, if any.
typedef ActiveWorkoutJson = ({
  String id,
  DateTime startTime,
  List<Exercise> exercises,
  Exercise? currentExercise,
});

Map<String, dynamic> encodeActiveWorkout({
  required String userId,
  required String id,
  required DateTime startTime,
  required List<Exercise> exercises,
  required Exercise? currentExercise,
}) =>
    {
      'version': workoutJsonVersion,
      'user_id': userId,
      'id': id,
      'start_time': _encodeTime(startTime),
      'exercises': [
        for (final exercise in exercises) _encodeExercise(exercise)
      ],
      'current_exercise':
          currentExercise == null ? null : _encodeExercise(currentExercise),
    };

ActiveWorkoutJson decodeActiveWorkout(Map<String, dynamic> json) {
  _checkVersion(json);
  final current = json['current_exercise'];
  return (
    id: _string(json, 'id'),
    startTime: _time(json, 'start_time'),
    exercises: [
      for (final exercise in _list(json, 'exercises')) _decodeExercise(exercise)
    ],
    currentExercise: current == null ? null : _decodeExercise(current),
  );
}

/// A finished workout. Exercises are written in the order they were done.
Map<String, dynamic> encodeWorkout(Workout workout, {required String userId}) {
  final startTime = workout.startTime;
  final endTime = workout.endTime;
  if (startTime == null || endTime == null) {
    throw ArgumentError('Only a finished workout can be saved.');
  }
  final exercises = workout.exercises.values.toList()
    ..sort((a, b) {
      final byStart = a.startTime.compareTo(b.startTime);
      return byStart != 0 ? byStart : a.id.compareTo(b.id);
    });
  return {
    'version': workoutJsonVersion,
    'user_id': userId,
    'id': workout.id,
    'start_time': _encodeTime(startTime),
    'end_time': _encodeTime(endTime),
    'title': workout.title,
    ...locationToColumns(workout.displayLocationType, workout.place),
    'exercises': [for (final exercise in exercises) _encodeExercise(exercise)],
  };
}

/// Reads a finished workout kept on the device. It is marked as not synced.
Workout decodeWorkout(Map<String, dynamic> json) {
  _checkVersion(json);
  final exercises = <int, Exercise>{};
  for (final row in _list(json, 'exercises')) {
    final exercise = _decodeExercise(row);
    exercises[exercise.id] = exercise;
  }
  return Workout(
    _string(json, 'id'),
    _time(json, 'start_time'),
    _time(json, 'end_time'),
    exercises,
    title: json['title'] as String?,
    locationType: LocationType.fromLabel(json['location_type']),
    place: mapPlaceColumns(json),
    synced: false,
  );
}

Map<String, dynamic> encodeManualWorkout(
  ManualWorkout workout, {
  required String userId,
}) =>
    {
      'version': workoutJsonVersion,
      'user_id': userId,
      'id': workout.id,
      'date': formatCalendarDate(workout.date),
      'title': workout.title,
      ...locationToColumns(workout.locationType, workout.place),
      'created_at': _encodeTime(workout.createdAt ?? DateTime.now()),
    };

/// Reads a logged workout kept on the device. It is marked as not synced.
ManualWorkout decodeManualWorkout(Map<String, dynamic> json) {
  _checkVersion(json);
  final date = parseCalendarDate(json['date']);
  if (date == null) {
    throw const FormatException('A logged workout has no date.');
  }
  return ManualWorkout(
    id: _string(json, 'id'),
    date: date,
    title: _string(json, 'title'),
    locationType:
        LocationType.fromLabel(json['location_type']) ?? LocationType.fallback,
    place: mapPlaceColumns(json),
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal(),
    synced: false,
  );
}

/// The `manual_workouts` row to insert for a logged workout's JSON.
Map<String, dynamic> manualWorkoutRow(Map<String, dynamic> json) => {
      for (final key in const [
        'user_id',
        'id',
        'date',
        'title',
        'location_type',
        'place_name',
        'place_address',
        'place_lat',
        'place_lng',
        'created_at',
      ])
        key: json[key],
    };

/// The user a stored entry belongs to, or null if it does not say.
String? storedUserId(Map<String, dynamic> json) => json['user_id'] as String?;

Map<String, dynamic> _encodeExercise(Exercise exercise) => {
      'id': exercise.id,
      'name': exercise.name,
      'start_time': _encodeTime(exercise.startTime),
      'end_time':
          exercise.endTime == null ? null : _encodeTime(exercise.endTime!),
      'type': exercise.type.name,
      'lap_seconds': [for (final lap in exercise.cardio.laps) lap.inSeconds],
      // Only on the device, so a running timer survives the app being killed.
      if (exercise.isCardio && exercise.endTime == null)
        'cardio_timer': _encodeLiveTimer(exercise.cardio),
      'sets': [
        for (final set in exercise.sets.values)
          {
            'id': set.id,
            'weight': set.weight,
            'reps': set.reps,
            'unit': set.unit.name,
            'created_at':
                set.savedAt == null ? null : _encodeTime(set.savedAt!),
          },
      ],
    };

Map<String, dynamic> _encodeLiveTimer(CardioTimer timer) => {
      'lap_ms': [for (final lap in timer.laps) lap.inMilliseconds],
      'running_since':
          timer.runningSince == null ? null : _encodeTime(timer.runningSince!),
      'paused_at': timer.pausedAt == null ? null : _encodeTime(timer.pausedAt!),
    };

CardioTimer _decodeTimer(Map<String, dynamic> exercise) {
  final live = exercise['cardio_timer'];
  if (live is Map<String, dynamic>) {
    return CardioTimer(
      laps: [
        for (final lap in _list(live, 'lap_ms'))
          Duration(milliseconds: _lapValue(lap)),
      ],
      runningSince:
          live['running_since'] == null ? null : _time(live, 'running_since'),
      pausedAt: live['paused_at'] == null ? null : _time(live, 'paused_at'),
    );
  }
  // Exercises saved before types existed have no laps.
  final seconds = exercise['lap_seconds'];
  if (seconds == null) {
    return const CardioTimer();
  }
  if (seconds is! List) {
    throw const FormatException('Lap times are not a list.');
  }
  return CardioTimer.fromLapSeconds(seconds.map(_lapValue));
}

int _lapValue(Object? value) {
  if (value is! num) {
    throw const FormatException('A lap has no time.');
  }
  return value.toInt();
}

Exercise _decodeExercise(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('An exercise is not a JSON object.');
  }
  final exercise = Exercise(
    _string(value, 'name'),
    {},
    _int(value, 'id'),
    _time(value, 'start_time'),
    type: ExerciseType.fromName(value['type']),
    cardio: _decodeTimer(value),
  );
  if (value['end_time'] != null) {
    exercise.setEndTime(_time(value, 'end_time'));
  }
  for (final set in _list(value, 'sets')) {
    if (set is! Map<String, dynamic>) {
      throw const FormatException('A set is not a JSON object.');
    }
    final weight = set['weight'];
    final reps = set['reps'];
    if (weight is! num || reps is! num) {
      throw const FormatException('A set has no weight or reps.');
    }
    exercise.addSet(ExerciseSet(
      weight.toDouble(),
      reps.toInt(),
      _int(set, 'id'),
      savedAt: set['created_at'] == null ? null : _time(set, 'created_at'),
      unit: WeightUnit.fromName(set['unit']),
    ));
  }
  return exercise;
}

void _checkVersion(Map<String, dynamic> json) {
  if (json['version'] != workoutJsonVersion) {
    throw FormatException('Unknown workout file version: ${json['version']}');
  }
}

String _encodeTime(DateTime time) => time.toUtc().toIso8601String();

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing "$key".');
  }
  return value;
}

int _int(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw FormatException('Missing "$key".');
  }
  return value.toInt();
}

DateTime _time(Map<String, dynamic> json, String key) {
  final value = DateTime.tryParse(json[key] as String? ?? '');
  if (value == null) {
    throw FormatException('Missing or invalid "$key".');
  }
  return value.toLocal();
}

List<Object?> _list(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) {
    throw FormatException('Missing "$key".');
  }
  return value;
}
