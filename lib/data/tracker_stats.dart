import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/util/date_format.dart';

/// Something that makes a day count as logged on the tracker.
sealed class TrackerEntry {
  const TrackerEntry();
}

/// A finished, recorded workout with at least one saved set.
class RecordedEntry extends TrackerEntry {
  const RecordedEntry(this.workout, this.totals);

  final Workout workout;
  final WorkoutTotals totals;
}

/// The workout in progress, once it has at least one saved set.
class LiveEntry extends TrackerEntry {
  const LiveEntry(this.totals);

  final WorkoutTotals totals;
}

/// A workout logged by hand.
class ManualEntry extends TrackerEntry {
  const ManualEntry(this.workout);

  final ManualWorkout workout;
}

/// Entries per calendar day (local midnight). Within a day they are ordered
/// recorded workouts, then the live workout, then manual entries.
typedef TrackerDays = Map<DateTime, List<TrackerEntry>>;

const trackerWeeks = 17;

/// Builds the per-day map the whole Tracker is derived from.
///
/// A recorded workout counts only if it has a saved set. The live workout
/// counts from its first saved set, before it is ended, on the day it started.
TrackerDays buildTrackerDays({
  required Iterable<Workout> workouts,
  required Iterable<ManualWorkout> manualWorkouts,
  DateTime? liveStart,
  WorkoutTotals? liveTotals,
}) {
  final recorded = <DateTime, List<TrackerEntry>>{};
  for (final workout in workouts) {
    final start = workout.startTime;
    if (start == null) {
      continue;
    }
    final totals = workoutTotals(workout.exercises.values);
    if (totals.sets > 0) {
      recorded.putIfAbsent(dayOf(start), () => []).add(
            RecordedEntry(workout, totals),
          );
    }
  }
  // Earliest first within a day.
  for (final entries in recorded.values) {
    entries.sort((a, b) => (a as RecordedEntry)
        .workout
        .startTime!
        .compareTo((b as RecordedEntry).workout.startTime!));
  }

  final days = <DateTime, List<TrackerEntry>>{...recorded};
  if (liveStart != null && liveTotals != null && liveTotals.sets > 0) {
    days.putIfAbsent(dayOf(liveStart), () => []).add(LiveEntry(liveTotals));
  }
  for (final manual in manualWorkouts) {
    days.putIfAbsent(dayOf(manual.date), () => []).add(ManualEntry(manual));
  }
  return days;
}

/// Heat level 0–3 for a day's entries, by the sets recorded that day:
/// 1–5 sets is 1, 6–9 is 2, 10 or more is 3. A day with only manual entries
/// is 2. No entries is 0.
int heatLevel(List<TrackerEntry>? entries) {
  if (entries == null || entries.isEmpty) {
    return 0;
  }
  var sets = 0;
  for (final entry in entries) {
    sets += switch (entry) {
      RecordedEntry(:final totals) => totals.sets,
      LiveEntry(:final totals) => totals.sets,
      ManualEntry() => 0,
    };
  }
  if (sets == 0) {
    return 2;
  }
  return sets <= 5
      ? 1
      : sets <= 9
          ? 2
          : 3;
}

/// The Monday that starts the grid: the Monday of [today]'s week, 16 weeks
/// back, so the last of the 17 columns is the current week.
DateTime trackerGridStart(DateTime today) {
  final day = dayOf(today);
  return DateTime(
    day.year,
    day.month,
    day.day - (day.weekday - 1) - (trackerWeeks - 1) * 7,
  );
}

/// The day in column [week] (0–16) and row [weekday] (0 = Monday).
DateTime trackerGridDay(DateTime today, int week, int weekday) {
  final start = trackerGridStart(today);
  // Built from fields, not by adding durations, so a clock change in the
  // range cannot shift a day.
  return DateTime(start.year, start.month, start.day + week * 7 + weekday);
}

/// The month to label above each column: the month of a 1st that falls in
/// that week, otherwise null.
List<int?> trackerMonthLabels(DateTime today) => [
      for (var week = 0; week < trackerWeeks; week++)
        () {
          for (var weekday = 0; weekday < 7; weekday++) {
            final day = trackerGridDay(today, week, weekday);
            if (day.day == 1) {
              return day.month;
            }
          }
          return null;
        }(),
    ];

/// Consecutive logged days ending today, or ending yesterday when today is
/// not logged yet.
int trackerStreak(TrackerDays days, DateTime today) {
  var day = dayOf(today);
  if (!days.containsKey(day)) {
    day = DateTime(day.year, day.month, day.day - 1);
  }
  var streak = 0;
  while (days.containsKey(day)) {
    streak++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return streak;
}

/// Logged days in [today]'s month.
int trackerDaysThisMonth(TrackerDays days, DateTime today) => days.keys
    .where((day) => day.year == today.year && day.month == today.month)
    .length;
