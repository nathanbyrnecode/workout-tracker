import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/theme/app_theme.dart';

import 'golden.dart';

/// Pumps [child] in the dark app theme on the design's 390×844 surface, with
/// the bundled fonts so text has its real size.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List overrides = const [],
  Brightness brightness = Brightness.dark,
}) async {
  await loadAppFonts();
  await tester.binding.setSurfaceSize(goldenSurfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        theme: buildAppTheme(brightness),
        home: Scaffold(body: child),
      ),
    ),
  );
}

/// Runs [open] with a context inside the pumped app, for showing sheets.
Future<void> openWith(
  WidgetTester tester,
  void Function(BuildContext context) open,
) async {
  open(tester.element(find.byType(Scaffold).first));
  await tester.pumpAndSettle();
}
