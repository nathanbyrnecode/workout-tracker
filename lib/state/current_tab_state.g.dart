// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_tab_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CurrentTabNotifier)
final currentTabProvider = CurrentTabNotifierProvider._();

final class CurrentTabNotifierProvider
    extends $NotifierProvider<CurrentTabNotifier, CurrentTabStateData> {
  CurrentTabNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentTabProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentTabNotifierHash();

  @$internal
  @override
  CurrentTabNotifier create() => CurrentTabNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CurrentTabStateData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CurrentTabStateData>(value),
    );
  }
}

String _$currentTabNotifierHash() =>
    r'c069d2a0d6341e12e5096ebb855f0a186d2f1bff';

abstract class _$CurrentTabNotifier extends $Notifier<CurrentTabStateData> {
  CurrentTabStateData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CurrentTabStateData, CurrentTabStateData>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<CurrentTabStateData, CurrentTabStateData>,
        CurrentTabStateData,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
