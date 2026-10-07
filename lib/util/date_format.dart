const _weekdaysLong = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', //
  'Friday', 'Saturday', 'Sunday',
];
const _weekdaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];
// "Sept" rather than "Sep", as British English writes it and the design shows.
const _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec',
];

String _two(int value) => value.toString().padLeft(2, '0');

/// The calendar day of [time], at local midnight.
DateTime dayOf(DateTime time) => DateTime(time.year, time.month, time.day);

/// `06/10/26`
String formatShortDate(DateTime date) =>
    '${_two(date.day)}/${_two(date.month)}/${_two(date.year % 100)}';

/// `09:38`
String formatClockTime(DateTime time) =>
    '${_two(time.hour)}:${_two(time.minute)}';

/// `October`
String monthName(int month) => _monthsLong[month - 1];

/// `Oct`, `Sept`
String shortMonthName(int month) => _monthsShort[month - 1];

/// `Fri`
String shortWeekdayName(int weekday) => _weekdaysShort[weekday - 1];

/// `Today`, `Yesterday`, or the day in full: `Monday 4 October`.
String relativeDayLabel(DateTime day, {required DateTime today}) {
  final difference = dayOf(today).difference(dayOf(day)).inDays;
  if (difference == 0) {
    return 'Today';
  }
  if (difference == 1) {
    return 'Yesterday';
  }
  return '${_weekdaysLong[day.weekday - 1]} ${day.day} '
      '${_monthsLong[day.month - 1]}';
}
