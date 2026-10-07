/// Formats a weight without a trailing `.0`: `80`, `82.5`.
String formatWeight(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

/// Formats a volume with thousands separators and at most one decimal place:
/// `0`, `412`, `1,732`, `1,067.5`.
String formatVolume(num value) {
  final rounded = (value * 10).round() / 10;
  final whole = rounded.truncate();
  final digits = whole.abs().toString();
  final grouped = StringBuffer(whole < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      grouped.write(',');
    }
    grouped.write(digits[i]);
  }
  final tenths = ((rounded - whole).abs() * 10).round();
  return tenths == 0 ? grouped.toString() : '$grouped.$tenths';
}

/// Formats a length of time the way the design writes durations in prose:
/// `45s`, `1m 18s`, `62m 5s`.
String formatElapsed(Duration duration) {
  final seconds = duration.isNegative ? 0 : duration.inSeconds;
  return seconds < 60 ? '${seconds}s' : '${seconds ~/ 60}m ${seconds % 60}s';
}
