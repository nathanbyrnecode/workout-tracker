import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_storage.g.dart';

/// Keeps the user's appearance choice on the device.
abstract interface class ThemeModeStorage {
  /// The saved value, or null if the user has never chosen.
  Future<String?> read();

  Future<void> write(String value);
}

class FileThemeModeStorage implements ThemeModeStorage {
  const FileThemeModeStorage();

  Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/theme_mode');
  }

  @override
  Future<String?> read() async {
    final file = await _file();
    if (!await file.exists()) {
      return null;
    }
    return (await file.readAsString()).trim();
  }

  @override
  Future<void> write(String value) async {
    final file = await _file();
    await file.writeAsString(value, flush: true);
  }
}

@Riverpod(keepAlive: true)
ThemeModeStorage themeModeStorage(Ref ref) => const FileThemeModeStorage();
