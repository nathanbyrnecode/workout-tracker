// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_workouts_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Workouts the user logged after the fact, newest day first.

@ProviderFor(ManualWorkoutsNotifier)
final manualWorkoutsProvider = ManualWorkoutsNotifierProvider._();

/// Workouts the user logged after the fact, newest day first.
final class ManualWorkoutsNotifierProvider
    extends $NotifierProvider<ManualWorkoutsNotifier, ManualWorkoutsStateData> {
  /// Workouts the user logged after the fact, newest day first.
  ManualWorkoutsNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'manualWorkoutsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$manualWorkoutsNotifierHash();

  @$internal
  @override
  ManualWorkoutsNotifier create() => ManualWorkoutsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ManualWorkoutsStateData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ManualWorkoutsStateData>(value),
    );
  }
}

String _$manualWorkoutsNotifierHash() =>
    r'5bc0a1d25293fdaa0afe8f058fc28c0a564e9bbf';

/// Workouts the user logged after the fact, newest day first.

abstract class _$ManualWorkoutsNotifier
    extends $Notifier<ManualWorkoutsStateData> {
  ManualWorkoutsStateData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<ManualWorkoutsStateData, ManualWorkoutsStateData>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<ManualWorkoutsStateData, ManualWorkoutsStateData>,
        ManualWorkoutsStateData,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
