import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/screens/home/widgets/timer_count.dart';

void main() {
  test('workout timer includes hours even for a short workout', () {
    expect(
        formatTimerDuration(const Duration(minutes: 5, seconds: 3),
            includeHours: true),
        '00:05:03');
  });

  test('short exercise timer shows minutes and seconds', () {
    expect(
        formatTimerDuration(const Duration(minutes: 5, seconds: 3)), '05:03');
  });

  test('restored exercise timers do not wrap after an hour', () {
    expect(
        formatTimerDuration(const Duration(hours: 8, minutes: 20, seconds: 5)),
        '08:20:05');
  });

  test('clock skew never displays negative elapsed time', () {
    expect(formatTimerDuration(const Duration(seconds: -5)), '00:00');
  });
}
