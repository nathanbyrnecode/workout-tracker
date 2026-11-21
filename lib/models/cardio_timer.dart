enum ExerciseType {
  strength,
  cardio;

  /// Reads a stored type. Anything saved before types existed is strength.
  static ExerciseType fromName(Object? value) =>
      value == cardio.name ? cardio : strength;
}

/// Where a cardio exercise's timer is. A finished exercise is one with an end
/// time; its timer is no longer running.
enum CardioStatus { notStarted, running, paused }

/// The time on a cardio exercise.
///
/// Nothing here counts ticks. Each lap holds the time it has banked, and while
/// running [runningSince] says when the open stretch began, so every duration
/// is worked out from the clock. That keeps it right after the app has been in
/// the background or killed. Instances are immutable, and an action that does
/// not apply in the current state returns the same instance.
class CardioTimer {
  const CardioTimer({
    this.laps = const [],
    this.runningSince,
    this.pausedAt,
  });

  /// A finished timer, from the whole seconds saved for each lap.
  factory CardioTimer.fromLapSeconds(Iterable<int> seconds) => CardioTimer(
        laps: [for (final lap in seconds) Duration(seconds: lap)],
      );

  /// The time banked in each lap, in order. The last lap is the current one.
  /// While running it does not include the stretch since [runningSince].
  final List<Duration> laps;

  /// When the open stretch began. Set only while running.
  final DateTime? runningSince;

  /// When the pause began. Set only while paused.
  final DateTime? pausedAt;

  CardioStatus get status {
    if (runningSince != null) {
      return CardioStatus.running;
    }
    return laps.isEmpty ? CardioStatus.notStarted : CardioStatus.paused;
  }

  /// [laps] with the open stretch added to the current lap. A clock moved
  /// backwards counts as no time rather than negative time.
  List<Duration> _banked(DateTime now) {
    final since = runningSince;
    if (since == null || laps.isEmpty) {
      return laps;
    }
    final open = now.difference(since);
    return [
      ...laps.take(laps.length - 1),
      laps.last + (open.isNegative ? Duration.zero : open),
    ];
  }

  /// Each lap's time in whole seconds.
  List<int> lapSeconds(DateTime now) =>
      [for (final lap in _banked(now)) lap.inSeconds];

  /// The sum of the laps as they are shown, so the laps on screen always add
  /// up to the total. Time spent paused never counts.
  Duration activeTime(DateTime now) => Duration(
        seconds: lapSeconds(now).fold(0, (total, lap) => total + lap),
      );

  /// How long the current pause has lasted.
  Duration pausedFor(DateTime now) {
    final since = pausedAt;
    if (since == null) {
      return Duration.zero;
    }
    final paused = now.difference(since);
    return paused.isNegative ? Duration.zero : paused;
  }

  /// Opens lap 1 and starts timing.
  CardioTimer start(DateTime now) => status == CardioStatus.notStarted
      ? CardioTimer(laps: const [Duration.zero], runningSince: now)
      : this;

  /// Banks the open stretch and records when the pause began.
  CardioTimer pause(DateTime now) => status == CardioStatus.running
      ? CardioTimer(laps: _banked(now), pausedAt: now)
      : this;

  /// Carries on timing the current lap.
  CardioTimer resume(DateTime now) => status == CardioStatus.paused
      ? CardioTimer(laps: laps, runningSince: now)
      : this;

  /// Closes the current lap and opens a new one, running. From paused this
  /// also resumes. A current lap under a second is kept instead of closed, so
  /// a double tap cannot leave an empty lap behind.
  CardioTimer newLap(DateTime now) {
    if (status == CardioStatus.notStarted) {
      return this;
    }
    final banked = _banked(now);
    if (banked.last.inSeconds == 0) {
      return resume(now);
    }
    return CardioTimer(laps: [...banked, Duration.zero], runningSince: now);
  }

  /// The timer stopped at [now], in whole seconds per lap.
  CardioTimer finish(DateTime now) => _closed(_banked(now));

  /// The timer of an exercise that was left running and never ended. Nobody
  /// knows when the open stretch really stopped, so it is not counted.
  CardioTimer get abandoned => _closed(laps);

  /// A last lap with no whole seconds was opened by accident or just before
  /// ending, and is not kept.
  static CardioTimer _closed(List<Duration> laps) {
    final seconds = [for (final lap in laps) lap.inSeconds];
    while (seconds.isNotEmpty && seconds.last == 0) {
      seconds.removeLast();
    }
    return CardioTimer.fromLapSeconds(seconds);
  }
}
