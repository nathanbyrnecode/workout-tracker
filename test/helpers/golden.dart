import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/theme/app_theme.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// The design's device frame.
const goldenSurfaceSize = Size(390, 844);

const _fontFiles = {
  AppTypography.sans: [
    'Geist-Regular.ttf',
    'Geist-Medium.ttf',
    'Geist-SemiBold.ttf',
    'Geist-Bold.ttf',
  ],
  AppTypography.mono: [
    'GeistMono-Regular.ttf',
    'GeistMono-Medium.ttf',
  ],
};

bool _fontsLoaded = false;
bool _glassReady = false;

/// Loads the glass shader `flutter test` can run. Without this the first golden in
/// a file is drawn before they are ready and shows the package's plain
/// fallback instead of the surface every later test gets.
Future<void> loadGlass(WidgetTester tester) async {
  if (_glassReady) {
    return;
  }
  // Only the standard shader: the premium ones need Impeller and are not
  // available to `flutter test`.
  await tester.runAsync(LightweightLiquidGlass.preWarm);
  _glassReady = true;
}

/// Loads the bundled Geist fonts so test text is not drawn as boxes.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) {
    return;
  }
  // Icon fonts ship inside their package, so the test has to find the file.
  final lucide = File(
    '${_packageRoot('lucide_icons_flutter')}/assets/lucide.ttf',
  ).readAsBytesSync();
  await (FontLoader('packages/lucide_icons_flutter/Lucide')
        ..addFont(Future.value(ByteData.sublistView(lucide))))
      .load();

  for (final MapEntry(key: family, value: files) in _fontFiles.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File('assets/fonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
  _fontsLoaded = true;
}

/// Where pub put [package], read from `.dart_tool/package_config.json`.
String _packageRoot(String package) {
  final config = jsonDecode(
    File('.dart_tool/package_config.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final entry = (config['packages'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere((entry) => entry['name'] == package);
  return Directory('.dart_tool')
      .uri
      .resolve(entry['rootUri'] as String)
      .toFilePath();
}

/// Wraps [child] in the app theme for [brightness], as the real app does.
Widget themedApp({required Brightness brightness, required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(brightness),
    home: child,
  );
}

/// Golden files are compared on Linux only, because text renders differently
/// on macOS. Set `ALLOW_LOCAL_GOLDENS=1` to render them elsewhere for a look;
/// never commit goldens made that way.
bool get _goldensEnabled =>
    Platform.isLinux || Platform.environment['ALLOW_LOCAL_GOLDENS'] == '1';

/// Pumps [builder] once per theme on a 390×844 surface with the bundled fonts
/// and compares it with `goldens/<name>_dark.png` and `goldens/<name>_light.png`
/// next to the test file. The tests are tagged `golden`.
///
/// Use [wrap] to add what the widget needs around it, such as a
/// `ProviderScope` with overrides. Use [setUp] to interact with the widget
/// (scroll, open a sheet) before the comparison.
void goldenTest(
  String description, {
  required String name,
  required WidgetBuilder builder,
  Widget Function(Widget child)? wrap,
  Future<void> Function(WidgetTester tester)? setUp,
}) {
  for (final brightness in [Brightness.dark, Brightness.light]) {
    testWidgets(
      '$description (${brightness.name})',
      tags: ['golden'],
      skip: !_goldensEnabled,
      (tester) async {
        await loadAppFonts();
        await loadGlass(tester);
        // Tests draw shadows as solid blocks unless this is switched off.
        debugDisableShadows = false;
        await tester.binding.setSurfaceSize(goldenSurfaceSize);
        tester.view.devicePixelRatio = 1;
        addTearDown(() => tester.binding.setSurfaceSize(null));
        addTearDown(tester.view.resetDevicePixelRatio);

        final app = themedApp(
          brightness: brightness,
          child: Builder(builder: builder),
        );
        await tester.pumpWidget(wrap == null ? app : wrap(app));
        await tester.pump();
        if (setUp != null) {
          await setUp(tester);
        }

        try {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/${name}_${brightness.name}.png'),
          );
        } finally {
          // The test binding checks this is back to its default.
          debugDisableShadows = true;
        }
      },
    );
  }
}
