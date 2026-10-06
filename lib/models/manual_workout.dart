import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/place.dart';

/// A workout logged after the fact, with no exercises or sets.
class ManualWorkout {
  const ManualWorkout({
    required this.id,
    required this.date,
    required this.title,
    required this.locationType,
    this.place,
  });

  final int id;

  /// A calendar day in the user's local time, at midnight.
  final DateTime date;
  final String title;
  final LocationType locationType;
  final Place? place;
}
