import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';

/// The small upper-case label above a form field, with an optional note at
/// the trailing edge such as REQUIRED or OPTIONAL.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label,
      {super.key, this.note, this.noteIsWarning = false});

  final String label;
  final String? note;

  /// Draws [note] in the danger colour, for a required field that is empty.
  final bool noteIsWarning;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final note = this.note;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(color: t.muted)),
        if (note != null)
          Text(
            note,
            style: AppTypography.labelSmall.copyWith(
              color: noteIsWarning ? t.danger : t.muted,
            ),
          ),
      ],
    );
  }
}
