import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/util/number_format.dart';

void main() {
  test('weights drop a trailing .0', () {
    expect(formatWeight(80), '80');
    expect(formatWeight(82.5), '82.5');
    expect(formatWeight(0), '0');
  });

  test('volumes get thousands separators', () {
    expect(formatVolume(0), '0');
    expect(formatVolume(412), '412');
    expect(formatVolume(1732), '1,732');
    expect(formatVolume(1000), '1,000');
    expect(formatVolume(1234567), '1,234,567');
  });

  test('volumes round to a whole number, halves up', () {
    expect(formatVolume(67.5), '68');
    expect(formatVolume(67.4), '67');
    expect(formatVolume(1067.5), '1,068');
    expect(formatVolume(999.5), '1,000');
    expect(formatVolume(412.0), '412');
  });

  test('counts take a singular noun only for one', () {
    expect(formatCount(1, 'set'), '1 set');
    expect(formatCount(3, 'set'), '3 sets');
    expect(formatCount(1, 'rep'), '1 rep');
    expect(formatCount(0, 'rep'), '0 reps');
  });

  test('elapsed time reads as seconds, minutes and seconds, then hours', () {
    expect(formatElapsed(Duration.zero), '0s');
    expect(formatElapsed(const Duration(seconds: 45)), '45s');
    expect(formatElapsed(const Duration(seconds: 60)), '1m 0s');
    expect(formatElapsed(const Duration(minutes: 1, seconds: 18)), '1m 18s');
    expect(formatElapsed(const Duration(minutes: 59, seconds: 59)), '59m 59s');
    expect(formatElapsed(const Duration(hours: 1)), '1h 0m');
    expect(formatElapsed(const Duration(hours: 1, minutes: 2, seconds: 5)),
        '1h 2m');
    expect(formatElapsed(const Duration(seconds: -5)), '0s');
  });

  test('distances are in miles', () {
    expect(formatDistance(644), '0.4 mi');
    expect(formatDistance(805), '0.5 mi');
    expect(formatDistance(1609.344), '1.0 mi');
    expect(formatDistance(40000), '25 mi');
  });
}
