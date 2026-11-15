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
    this.createdAt,
    this.synced = true,
  });

  /// A UUID the app creates when the workout is logged.
  final String id;

  /// A calendar day in the user's local time, at midnight.
  final DateTime date;
  final String title;
  final LocationType locationType;
  final Place? place;

  /// When it was logged. Orders several entries on one day, newest first.
  /// Null only if the row has no timestamp.
  final DateTime? createdAt;

  /// False while the workout is only on this device and has not reached the
  /// server yet.
  final bool synced;
}
