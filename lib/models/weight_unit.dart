/// The unit a set's weight was entered in.
enum WeightUnit {
  kg(step: 2.5),
  lb(step: 5);

  const WeightUnit({required this.step});

  static const poundsPerKilogram = 2.20462;

  /// How far the set sheet's − and + buttons move the weight.
  final double step;

  WeightUnit get other => this == kg ? lb : kg;

  /// [weight], given in this unit, in kilograms. Not rounded, because volume
  /// is worked out from it.
  double toKg(double weight) =>
      this == kg ? weight : weight / poundsPerKilogram;

  /// [weight], given in this unit, in [target], to the nearest 0.5.
  double convert(double weight, WeightUnit target) {
    if (target == this) {
      return weight;
    }
    return roundToHalf(
      target == lb ? weight * poundsPerKilogram : weight / poundsPerKilogram,
    );
  }

  /// Reads a stored unit. Anything saved before units existed is in kg.
  static WeightUnit fromName(Object? value) => value == lb.name ? lb : kg;
}

double roundToHalf(double value) => (value * 2).round() / 2;
