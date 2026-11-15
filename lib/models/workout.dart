import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/place.dart';

class Workout {
  static const fallbackTitle = 'Workout';

  final String _id;
  final DateTime? _startTime;
  final DateTime? _endTime;
  final Map<int, Exercise> _exercises;
  final String? _title;
  final LocationType? _locationType;
  final Place? _place;
  final bool _synced;

  Workout(
    this._id,
    this._startTime,
    this._endTime,
    this._exercises, {
    String? title,
    LocationType? locationType,
    Place? place,
    bool synced = true,
  })  : _title = title,
        _synced = synced,
        _locationType = locationType,
        _place = place;

  /// A UUID the app creates when the workout starts.
  String get id => _id;
  DateTime? get startTime => _startTime;
  DateTime? get endTime => _endTime;
  Map<int, Exercise> get exercises => _exercises;

  /// Null for workouts saved before titles existed.
  String? get title => _title;

  /// Null for workouts saved before locations existed.
  LocationType? get locationType => _locationType;
  Place? get place => _place;

  /// False while the workout is only on this device and has not reached the
  /// server yet.
  bool get synced => _synced;

  String get displayTitle {
    final title = _title?.trim();
    return title == null || title.isEmpty ? fallbackTitle : title;
  }

  LocationType get displayLocationType =>
      _locationType ?? LocationType.fallback;

  void addExercise(Exercise exercise) {
    if (!_exercises.containsKey(exercise.id)) {
      _exercises[exercise.id] = exercise;
    }
  }

  void addSet(ExerciseSet set, int exerciseId) {
    if (!_exercises.containsKey(exerciseId) ||
        !_exercises[exerciseId]!.sets.containsKey(set.id)) {
      return;
    }
    _exercises[exerciseId]!.addSet(set);
  }
}
