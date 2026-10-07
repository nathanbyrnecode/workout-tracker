import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/theme_mode_storage.dart';
import 'package:gym_tracker_app/state/theme_mode_state.dart';

class FakeThemeModeStorage implements ThemeModeStorage {
  FakeThemeModeStorage([this.value]);

  String? value;
  Completer<void>? readGate;
  bool failReads = false;

  @override
  Future<String?> read() async {
    await readGate?.future;
    if (failReads) {
      throw const FormatException('unreadable');
    }
    return value;
  }

  @override
  Future<void> write(String value) async => this.value = value;
}

ProviderContainer containerWith(FakeThemeModeStorage storage) {
  final container = ProviderContainer(
    overrides: [themeModeStorageProvider.overrideWithValue(storage)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('defaults to system when nothing has been chosen', () async {
    final container = containerWith(FakeThemeModeStorage());
    expect(container.read(themeModeProvider).themeMode, ThemeMode.system);
    await pumpEventQueue();
    expect(container.read(themeModeProvider).themeMode, ThemeMode.system);
  });

  test('restores a saved choice', () async {
    final container = containerWith(FakeThemeModeStorage('dark'));
    expect(container.read(themeModeProvider).themeMode, ThemeMode.system);
    await pumpEventQueue();
    expect(container.read(themeModeProvider).themeMode, ThemeMode.dark);
  });

  test('a choice applies at once and is saved', () async {
    final storage = FakeThemeModeStorage();
    final container = containerWith(storage);
    await container
        .read(themeModeProvider.notifier)
        .setThemeMode(ThemeMode.light);
    expect(container.read(themeModeProvider).themeMode, ThemeMode.light);
    expect(storage.value, 'light');

    final restarted = containerWith(storage);
    restarted.read(themeModeProvider);
    await pumpEventQueue();
    expect(restarted.read(themeModeProvider).themeMode, ThemeMode.light);
  });

  test('a choice made while loading is not overwritten by the saved one',
      () async {
    final storage = FakeThemeModeStorage('dark')..readGate = Completer<void>();
    final container = containerWith(storage);
    await container
        .read(themeModeProvider.notifier)
        .setThemeMode(ThemeMode.light);
    storage.readGate!.complete();
    await pumpEventQueue();
    expect(container.read(themeModeProvider).themeMode, ThemeMode.light);
  });

  test('an unreadable or unknown saved value falls back to system', () async {
    final unknown = containerWith(FakeThemeModeStorage('sepia'));
    unknown.read(themeModeProvider);
    await pumpEventQueue();
    expect(unknown.read(themeModeProvider).themeMode, ThemeMode.system);

    final failing = containerWith(FakeThemeModeStorage()..failReads = true);
    failing.read(themeModeProvider);
    await pumpEventQueue();
    expect(failing.read(themeModeProvider).themeMode, ThemeMode.system);
  });
}
