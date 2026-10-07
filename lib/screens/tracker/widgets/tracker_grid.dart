import 'package:flutter/material.dart';
import 'package:gym_tracker_app/data/tracker_stats.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/date_format.dart';

/// The contribution grid: 17 weeks across, Monday to Sunday down, one square
/// per day coloured by how much was logged. Tapping a past or present day
/// selects it; future days are outlined and cannot be picked.
class TrackerGrid extends StatelessWidget {
  const TrackerGrid({
    super.key,
    required this.days,
    required this.today,
    required this.selected,
    required this.onSelected,
  });

  final TrackerDays days;
  final DateTime today;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  static const square = 14.0;
  static const gap = 3.0;
  static const _pitch = square + gap;

  /// Height of the month labels above the squares, with the gap under them.
  static const _labelBand = 15.0 + gap;

  /// Width of the M / W / F / S column, with the gap after it.
  static const _dayLabels = 12.0;

  static const width = _dayLabels + trackerWeeks * _pitch - gap;
  static const height = _labelBand + 7 * _pitch - gap;

  /// Where the square for column [week] and row [weekday] is drawn.
  static Rect cellRect(int week, int weekday) => Rect.fromLTWH(
        _dayLabels + week * _pitch,
        _labelBand + weekday * _pitch,
        square,
        square,
      );

  void _handleTap(Offset position) {
    for (var week = 0; week < trackerWeeks; week++) {
      for (var weekday = 0; weekday < 7; weekday++) {
        // Half the gap on each side counts, so there are no dead strips.
        if (cellRect(week, weekday).inflate(gap / 2).contains(position)) {
          final day = trackerGridDay(today, week, weekday);
          if (!day.isAfter(dayOf(today))) {
            onSelected(day);
          }
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: 'Activity over the last $trackerWeeks weeks. '
          '${relativeDayLabel(selected, today: today)} is selected.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => _handleTap(details.localPosition),
        child: CustomPaint(
          size: const Size(width, height),
          painter: _TrackerGridPainter(
            days: days,
            today: dayOf(today),
            selected: dayOf(selected),
            tokens: t,
            labelStyle: AppTypography.monoSmall.copyWith(
              fontSize: 9,
              color: t.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackerGridPainter extends CustomPainter {
  _TrackerGridPainter({
    required this.days,
    required this.today,
    required this.selected,
    required this.tokens,
    required this.labelStyle,
  });

  final TrackerDays days;
  final DateTime today;
  final DateTime selected;
  final AppTokens tokens;
  final TextStyle labelStyle;

  void _text(Canvas canvas, String text, Offset topLeft, double lineHeight) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(
      canvas,
      topLeft + Offset(0, (lineHeight - painter.height) / 2),
    );
    painter.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(tokens.radii.trackerSquare);

    const rowLabels = {0: 'M', 2: 'W', 4: 'F', 6: 'S'};
    for (final MapEntry(key: row, value: label) in rowLabels.entries) {
      _text(
        canvas,
        label,
        Offset(0, TrackerGrid.cellRect(0, row).top),
        TrackerGrid.square,
      );
    }

    final months = trackerMonthLabels(today);
    for (var week = 0; week < trackerWeeks; week++) {
      final month = months[week];
      if (month != null) {
        _text(
          canvas,
          shortMonthName(month),
          Offset(TrackerGrid.cellRect(week, 0).left, 0),
          11,
        );
      }
    }

    Rect? selectedRect;
    for (var week = 0; week < trackerWeeks; week++) {
      for (var weekday = 0; weekday < 7; weekday++) {
        final day = trackerGridDay(today, week, weekday);
        final rect = TrackerGrid.cellRect(week, weekday);
        final shape = RRect.fromRectAndRadius(rect, radius);
        if (day.isAfter(today)) {
          // A future day: clear, with a 1px ring inside its edge.
          canvas.drawRRect(
            shape.deflate(0.5),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = tokens.line,
          );
        } else {
          canvas.drawRRect(
            shape,
            Paint()..color = tokens.heat(heatLevel(days[day])),
          );
        }
        if (day == selected) {
          selectedRect = rect;
        }
      }
    }

    // Drawn last so its ring sits over the neighbouring squares: a 2px gap in
    // the page colour, then a 1.5px ring in the text colour.
    if (selectedRect != null) {
      final shape = RRect.fromRectAndRadius(selectedRect, radius);
      canvas
        ..drawRRect(
          shape.inflate(2.75),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = tokens.fg,
        )
        ..drawRRect(
          shape.inflate(1),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = tokens.bg,
        );
    }
  }

  @override
  bool shouldRepaint(_TrackerGridPainter oldDelegate) =>
      days != oldDelegate.days ||
      today != oldDelegate.today ||
      selected != oldDelegate.selected ||
      tokens != oldDelegate.tokens;
}
