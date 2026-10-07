import 'package:flutter/material.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/widgets/app_bottom_sheet.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';
import 'package:gym_tracker_app/widgets/location_section.dart';
import 'package:gym_tracker_app/widgets/workout_name_field.dart';

/// What the user entered about a workout: its name and where it was.
typedef WorkoutDetails = ({String title, LocationType type, Place? place});

/// Changes a workout's name and location, for recorded and manual workouts
/// alike. [onSave] does the saving and reports whether it worked; the sheet
/// closes on success and stays open with a message otherwise. Completes with
/// true when the change was saved.
Future<bool?> showEditWorkoutSheet({
  required BuildContext context,
  required WorkoutDetails initial,
  required Future<bool> Function(WorkoutDetails details) onSave,
}) {
  return showAppSheet<bool>(
    context: context,
    children: (sheetContext) => [
      WorkoutForm(
        header: const Text('Edit workout', style: AppTypography.sheetTitle),
        initial: initial,
        namePlaceholder: 'Workout name',
        confirmLabel: 'Save changes',
        busyLabel: 'Saving…',
        cancelLabel: 'Cancel',
        failureMessage:
            'Could not save the changes. Check your connection and try again.',
        onConfirm: onSave,
      ),
    ],
  );
}

/// Asks before deleting a workout. Completes with true only on confirm.
Future<bool?> showDeleteWorkoutSheet({
  required BuildContext context,
  required String workoutName,
}) {
  return showAppSheet<bool>(
    context: context,
    children: (sheetContext) {
      final t = sheetContext.tokens;
      return [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            const Text('Delete workout?', style: AppTypography.cardTitleLarge),
            Text(
              '“$workoutName” will be removed from your history and the '
              'tracker.',
              style: AppTypography.body.copyWith(color: t.muted, height: 1.45),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            AppButton(
              label: 'Delete workout',
              style: AppButtonStyle.danger,
              onPressed: () => Navigator.of(sheetContext).pop(true),
            ),
            AppButton(
              label: 'Cancel',
              style: AppButtonStyle.neutral,
              onPressed: () => Navigator.of(sheetContext).pop(false),
            ),
          ],
        ),
      ];
    },
  );
}

/// The body shared by the End and Edit workout sheets: a header, the
/// required name, the location section, a confirm button that is disabled
/// until there is a name, and a cancel button.
class WorkoutForm extends StatefulWidget {
  const WorkoutForm({
    super.key,
    required this.header,
    required this.initial,
    required this.namePlaceholder,
    required this.confirmLabel,
    required this.busyLabel,
    required this.cancelLabel,
    required this.failureMessage,
    required this.onConfirm,
    this.confirmStyle = AppButtonStyle.accent,
    this.confirmHeight,
  });

  final Widget header;
  final WorkoutDetails initial;
  final String namePlaceholder;
  final String confirmLabel;

  /// Shown on the confirm button while [onConfirm] runs.
  final String busyLabel;
  final String cancelLabel;

  /// Shown when [onConfirm] reports failure.
  final String failureMessage;
  final Future<bool> Function(WorkoutDetails details) onConfirm;
  final AppButtonStyle confirmStyle;
  final double? confirmHeight;

  @override
  State<WorkoutForm> createState() => _WorkoutFormState();
}

class _WorkoutFormState extends State<WorkoutForm> {
  late final _title = TextEditingController(text: widget.initial.title);
  late LocationType _type = widget.initial.type;
  late Place? _place = widget.initial.place;
  bool _busy = false;
  bool _failed = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final title = _title.text.trim();
    if (title.isEmpty || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _failed = false;
    });
    final saved =
        await widget.onConfirm((title: title, type: _type, place: _place));
    if (!mounted) {
      return;
    }
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: t.spacing.gap18,
      children: [
        widget.header,
        WorkoutNameField(
          controller: _title,
          placeholder: widget.namePlaceholder,
        ),
        LocationSection(
          type: _type,
          onTypeChanged: (type) => setState(() => _type = type),
          place: _place,
          onPlaceChanged: (place) => setState(() => _place = place),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: t.spacing.gap8,
          children: [
            if (_failed)
              Text(
                widget.failureMessage,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: t.danger),
              ),
            // Rebuilds as the name changes, to enable and disable itself.
            ListenableBuilder(
              listenable: _title,
              builder: (context, child) => AppButton(
                label: _busy ? widget.busyLabel : widget.confirmLabel,
                style: widget.confirmStyle,
                height: widget.confirmHeight,
                onPressed:
                    _title.text.trim().isEmpty || _busy ? null : _confirm,
              ),
            ),
            AppButton(
              label: widget.cancelLabel,
              style: AppButtonStyle.neutral,
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ],
    );
  }
}
