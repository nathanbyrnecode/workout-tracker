import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';

/// The design's single-line text field: inset fill, 56 tall, radius 16.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.autofocus = false,
    this.maxLength,
    this.textCapitalization = TextCapitalization.sentences,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String placeholder;
  final bool autofocus;

  /// Typing stops at this length. No counter is shown.
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: 56,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: t.card2,
        borderRadius: BorderRadius.circular(t.radii.input),
        border: Border.all(color: t.line),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        textCapitalization: textCapitalization,
        textInputAction: TextInputAction.done,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        inputFormatters: [
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ],
        cursorColor: t.accentText,
        style: AppTypography.input.copyWith(color: t.fg),
        decoration: InputDecoration.collapsed(
          hintText: placeholder,
          hintStyle: AppTypography.input.copyWith(color: t.muted),
        ),
      ),
    );
  }
}
