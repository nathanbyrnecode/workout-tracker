import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/place.dart';

const locationColumns =
    'location_type, place_name, place_address, place_lat, place_lng';

/// Reads the `place_*` columns shared by `workouts` and `manual_workouts`.
Place? mapPlaceColumns(Map<String, dynamic> row) {
  final name = row['place_name'];
  if (name is! String || name.isEmpty) {
    return null;
  }
  return Place(
    name: name,
    address: row['place_address'] as String?,
    lat: (row['place_lat'] as num?)?.toDouble(),
    lng: (row['place_lng'] as num?)?.toDouble(),
  );
}

/// Always writes every location column so that clearing a place removes it.
Map<String, dynamic> locationToColumns(LocationType type, Place? place) => {
      'location_type': type.label,
      'place_name': place?.name,
      'place_address': place?.address,
      'place_lat': place?.lat,
      'place_lng': place?.lng,
    };
