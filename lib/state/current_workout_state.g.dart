// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_workout_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The workout in progress. It lives on the device only: every change is
/// written to the user's `active.json` (`dev/decisions.md` 21), so nothing
/// here needs the network until the workout is ended.

@ProviderFor(CurrentWorkoutNotifier)
final currentWorkoutProvider = CurrentWorkoutNotifierProvider._();

/// The workout in progress. It lives on the device only: every change is
/// written to the user's `active.json` (`dev/decisions.md` 21), so nothing
/// here needs the network until the workout is ended.
final class CurrentWorkoutNotifierProvider
    extends $NotifierProvider<CurrentWorkoutNotifier, CurrentWorkoutStateData> {
  /// The workout in progress. It lives on the device only: every change is
  /// written to the user's `active.json` (`dev/decisions.md` 21), so nothing
  /// here needs the network until the workout is ended.
  CurrentWorkoutNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentWorkoutProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentWorkoutNotifierHash();

  @$internal
  @override
  CurrentWorkoutNotifier create() => CurrentWorkoutNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CurrentWorkoutStateData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CurrentWorkoutStateData>(value),
    );
  }
}

String _$currentWorkoutNotifierHash() =>
    r'9ad232a27c053c30b8276209a89f2100887d7f9b';

/// The workout in progress. It lives on the device only: every change is
/// written to the user's `active.json` (`dev/decisions.md` 21), so nothing
/// here needs the network until the workout is ended.

abstract class _$CurrentWorkoutNotifier
    extends $Notifier<CurrentWorkoutStateData> {
  CurrentWorkoutStateData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<CurrentWorkoutStateData, CurrentWorkoutStateData>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<CurrentWorkoutStateData, CurrentWorkoutStateData>,
        CurrentWorkoutStateData,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
