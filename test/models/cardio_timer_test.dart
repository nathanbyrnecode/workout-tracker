import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/models/cardio_timer.dart';

void main() {
  final t0 = DateTime(2026, 11, 21, 9);
  DateTime at(int seconds) => t0.add(Duration(seconds: seconds));

  test('a new timer has not started and shows no time', () {
    const timer = CardioTimer();
    expect(timer.status, CardioStatus.notStarted);
    expect(timer.activeTime(at(100)), Duration.zero);
    expect(timer.lapSeconds(at(100)), isEmpty);
  });

  test('start opens lap 1 and times it from the clock', () {
    final timer = const CardioTimer().start(at(0));
    expect(timer.status, CardioStatus.running);
    expect(timer.lapSeconds(at(612)), [612]);
    expect(timer.activeTime(at(612)), const Duration(minutes: 10, seconds: 12));
  });

  test('pause stops timing and measures the pause', () {
    final timer = const CardioTimer().start(at(0)).pause(at(60));
    expect(timer.status, CardioStatus.paused);
    expect(timer.activeTime(at(500)), const Duration(seconds: 60));
    expect(timer.pausedFor(at(102)), const Duration(seconds: 42));
  });

  test('resume carries on the same lap, leaving the pause out', () {
    final timer =
        const CardioTimer().start(at(0)).pause(at(60)).resume(at(100));
    expect(timer.status, CardioStatus.running);
    expect(timer.lapSeconds(at(130)), [90]);
    expect(timer.pausedFor(at(130)), Duration.zero);
  });

  test('new lap while running closes the lap and keeps timing', () {
    final timer = const CardioTimer().start(at(0)).newLap(at(612));
    expect(timer.status, CardioStatus.running);
    expect(timer.lapSeconds(at(707)), [612, 95]);
    expect(timer.activeTime(at(707)), const Duration(seconds: 707));
  });

  test('new lap while paused closes the lap and resumes', () {
    final timer =
        const CardioTimer().start(at(0)).pause(at(612)).newLap(at(700));
    expect(timer.status, CardioStatus.running);
    expect(timer.lapSeconds(at(730)), [612, 30]);
  });

  test('a double tap on new lap does not leave an empty lap', () {
    final first = const CardioTimer().start(at(0)).newLap(at(60));
    final second = first.newLap(at(60).add(const Duration(milliseconds: 200)));
    expect(second.laps, hasLength(2));
    expect(identical(first, second), isTrue);
  });

  test('new lap on a paused lap with no time just resumes', () {
    final timer = const CardioTimer()
        .start(at(0))
        .pause(at(0).add(const Duration(milliseconds: 300)))
        .newLap(at(5));
    expect(timer.status, CardioStatus.running);
    expect(timer.laps, hasLength(1));
  });

  test('sub-second time carries across a pause', () {
    final timer = const CardioTimer()
        .start(at(0))
        .pause(at(0).add(const Duration(milliseconds: 600)))
        .resume(at(10));
    expect(
      timer.lapSeconds(at(10).add(const Duration(milliseconds: 500))),
      [1],
    );
  });

  test('the total is the sum of the laps as shown', () {
    final timer = const CardioTimer()
        .start(at(0))
        .newLap(at(1).add(const Duration(milliseconds: 700)));
    final now = at(3).add(const Duration(milliseconds: 400));
    expect(timer.lapSeconds(now), [1, 1]);
    expect(timer.activeTime(now), const Duration(seconds: 2));
  });

  test('a clock moved backwards never gives negative time', () {
    final timer = const CardioTimer().start(at(100));
    expect(timer.activeTime(at(50)), Duration.zero);
    expect(const CardioTimer().start(at(0)).pause(at(10)).pausedFor(at(5)),
        Duration.zero);
  });

  test('actions that do not apply change nothing', () {
    const fresh = CardioTimer();
    expect(identical(fresh.pause(at(1)), fresh), isTrue);
    expect(identical(fresh.resume(at(1)), fresh), isTrue);
    expect(identical(fresh.newLap(at(1)), fresh), isTrue);

    final running = fresh.start(at(0));
    expect(identical(running.start(at(1)), running), isTrue);
    expect(identical(running.resume(at(1)), running), isTrue);

    final paused = running.pause(at(5));
    expect(identical(paused.pause(at(6)), paused), isTrue);
    expect(identical(paused.start(at(6)), paused), isTrue);
  });

  group('finishing', () {
    test('keeps whole seconds per lap and stops the clock', () {
      final timer = const CardioTimer()
          .start(at(0))
          .newLap(at(612))
          .finish(at(1152).add(const Duration(milliseconds: 900)));
      expect(timer.runningSince, isNull);
      expect(timer.lapSeconds(at(9999)), [612, 540]);
      expect(timer.activeTime(at(9999)), const Duration(seconds: 1152));
    });

    test('with no time leaves no laps', () {
      expect(const CardioTimer().finish(at(5)).laps, isEmpty);
      expect(
        const CardioTimer()
            .start(at(0))
            .finish(at(0).add(const Duration(milliseconds: 500)))
            .laps,
        isEmpty,
      );
    });

    test('drops a last lap with no time', () {
      final timer = const CardioTimer()
          .start(at(0))
          .newLap(at(60))
          .finish(at(60).add(const Duration(milliseconds: 300)));
      expect(timer.lapSeconds(at(100)), [60]);
    });

    test('an abandoned timer does not count the open stretch', () {
      final timer =
          const CardioTimer().start(at(0)).newLap(at(600)).newLap(at(900));
      expect(timer.abandoned.lapSeconds(at(99999)), [600, 300]);
    });

    test('an abandoned timer on its first stretch has no time', () {
      expect(const CardioTimer().start(at(0)).abandoned.laps, isEmpty);
    });

    test('an abandoned paused timer keeps what it had', () {
      final timer = const CardioTimer().start(at(0)).pause(at(600));
      expect(timer.abandoned.lapSeconds(at(99999)), [600]);
    });
  });
}
