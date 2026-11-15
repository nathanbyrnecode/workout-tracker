import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/local_workout_store.dart';

void main() {
  late Directory root;
  late FileLocalWorkoutStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('local_workout_store_test');
    store = FileLocalWorkoutStore(root: () async => root);
  });

  tearDown(() => root.delete(recursive: true));

  List<String> filesUnder(String path) => Directory('${root.path}/$path')
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path.substring(root.path.length + 1))
      .toList()
    ..sort();

  test('the active workout is written, read back and deleted', () async {
    expect(await store.readActive('user-a'), isNull);

    await store.writeActive('user-a', {'id': 'w1', 'n': 1});
    await store.writeActive('user-a', {'id': 'w1', 'n': 2});
    expect(await store.readActive('user-a'), {'id': 'w1', 'n': 2});
    // Only the real file is left; the temporary one was renamed over it.
    expect(filesUnder('workouts'), ['workouts/user-a/active.json']);

    await store.deleteActive('user-a');
    expect(await store.readActive('user-a'), isNull);
    // Deleting what is not there is fine.
    await store.deleteActive('user-a');
  });

  test('writes started together land in order', () async {
    await Future.wait([
      for (var n = 0; n < 20; n++) store.writeActive('user-a', {'n': n}),
    ]);
    expect(await store.readActive('user-a'), {'n': 19});
  });

  test('pending workouts are kept per kind and per user', () async {
    await store.writePending('user-a', PendingKind.workout, 'w1', {'id': 'w1'});
    await store.writePending('user-a', PendingKind.workout, 'w2', {'id': 'w2'});
    await store
        .writePending('user-a', PendingKind.manualWorkout, 'm1', {'id': 'm1'});
    await store.writePending('user-b', PendingKind.workout, 'w3', {'id': 'w3'});

    final workouts = await store.readPending('user-a', PendingKind.workout);
    expect(workouts.map((json) => json['id']).toSet(), {'w1', 'w2'});
    expect(
      await store.readPending('user-a', PendingKind.manualWorkout),
      [
        {'id': 'm1'}
      ],
    );
    expect(await store.readPending('user-c', PendingKind.workout), isEmpty);

    await store.deletePending('user-a', PendingKind.workout, 'w1');
    expect(
      await store.readPending('user-a', PendingKind.workout),
      [
        {'id': 'w2'}
      ],
    );
  });

  test('files that cannot be read are skipped, not fatal', () async {
    await store.writePending('user-a', PendingKind.workout, 'w1', {'id': 'w1'});
    File('${root.path}/workouts/user-a/pending/broken.json')
        .writeAsStringSync('{not json');
    File('${root.path}/workouts/user-a/pending/list.json')
        .writeAsStringSync('[1, 2]');
    File('${root.path}/workouts/user-a/active.json')
        .writeAsStringSync('{"cut off');

    expect(
      await store.readPending('user-a', PendingKind.workout),
      [
        {'id': 'w1'}
      ],
    );
    expect(await store.readActive('user-a'), isNull);
  });

  test('deleting a user removes only their folder', () async {
    await store.writeActive('user-a', {'id': 'w1'});
    await store.writePending('user-a', PendingKind.workout, 'w2', {'id': 'w2'});
    await store.writeActive('user-b', {'id': 'w3'});

    await store.deleteUser('user-a');

    expect(await store.readActive('user-a'), isNull);
    expect(await store.readPending('user-a', PendingKind.workout), isEmpty);
    expect(await store.readActive('user-b'), {'id': 'w3'});
  });

  test('IDs that are not plain identifiers are refused', () async {
    expect(() => store.readActive('../user-b'), throwsArgumentError);
    expect(
      () => store.writePending('user-a', PendingKind.workout, '../x', {}),
      throwsArgumentError,
    );
  });
}
