/// Formats a weight without a trailing `.0`: `80`, `82.5`.
String formatWeight(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
