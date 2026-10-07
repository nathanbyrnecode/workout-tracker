// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'past_workouts_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PastWorkoutsNotifier)
final pastWorkoutsProvider = PastWorkoutsNotifierProvider._();

final class PastWorkoutsNotifierProvider
    extends $NotifierProvider<PastWorkoutsNotifier, PastWorkoutsStateData> {
  PastWorkoutsNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pastWorkoutsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pastWorkoutsNotifierHash();

  @$internal
  @override
  PastWorkoutsNotifier create() => PastWorkoutsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PastWorkoutsStateData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PastWorkoutsStateData>(value),
    );
  }
}

String _$pastWorkoutsNotifierHash() =>
    r'e3295929dd0732c8ac90f08bffc34fab8c3eec3e';

abstract class _$PastWorkoutsNotifier extends $Notifier<PastWorkoutsStateData> {
  PastWorkoutsStateData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PastWorkoutsStateData, PastWorkoutsStateData>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<PastWorkoutsStateData, PastWorkoutsStateData>,
        PastWorkoutsStateData,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
