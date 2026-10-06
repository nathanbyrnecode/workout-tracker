import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';

/// Opens [children] in the shared bottom sheet. Tapping the scrim or dragging
/// the sheet down closes it and completes with null.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required List<Widget> Function(BuildContext context) children,
}) {
  final t = context.tokens;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    elevation: 0,
    barrierColor: t.scrim,
    // The sheet paints its own surface so it can carry the design's shadow.
    backgroundColor: t.sheet.withValues(alpha: 0),
    builder: (sheetContext) => AppSheet(children: children(sheetContext)),
  );
}

/// The surface every bottom sheet shares: sheet colour, 32 top radius, a grab
/// handle, and content that scrolls once it passes [maxHeight].
class AppSheet extends StatelessWidget {
  const AppSheet({super.key, required this.children});

  final List<Widget> children;

  static const maxHeight = 800.0;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = Radius.circular(t.radii.sheet);
    // Keeps the content above the keyboard.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: const BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: t.sheet,
        borderRadius: BorderRadius.only(topLeft: radius, topRight: radius),
        boxShadow: t.sheetShadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          t.spacing.screen,
          10,
          t.spacing.screen,
          40 + keyboard,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: t.spacing.gap18,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: t.line,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
