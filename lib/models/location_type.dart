enum LocationType {
  gym('Gym'),
  home('Home'),
  park('Park'),
  other('Other');

  const LocationType(this.label);

  /// Shown in the UI and stored in the `location_type` columns.
  final String label;

  /// Used where a workout has no saved type, such as rows written before
  /// locations existed.
  static const fallback = LocationType.gym;

  static LocationType? fromLabel(Object? value) {
    for (final type in values) {
      if (type.label == value) {
        return type;
      }
    }
    return null;
  }
}
