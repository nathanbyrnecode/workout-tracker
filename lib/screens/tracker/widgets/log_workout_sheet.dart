import 'package:flutter/material.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/date_format.dart';
import 'package:gym_tracker_app/widgets/app_bottom_sheet.dart';
import 'package:gym_tracker_app/widgets/workout_form_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Logs a workout that was not recorded in the app. [onAdd] saves it for the
/// chosen day and reports whether that worked; the sheet closes on success
/// and stays open with a message otherwise. Completes with true when a
/// workout was added.
///
/// The date starts on [initialDay] and cannot go past [today].
Future<bool?> showLogWorkoutSheet({
  required BuildContext context,
  required DateTime initialDay,
  required DateTime today,
  required LocationType initialType,
  required Future<bool> Function(DateTime day, WorkoutDetails details) onAdd,
}) {
  return showAppSheet<bool>(
    context: context,
    children: (sheetContext) => [
      _LogWorkoutForm(
        initialDay: dayOf(initialDay),
        today: dayOf(today),
        initialType: initialType,
        onAdd: onAdd,
      ),
    ],
  );
}

class _LogWorkoutForm extends StatefulWidget {
  const _LogWorkoutForm({
    required this.initialDay,
    required this.today,
    required this.initialType,
    required this.onAdd,
  });

  final DateTime initialDay;
  final DateTime today;
  final LocationType initialType;
  final Future<bool> Function(DateTime day, WorkoutDetails details) onAdd;

  @override
  State<_LogWorkoutForm> createState() => _LogWorkoutFormState();
}

class _LogWorkoutFormState extends State<_LogWorkoutForm> {
  late DateTime _day = widget.initialDay.isAfter(widget.today)
      ? widget.today
      : widget.initialDay;

  void _step(int days) {
    final next = DateTime(_day.year, _day.month, _day.day + days);
    if (!next.isAfter(widget.today)) {
      setState(() => _day = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return WorkoutForm(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          const Text('Log a workout', style: AppTypography.sheetTitle),
          Text(
            "For workouts you didn't record in the app.",
            style: AppTypography.bodyMedium.copyWith(color: t.muted),
          ),
        ],
      ),
      leading: _DateStepper(
        day: _day,
        today: widget.today,
        onPrevious: () => _step(-1),
        onNext: () => _step(1),
      ),
      initial: (title: '', type: widget.initialType, place: null),
      namePlaceholder: 'e.g. Morning run',
      confirmLabel: 'Add workout',
      busyLabel: 'Adding…',
      cancelLabel: 'Cancel',
      showCancel: false,
      failureMessage:
          'Could not add the workout. Check your connection and try again.',
      onConfirm: (details) => widget.onAdd(_day, details),
    );
  }
}

class _DateStepper extends StatelessWidget {
  const _DateStepper({
    required this.day,
    required this.today,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime day;
  final DateTime today;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final atToday = !day.isBefore(today);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: t.card2,
        borderRadius: BorderRadius.circular(t.radii.card),
      ),
      child: Row(
        spacing: t.spacing.gap8,
        children: [
          _StepButton(
            icon: LucideIcons.chevronLeft,
            label: 'Previous day',
            onPressed: onPrevious,
          ),
          Expanded(
            child: Column(
              spacing: 2,
              children: [
                Text(
                  relativeDayLabel(day, today: today),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardTitle.copyWith(fontSize: 18),
                ),
                Text(
                  formatStampDate(day),
                  style: AppTypography.labelWide.copyWith(
                    letterSpacing: 1.32,
                    color: t.muted,
                  ),
                ),
              ],
            ),
          ),
          Opacity(
            opacity: atToday ? 0.3 : 1,
            child: _StepButton(
              icon: LucideIcons.chevronRight,
              label: 'Next day',
              // There is no logging a workout that has not happened yet.
              onPressed: atToday ? null : onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: Material(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radii.iconButton),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: t.spacing.iconButton,
            height: t.spacing.iconButton,
            child: Icon(icon, size: 18, color: t.fg),
          ),
        ),
      ),
    );
  }
}
