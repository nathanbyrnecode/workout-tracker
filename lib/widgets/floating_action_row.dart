import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';

/// A row of floating buttons that sits above the tab bar. Give children a
/// `flex` with [Expanded] or [Flexible] to share the width.
class FloatingActionRow extends StatelessWidget {
  const FloatingActionRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: context.tokens.spacing.gap8,
      children: children,
    );
  }
}
