import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class TimerCount extends ConsumerStatefulWidget {
  const TimerCount({
    super.key,
    required this.startTime,
    this.includeHours = false,
    this.isSecondary = false,
  });

  final DateTime startTime;
  final bool includeHours;
  final bool isSecondary;
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
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsed();
    });
  }

  @override
  void didUpdateWidget(covariant TimerCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startTime != widget.startTime) _updateElapsed();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _updateElapsed();
  }

  void _updateElapsed() {
    setState(() {
      _elapsed = DateTime.now().difference(widget.startTime);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Color.from(alpha: 0.04, red: 1, green: 1, blue: 1)),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 1),
      child: Row(
        spacing: 8,
        children: [
          Text(
            formatTimerDuration(_elapsed, includeHours: widget.includeHours),
            style: GoogleFonts.kodeMono(
              color: widget.isSecondary
                  ? Color.fromRGBO(192, 192, 192, .5)
                  : Color.fromARGB(255, 255, 255, 255),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
