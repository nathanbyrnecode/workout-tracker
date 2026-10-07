class ExerciseSet {
  final double _weight;
  final int _reps;
  final int _id;
  final DateTime? _savedAt;

  ExerciseSet(double weight, int reps, int id, {DateTime? savedAt})
      : _weight = weight,
        _reps = reps,
        _id = id,
        _savedAt = savedAt;

  /// In kilograms.
  double get weight => _weight;
  int get reps => _reps;
  int get id => _id;

  /// Null for sets saved before timestamps were recorded.
  DateTime? get savedAt => _savedAt;
}
