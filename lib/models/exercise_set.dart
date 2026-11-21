import 'package:gym_tracker_app/models/weight_unit.dart';

class ExerciseSet {
  final double _weight;
  final int _reps;
  final int _id;
  final DateTime? _savedAt;
  final WeightUnit _unit;

  ExerciseSet(
    double weight,
    int reps,
    int id, {
    DateTime? savedAt,
    WeightUnit unit = WeightUnit.kg,
  })  : _weight = weight,
        _reps = reps,
        _id = id,
        _savedAt = savedAt,
        _unit = unit;

  /// In [unit], as it was entered.
  double get weight => _weight;
  int get reps => _reps;
  int get id => _id;

  /// Null for sets saved before timestamps were recorded.
  DateTime? get savedAt => _savedAt;

  WeightUnit get unit => _unit;

  /// [weight] in kilograms, which is what volume is calculated in.
  double get weightKg => _unit.toKg(_weight);
}
