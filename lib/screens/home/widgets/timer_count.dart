import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';

/// Shows the time since [startTime] and updates every second. The value is
/// worked out from the clock each tick, so it stays right after the app has
/// been in the background.
class TimerCount extends ConsumerStatefulWidget {
  const TimerCount({
    super.key,
    required this.startTime,
    required this.style,
    this.includeHours = false,
  });

  final DateTime startTime;
  final TextStyle style;
  final bool includeHours;

  @override
  ConsumerState<TimerCount> createState() => _TimerCountState();
}

class _TimerCountState extends ConsumerState<TimerCount>
    with WidgetsBindingObserver {
  late Duration _elapsed;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _elapsed = _measure();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  @override
  void didUpdateWidget(covariant TimerCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startTime != widget.startTime) _update();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _update();
  }

  Duration _measure() => ref.read(clockProvider)().difference(widget.startTime);

  void _update() => setState(() => _elapsed = _measure());

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatTimerDuration(_elapsed, includeHours: widget.includeHours),
      maxLines: 1,
      softWrap: false,
      style: widget.style,
    );
  }
}

String formatTimerDuration(Duration duration, {bool includeHours = false}) {
  final elapsed = duration.isNegative ? Duration.zero : duration;
  final hours = elapsed.inHours.toString().padLeft(2, '0');
  final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
  // Long-running exercises must also show hours after recovery.
  return includeHours || elapsed.inHours > 0
      ? '$hours:$minutes:$seconds'
      : '$minutes:$seconds';
}
