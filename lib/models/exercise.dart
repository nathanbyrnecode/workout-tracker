import 'package:gym_tracker_app/models/cardio_timer.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';

class Exercise {
  final String _name;
  final Map<int, ExerciseSet> _sets;
  final int _id;
  final DateTime _startTime;
  final ExerciseType _type;
  final CardioTimer _cardio;
  DateTime? _endTime;

  Exercise(
    String name,
    Map<int, ExerciseSet> sets,
    int id,
    DateTime startTime, {
    ExerciseType type = ExerciseType.strength,
    CardioTimer cardio = const CardioTimer(),
  })  : _name = name,
        _sets = sets,
        _id = id,
        _startTime = startTime,
        _type = type,
        _cardio = cardio;

  String get name => _name;
  Map<int, ExerciseSet> get sets => _sets;
  int get id => _id;
  DateTime get startTime => _startTime;
  DateTime? get endTime => _endTime;
  ExerciseType get type => _type;
  bool get isCardio => _type == ExerciseType.cardio;

  /// The timer and laps of a cardio exercise. Empty for strength.
  CardioTimer get cardio => _cardio;

  /// Whether this is a cardio exercise whose timer has been started.
  bool get hasCardioTime => isCardio && _cardio.laps.isNotEmpty;

  /// A finished cardio exercise's time, which leaves out any pauses.
  Duration get activeTime => _cardio.activeTime(_endTime ?? _startTime);

  Exercise addSet(ExerciseSet set) {
    _sets[set.id] = set;
    return this;
  }

  Exercise setEndTime(DateTime endTime) {
    _endTime = endTime;
    return this;
  }
}
