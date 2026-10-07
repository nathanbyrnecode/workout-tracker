import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/tracker_stats.dart';
import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';

import '../helpers/fakes.dart';

// Wednesday.
final today = DateTime(2026, 10, 7);

ManualWorkout manual(int id, DateTime date) => ManualWorkout(
      id: id,
      date: date,
      title: 'Morning run',
      locationType: LocationType.park,
    );

List<(double, int)> sets(int count) =>
    [for (var i = 0; i < count; i++) (60, 8)];

const WorkoutTotals noSets = (exercises: 1, sets: 0, reps: 0, volume: 0);
const WorkoutTotals oneSet = (exercises: 1, sets: 1, reps: 8, volume: 480);

TrackerDays daysWithManualOn(Iterable<DateTime> dates) => buildTrackerDays(
      workouts: const [],
      manualWorkouts: [
        for (final (i, date) in dates.indexed) manual(i, date),
      ],
    );

void main() {
  group('which days are logged', () {
    test('a recorded workout counts on the day it started', () {
      final days = buildTrackerDays(
        workouts: [testWorkout(1, DateTime(2026, 10, 6, 23, 30))],
        manualWorkouts: const [],
      );
      expect(days.keys, [DateTime(2026, 10, 6)]);
      expect(days.values.single.single, isA<RecordedEntry>());
    });

    test('a recorded workout with no saved sets does not count', () {
      final days = buildTrackerDays(
        workouts: [
          testWorkout(1, DateTime(2026, 10, 6, 9), exercises: {'Squat': []}),
          testWorkout(2, DateTime(2026, 10, 5, 9), exercises: {}),
        ],
        manualWorkouts: const [],
      );
      expect(days, isEmpty);
    });

    test('the live workout lights its day from the first saved set', () {
      TrackerDays live(WorkoutTotals totals) => buildTrackerDays(
            workouts: const [],
            manualWorkouts: const [],
            liveStart: DateTime(2026, 10, 7, 9, 38),
            liveTotals: totals,
          );

      expect(live(noSets), isEmpty);
      final days = live(oneSet);
      expect(days.keys, [today]);
      expect(days[today]!.single, isA<LiveEntry>());
    });

    test('manual entries count, several to a day', () {
      final days = daysWithManualOn([today, today, DateTime(2026, 10, 5)]);
      expect(days.length, 2);
      expect(days[today], hasLength(2));
    });

    test('a day lists recorded workouts, then live, then manual', () {
      final days = buildTrackerDays(
        workouts: [
          testWorkout(2, DateTime(2026, 10, 7, 18)),
          testWorkout(1, DateTime(2026, 10, 7, 7)),
        ],
        manualWorkouts: [manual(1, today)],
        liveStart: DateTime(2026, 10, 7, 20),
        liveTotals: oneSet,
      );
      final entries = days[today]!;
      expect(entries.map((entry) => entry.runtimeType), [
        RecordedEntry,
        RecordedEntry,
        LiveEntry,
        ManualEntry,
      ]);
      // Recorded workouts are in the order they happened.
      expect((entries[0] as RecordedEntry).workout.id, 1);
      expect((entries[1] as RecordedEntry).workout.id, 2);
    });
  });

  group('heat level', () {
    int levelFor(int setCount) => heatLevel(buildTrackerDays(
          workouts: [
            testWorkout(1, today, exercises: {'Squat': sets(setCount)}),
          ],
          manualWorkouts: const [],
        )[today]);

    test('follows the sets recorded that day', () {
      expect(levelFor(1), 1);
      expect(levelFor(5), 1);
      expect(levelFor(6), 2);
      expect(levelFor(9), 2);
      expect(levelFor(10), 3);
      expect(levelFor(40), 3);
    });

    test('adds sets across workouts and the live workout', () {
      final days = buildTrackerDays(
        workouts: [
          testWorkout(1, today, exercises: {'Squat': sets(4)}),
          testWorkout(2, today, exercises: {'Row': sets(4)}),
        ],
        manualWorkouts: const [],
        liveStart: today,
        liveTotals: (exercises: 1, sets: 2, reps: 16, volume: 960),
      );
      expect(heatLevel(days[today]), 3);
    });

    test('a manual-only day is level 2; an empty day is 0', () {
      expect(heatLevel(daysWithManualOn([today])[today]), 2);
      expect(heatLevel(null), 0);
      expect(heatLevel(const []), 0);
    });

    test('a manual entry does not change a day that has recorded sets', () {
      final days = buildTrackerDays(
        workouts: [
          testWorkout(1, today, exercises: {'Squat': sets(2)})
        ],
        manualWorkouts: [manual(1, today)],
      );
      expect(heatLevel(days[today]), 1);
    });
  });

  group('grid', () {
    test('starts on the Monday 16 weeks before this week', () {
      final start = trackerGridStart(today);
      expect(start.weekday, DateTime.monday);
      expect(start, DateTime(2026, 6, 15));
      // Today is in the last column, on Wednesday's row.
      expect(trackerGridDay(today, 16, 2), today);
      expect(trackerGridDay(today, 16, 0), DateTime(2026, 10, 5));
      expect(trackerGridDay(today, 16, 6), DateTime(2026, 10, 11));
    });

    test('a Monday starts its own week; a Sunday ends one', () {
      final monday = DateTime(2026, 10, 5);
      expect(trackerGridDay(monday, 16, 0), monday);
      final sunday = DateTime(2026, 10, 11);
      expect(trackerGridDay(sunday, 16, 6), sunday);
      expect(trackerGridStart(sunday), trackerGridStart(monday));
    });

    test('every column is seven consecutive days across a clock change', () {
      // The UK leaves summer time on 25 October 2026.
      final afterChange = DateTime(2026, 11, 4);
      var previous = trackerGridDay(afterChange, 0, 0);
      for (var index = 1; index < trackerWeeks * 7; index++) {
        final day = trackerGridDay(afterChange, index ~/ 7, index % 7);
        expect(day.hour, 0);
        expect(
          DateTime(previous.year, previous.month, previous.day + 1),
          day,
        );
        previous = day;
      }
    });

    test('month labels sit above the week containing the 1st', () {
      final labels = trackerMonthLabels(today);
      expect(labels, hasLength(trackerWeeks));
      // 1 Jul, 1 Aug, 1 Sept and 1 Oct 2026 fall in these columns.
      expect(
        {
          for (final (week, month) in labels.indexed)
            if (month != null) week: month,
        },
        {2: 7, 6: 8, 11: 9, 15: 10},
      );
    });
  });

  group('streak', () {
    test('counts back from today when today is logged', () {
      final days = daysWithManualOn([
        today,
        DateTime(2026, 10, 6),
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 3),
      ]);
      expect(trackerStreak(days, today), 3);
    });

    test('counts back from yesterday when today is not logged yet', () {
      final days = daysWithManualOn([
        DateTime(2026, 10, 6),
        DateTime(2026, 10, 5),
      ]);
      expect(trackerStreak(days, today), 2);
    });

    test('is zero when neither today nor yesterday is logged', () {
      expect(
          trackerStreak(daysWithManualOn([DateTime(2026, 10, 5)]), today), 0);
      expect(trackerStreak({}, today), 0);
    });

    test('runs across a month boundary', () {
      final second = DateTime(2026, 10, 2);
      final days = daysWithManualOn([
        second,
        DateTime(2026, 10, 1),
        DateTime(2026, 9, 30),
        DateTime(2026, 9, 29),
      ]);
      expect(trackerStreak(days, second), 4);
    });

    test('ignores the time of day', () {
      final days = daysWithManualOn([today]);
      expect(trackerStreak(days, DateTime(2026, 10, 7, 23, 59)), 1);
    });
  });

  test('days this month and total days', () {
    final days = daysWithManualOn([
      today,
      today,
      DateTime(2026, 10, 1),
      DateTime(2026, 9, 30),
      DateTime(2025, 10, 7),
    ]);
    expect(trackerDaysThisMonth(days, today), 2);
    expect(days.length, 4);
  });
}
