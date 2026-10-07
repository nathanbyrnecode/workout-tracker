import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/util/date_format.dart';

void main() {
  test('short dates are DD/MM/YY', () {
    expect(formatShortDate(DateTime(2026, 10, 6)), '06/10/26');
    expect(formatShortDate(DateTime(2027, 1, 31)), '31/01/27');
  });

  test('clock times are zero-padded 24-hour', () {
    expect(formatClockTime(DateTime(2026, 10, 6, 9, 5)), '09:05');
    expect(formatClockTime(DateTime(2026, 10, 6, 23, 59)), '23:59');
  });

  test('month and weekday names', () {
    expect(monthName(10), 'October');
    expect(shortMonthName(9), 'Sept');
    expect(shortMonthName(10), 'Oct');
    expect(shortWeekdayName(DateTime(2026, 10, 2).weekday), 'Fri');
  });

  test('a day is labelled relative to today', () {
    final today = DateTime(2026, 10, 7, 15);
    expect(relativeDayLabel(DateTime(2026, 10, 7), today: today), 'Today');
    expect(
        relativeDayLabel(DateTime(2026, 10, 6, 23), today: today), 'Yesterday');
    expect(
      relativeDayLabel(DateTime(2026, 10, 5), today: today),
      'Monday 5 October',
    );
    expect(
      relativeDayLabel(DateTime(2026, 9, 21), today: today),
      'Monday 21 September',
    );
  });

  test('dayOf drops the time', () {
    expect(dayOf(DateTime(2026, 10, 7, 23, 59, 59)), DateTime(2026, 10, 7));
  });

  test('long dates spell out the month', () {
    expect(formatLongDate(DateTime(2026, 9, 21)), 'Mon 21 September 2026');
    expect(formatLongDate(DateTime(2026, 10, 4)), 'Sun 4 October 2026');
  });

  test('stamp dates are two-digit day, short month, year, in capitals', () {
    expect(formatStampDate(DateTime(2026, 10, 6)), '06 OCT 2026');
    expect(formatStampDate(DateTime(2026, 9, 21)), '21 SEPT 2026');
  });
}
