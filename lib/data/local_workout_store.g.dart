// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_workout_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(localWorkoutStore)
final localWorkoutStoreProvider = LocalWorkoutStoreProvider._();

final class LocalWorkoutStoreProvider extends $FunctionalProvider<
    LocalWorkoutStore,
    LocalWorkoutStore,
    LocalWorkoutStore> with $Provider<LocalWorkoutStore> {
  LocalWorkoutStoreProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'localWorkoutStoreProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$localWorkoutStoreHash();

  @$internal
  @override
  $ProviderElement<LocalWorkoutStore> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalWorkoutStore create(Ref ref) {
    return localWorkoutStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalWorkoutStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalWorkoutStore>(value),
    );
  }
}

String _$localWorkoutStoreHash() => r'bf7ca9e25d18930870d0debed57afe53f6e8f46d';
