// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_sync_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The workouts and logged workouts that are on the device but not on the
/// server yet, and their uploads.
///
/// Each one is a file in the signed-in user's folder (see
/// `LocalWorkoutStore`). Uploads are single-flight per ID, so the Sync
/// button, the automatic sync and ending a workout never send the same one
/// twice at once. After a successful upload the file is deleted and the
/// workout moves to the server-backed list.

@ProviderFor(WorkoutSyncNotifier)
final workoutSyncProvider = WorkoutSyncNotifierProvider._();

/// The workouts and logged workouts that are on the device but not on the
/// server yet, and their uploads.
///
/// Each one is a file in the signed-in user's folder (see
/// `LocalWorkoutStore`). Uploads are single-flight per ID, so the Sync
/// button, the automatic sync and ending a workout never send the same one
/// twice at once. After a successful upload the file is deleted and the
/// workout moves to the server-backed list.
final class WorkoutSyncNotifierProvider
    extends $NotifierProvider<WorkoutSyncNotifier, WorkoutSyncStateData> {
  /// The workouts and logged workouts that are on the device but not on the
  /// server yet, and their uploads.
  ///
  /// Each one is a file in the signed-in user's folder (see
  /// `LocalWorkoutStore`). Uploads are single-flight per ID, so the Sync
  /// button, the automatic sync and ending a workout never send the same one
  /// twice at once. After a successful upload the file is deleted and the
  /// workout moves to the server-backed list.
  WorkoutSyncNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'workoutSyncProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$workoutSyncNotifierHash();

  @$internal
  @override
  WorkoutSyncNotifier create() => WorkoutSyncNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkoutSyncStateData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkoutSyncStateData>(value),
    );
  }
}

String _$workoutSyncNotifierHash() =>
    r'08f4da8f272e3699978327b0969fff4d8758ae52';

/// The workouts and logged workouts that are on the device but not on the
/// server yet, and their uploads.
///
/// Each one is a file in the signed-in user's folder (see
/// `LocalWorkoutStore`). Uploads are single-flight per ID, so the Sync
/// button, the automatic sync and ending a workout never send the same one
/// twice at once. After a successful upload the file is deleted and the
/// workout moves to the server-backed list.

abstract class _$WorkoutSyncNotifier extends $Notifier<WorkoutSyncStateData> {
  WorkoutSyncStateData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WorkoutSyncStateData, WorkoutSyncStateData>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<WorkoutSyncStateData, WorkoutSyncStateData>,
        WorkoutSyncStateData,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

/// Every finished workout to show: the server's, plus those still on the
/// device. A workout in both lists is shown once, from the server.

@ProviderFor(allWorkouts)
final allWorkoutsProvider = AllWorkoutsProvider._();

/// Every finished workout to show: the server's, plus those still on the
/// device. A workout in both lists is shown once, from the server.

final class AllWorkoutsProvider
    extends $FunctionalProvider<List<Workout>, List<Workout>, List<Workout>>
    with $Provider<List<Workout>> {
  /// Every finished workout to show: the server's, plus those still on the
  /// device. A workout in both lists is shown once, from the server.
  AllWorkoutsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'allWorkoutsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$allWorkoutsHash();

  @$internal
  @override
  $ProviderElement<List<Workout>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Workout> create(Ref ref) {
    return allWorkouts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Workout> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Workout>>(value),
    );
  }
}

String _$allWorkoutsHash() => r'992bccf8e4f57adf1ec715d3bcf08b933fc7b2de';

/// Every logged workout to show, newest day first: the server's, plus those
/// still on the device.

@ProviderFor(allManualWorkouts)
final allManualWorkoutsProvider = AllManualWorkoutsProvider._();

/// Every logged workout to show, newest day first: the server's, plus those
/// still on the device.

final class AllManualWorkoutsProvider extends $FunctionalProvider<
    List<ManualWorkout>,
    List<ManualWorkout>,
    List<ManualWorkout>> with $Provider<List<ManualWorkout>> {
  /// Every logged workout to show, newest day first: the server's, plus those
  /// still on the device.
  AllManualWorkoutsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'allManualWorkoutsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$allManualWorkoutsHash();

  @$internal
  @override
  $ProviderElement<List<ManualWorkout>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<ManualWorkout> create(Ref ref) {
    return allManualWorkouts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ManualWorkout> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ManualWorkout>>(value),
    );
  }
}

String _$allManualWorkoutsHash() => r'942415968f105d1295c79bb18017b015e59916a9';
