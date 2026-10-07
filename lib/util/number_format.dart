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
/// `45s`, `1m 18s`, `62m 5s`.
String formatElapsed(Duration duration) {
  final seconds = duration.isNegative ? 0 : duration.inSeconds;
  return seconds < 60 ? '${seconds}s' : '${seconds ~/ 60}m ${seconds % 60}s';
}
