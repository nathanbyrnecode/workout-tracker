// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_workout_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CurrentWorkoutNotifier)
final currentWorkoutProvider = CurrentWorkoutNotifierProvider._();

final class CurrentWorkoutNotifierProvider
    extends $NotifierProvider<CurrentWorkoutNotifier, CurrentWorkoutStateData> {
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
    r'76d53b8d3d76a9706c84dee4ae739cdf7e21cd60';

abstract class _$CurrentWorkoutNotifier
    extends $Notifier<CurrentWorkoutStateData> {
  CurrentWorkoutStateData build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<CurrentWorkoutStateData, CurrentWorkoutStateData>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<CurrentWorkoutStateData, CurrentWorkoutStateData>,
        CurrentWorkoutStateData,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
