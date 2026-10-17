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
    this.keyboardType,
    this.textInputAction = TextInputAction.done,
    this.autofillHints,
    this.obscureText = false,
    this.autocorrect = true,
    this.digitsOnly = false,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String placeholder;
  final bool autofocus;

  /// Typing stops at this length. No counter is shown.
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;

  /// Lets password managers and one-time-code autofill find the field.
  final Iterable<String>? autofillHints;
  final bool obscureText;

  /// Also turns suggestions off, for addresses, passwords and codes.
  final bool autocorrect;
  final bool digitsOnly;

  /// Shown at the trailing edge, such as a show-password button.
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final trailing = this.trailing;
    return Container(
      height: 56,
      alignment: Alignment.center,
      padding: EdgeInsets.only(left: 16, right: trailing == null ? 16 : 4),
      decoration: BoxDecoration(
        color: t.card2,
        borderRadius: BorderRadius.circular(t.radii.input),
        border: Border.all(color: t.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              textCapitalization: textCapitalization,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              autofillHints: autofillHints,
              obscureText: obscureText,
              autocorrect: autocorrect,
              enableSuggestions: autocorrect,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              inputFormatters: [
                if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
                if (maxLength != null)
                  LengthLimitingTextInputFormatter(maxLength),
              ],
              cursorColor: t.accentText,
              style: AppTypography.input.copyWith(color: t.fg),
              decoration: InputDecoration.collapsed(
                hintText: placeholder,
                hintStyle: AppTypography.input.copyWith(color: t.muted),
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
