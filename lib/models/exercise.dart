import 'package:gym_tracker_app/models/exercise_set.dart';

class Exercise {
  final String _name;
  final Map<int, ExerciseSet> _sets;
  final int _id;
  final DateTime _startTime;
  DateTime? _endTime;

  Exercise(
    String name,
    Map<int, ExerciseSet> sets,
    int id,
    DateTime startTime,
  )   : _name = name,
        _sets = sets,
        _id = id,
        _startTime = startTime;

  String get name => _name;
  Map<int, ExerciseSet> get sets => _sets;
  int get id => _id;
  DateTime get startTime => _startTime;
  DateTime? get endTime => _endTime;

  Exercise addSet(ExerciseSet set) {
    _sets[set.id] = set;
    return this;
  }

  Exercise setEndTime(DateTime endTime) {
    _endTime = endTime;
    return this;
  }
}
