import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_workout_store.g.dart';

/// The two kinds of finished entry that can wait on the device for upload.
enum PendingKind {
  workout('pending'),
  manualWorkout('pending_manual');

  const PendingKind(this.folder);

  final String folder;
}

/// Keeps the active workout and any workouts that have not reached the server
/// yet on the device, as JSON, one folder per user (`dev/decisions.md` 21).
///
/// Every method takes the user's ID, and only that user's folder is touched,
/// so a second account on the same device never sees the first one's
/// workouts.
abstract interface class LocalWorkoutStore {
  /// The active workout, or null if there is none or it cannot be read.
  Future<Map<String, dynamic>?> readActive(String userId);

  Future<void> writeActive(String userId, Map<String, dynamic> json);

  Future<void> deleteActive(String userId);

  /// Every readable entry of [kind]. Files that cannot be read are skipped.
  Future<List<Map<String, dynamic>>> readPending(
    String userId,
    PendingKind kind,
  );

  Future<void> writePending(
    String userId,
    PendingKind kind,
    String id,
    Map<String, dynamic> json,
  );

  Future<void> deletePending(String userId, PendingKind kind, String id);

  /// Removes everything kept for [userId].
  Future<void> deleteUser(String userId);
}

class FileLocalWorkoutStore implements LocalWorkoutStore {
  FileLocalWorkoutStore({Future<Directory> Function()? root})
      : _root = root ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _root;

  /// The last write to each path, so writes to one file happen in order.
  final _writes = <String, Future<void>>{};

  Future<Directory> _userDirectory(String userId) async {
    // User IDs are UUIDs; anything else is refused rather than used as a path.
    if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(userId)) {
      throw ArgumentError.value(userId, 'userId', 'not a valid user ID');
    }
    final root = await _root();
    return Directory('${root.path}/workouts/$userId');
  }

  Future<File> _activeFile(String userId) async =>
      File('${(await _userDirectory(userId)).path}/active.json');

  Future<Directory> _pendingDirectory(String userId, PendingKind kind) async =>
      Directory('${(await _userDirectory(userId)).path}/${kind.folder}');

  Future<File> _pendingFile(
    String userId,
    PendingKind kind,
    String id,
  ) async {
    if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(id)) {
      throw ArgumentError.value(id, 'id', 'not a valid workout ID');
    }
    return File('${(await _pendingDirectory(userId, kind)).path}/$id.json');
  }

  Future<Map<String, dynamic>?> _read(File file) async {
    if (!await file.exists()) {
      return null;
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      log('Ignored ${file.path}: not a JSON object.');
    } on FormatException catch (error) {
      log('Ignored ${file.path}: not valid JSON.', error: error);
    }
    return null;
  }

  /// Writes to a temporary file, then renames it over the real one, so a
  /// crash part-way leaves either the old file or the new one, never half.
  Future<void> _write(File file, Map<String, dynamic> json) =>
      _serialise(file.path, () async {
        await file.parent.create(recursive: true);
        final temporary = File('${file.path}.tmp');
        await temporary.writeAsString(jsonEncode(json), flush: true);
        await temporary.rename(file.path);
      });

  Future<void> _delete(File file) => _serialise(file.path, () async {
        if (await file.exists()) {
          await file.delete();
        }
      });

  Future<void> _serialise(String path, Future<void> Function() action) {
    final previous = _writes[path] ?? Future<void>.value();
    final next = previous.catchError((Object _) {}).then((_) => action());
    _writes[path] = next;
    return next.whenComplete(() {
      if (identical(_writes[path], next)) {
        _writes.remove(path);
      }
    });
  }

  @override
  Future<Map<String, dynamic>?> readActive(String userId) async =>
      _read(await _activeFile(userId));

  @override
  Future<void> writeActive(String userId, Map<String, dynamic> json) async =>
      _write(await _activeFile(userId), json);

  @override
  Future<void> deleteActive(String userId) async =>
      _delete(await _activeFile(userId));

  @override
  Future<List<Map<String, dynamic>>> readPending(
    String userId,
    PendingKind kind,
  ) async {
    final directory = await _pendingDirectory(userId, kind);
    if (!await directory.exists()) {
      return [];
    }
    final entries = <Map<String, dynamic>>[];
    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final json = await _read(entity);
        if (json != null) {
          entries.add(json);
        }
      }
    }
    return entries;
  }

  @override
  Future<void> writePending(
    String userId,
    PendingKind kind,
    String id,
    Map<String, dynamic> json,
  ) async =>
      _write(await _pendingFile(userId, kind, id), json);

  @override
  Future<void> deletePending(
          String userId, PendingKind kind, String id) async =>
      _delete(await _pendingFile(userId, kind, id));

  @override
  Future<void> deleteUser(String userId) async {
    final directory = await _userDirectory(userId);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

@Riverpod(keepAlive: true)
LocalWorkoutStore localWorkoutStore(Ref ref) => FileLocalWorkoutStore();
