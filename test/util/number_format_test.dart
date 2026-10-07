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

  test('volumes keep at most one decimal place', () {
    expect(formatVolume(67.5), '67.5');
    expect(formatVolume(1067.5), '1,067.5');
    expect(formatVolume(412.0), '412');
    expect(formatVolume(99.96), '100');
    expect(formatVolume(999.96), '1,000');
    expect(formatVolume(12.34), '12.3');
  });

  test('elapsed time reads as seconds, then minutes and seconds', () {
    expect(formatElapsed(Duration.zero), '0s');
    expect(formatElapsed(const Duration(seconds: 45)), '45s');
    expect(formatElapsed(const Duration(seconds: 60)), '1m 0s');
    expect(formatElapsed(const Duration(minutes: 1, seconds: 18)), '1m 18s');
    expect(formatElapsed(const Duration(hours: 1, minutes: 2, seconds: 5)),
        '62m 5s');
    expect(formatElapsed(const Duration(seconds: -5)), '0s');
  });
}
