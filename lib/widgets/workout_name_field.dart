import 'package:flutter/material.dart';
import 'package:gym_tracker_app/widgets/app_text_field.dart';
import 'package:gym_tracker_app/widgets/field_label.dart';

/// The required WORKOUT NAME field shared by the End, Log and Edit workout
/// sheets. Its REQUIRED note is red while the field is empty.
class WorkoutNameField extends StatelessWidget {
  const WorkoutNameField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;

  static const maxLength = 40;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          FieldLabel(
            'WORKOUT NAME',
            note: 'REQUIRED',
            noteIsWarning: controller.text.trim().isEmpty,
          ),
          child!,
        ],
      ),
      child: AppTextField(
        controller: controller,
        placeholder: placeholder,
        maxLength: maxLength,
        onChanged: onChanged,
      ),
    );
  }
}
