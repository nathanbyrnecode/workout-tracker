import 'package:gym_tracker_app/data/location_mapper.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';

const manualWorkoutColumns = 'id, date, title, $locationColumns';

/// Rows that cannot be read (no date or title) are skipped.
List<ManualWorkout> mapManualWorkoutRows(List<Map<String, dynamic>> rows) {
  final workouts = <ManualWorkout>[];
  for (final row in rows) {
    final date = parseCalendarDate(row['date']);
    final title = row['title'];
    if (date == null || title is! String || title.isEmpty) {
      continue;
    }
    workouts.add(ManualWorkout(
      id: (row['id'] as num).toInt(),
      date: date,
      title: title,
      locationType:
          LocationType.fromLabel(row['location_type']) ?? LocationType.fallback,
      place: mapPlaceColumns(row),
    ));
  }
  return workouts;
}

/// Parses a Postgres `date` (`yyyy-mm-dd`) as a local calendar day. It is not
/// an instant, so it must not be shifted by the device's time zone.
DateTime? parseCalendarDate(Object? value) {
  if (value is! String) {
    return null;
  }
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
  if (match == null) {
    return null;
  }
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

String formatCalendarDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
