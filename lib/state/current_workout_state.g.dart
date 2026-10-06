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
    r'bc3bd0d44e4cd92f214e233ea9138699ece38ce0';

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
