/// Formats a weight without a trailing `.0`: `80`, `82.5`.
String formatWeight(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

/// Formats a volume as a whole number with thousands separators, the way
/// the design shows every volume: `0`, `412`, `1,732`. Halves round up.
String formatVolume(num value) {
  final whole = value.round();
  final digits = whole.abs().toString();
  final grouped = StringBuffer(whole < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      grouped.write(',');
    }
    grouped.write(digits[i]);
  }
  return grouped.toString();
}

/// A count with its noun: `1 set`, `3 sets`, `1 rep`, `0 reps`.
String formatCount(int count, String noun) =>
    '$count ${count == 1 ? noun : '${noun}s'}';

/// Formats a length of time the way the design writes durations in prose:
/// `45s`, `1m 18s`, and from an hour up `1h 2m`.
String formatElapsed(Duration duration) {
  final seconds = duration.isNegative ? 0 : duration.inSeconds;
  if (seconds < 60) {
    return '${seconds}s';
  }
  if (seconds < 3600) {
    return '${seconds ~/ 60}m ${seconds % 60}s';
  }
  return '${seconds ~/ 3600}h ${seconds % 3600 ~/ 60}m';
}

/// Formats a distance in miles, as the design does: `0.4 mi`, `12 mi`.
String formatDistance(double meters) {
  final miles = meters / 1609.344;
  return miles < 10 ? '${miles.toStringAsFixed(1)} mi' : '${miles.round()} mi';
}
