import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gym_tracker_app/data/theme_mode_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_state.g.dart';

typedef ThemeModeStateData = ({
  ThemeMode themeMode,
});

const ThemeModeStateData initialThemeModeStateData =
    (themeMode: ThemeMode.system,);

/// The app follows the system setting until the user picks light or dark
/// under Profile → Appearance. The choice is stored on the device.
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  int _generation = 0;

  @override
  ThemeModeStateData build() {
    ref.onDispose(() => _generation++);
    _load();
    return initialThemeModeStateData;
  }

  Future<void> _load() async {
    final generation = _generation;
    try {
      final saved = await ref.read(themeModeStorageProvider).read();
      // A choice made while the saved one was loading wins.
      if (!ref.mounted || generation != _generation) {
        return;
      }
      final themeMode = _parse(saved);
      if (themeMode != null) {
        state = (themeMode: themeMode);
      }
    } catch (error, stackTrace) {
      log('Failed to load the theme mode.',
          error: error, stackTrace: stackTrace);
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    _generation++;
    state = (themeMode: themeMode);
    try {
      await ref.read(themeModeStorageProvider).write(themeMode.name);
    } catch (error, stackTrace) {
      log('Failed to save the theme mode.',
          error: error, stackTrace: stackTrace);
    }
  }

  ThemeMode? _parse(String? value) {
    for (final themeMode in ThemeMode.values) {
      if (themeMode.name == value) {
        return themeMode;
      }
    }
    return null;
  }
}
