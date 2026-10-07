import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/widgets/app_bottom_sheet.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';
import 'package:gym_tracker_app/widgets/app_text_field.dart';

/// Asks for the name of the exercise to start. Completes with what was typed,
/// trimmed (possibly empty), or null if the sheet was dismissed.
Future<String?> showNewExerciseSheet({required BuildContext context}) {
  return showAppSheet<String>(
    context: context,
    children: (sheetContext) => [const _NewExerciseForm()],
  );
}

/// The name an exercise gets when none was typed: "Exercise N", counting the
/// exercises already in the workout.
String exerciseNameOrDefault(String typed, {required int existingExercises}) {
  final name = typed.trim();
  return name.isEmpty ? 'Exercise ${existingExercises + 1}' : name;
}

class _NewExerciseForm extends StatefulWidget {
  const _NewExerciseForm();

  @override
  State<_NewExerciseForm> createState() => _NewExerciseFormState();
}

class _NewExerciseFormState extends State<_NewExerciseForm> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.of(context).pop(_name.text.trim());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [
        const Text('New exercise', style: AppTypography.sheetTitle),
        AppTextField(
          controller: _name,
          placeholder: 'Exercise name',
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _confirm(),
        ),
        AppButton(label: 'Start exercise', onPressed: _confirm),
      ],
    );
  }
}
