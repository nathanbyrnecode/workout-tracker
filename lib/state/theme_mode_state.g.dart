// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app follows the system setting until the user picks light or dark
/// under Profile → Appearance. The choice is stored on the device.

@ProviderFor(ThemeModeNotifier)
final themeModeProvider = ThemeModeNotifierProvider._();

/// The app follows the system setting until the user picks light or dark
/// under Profile → Appearance. The choice is stored on the device.
final class ThemeModeNotifierProvider
    extends $NotifierProvider<ThemeModeNotifier, ThemeModeStateData> {
  /// The app follows the system setting until the user picks light or dark
  /// under Profile → Appearance. The choice is stored on the device.
  ThemeModeNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'themeModeProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$themeModeNotifierHash();

  @$internal
  @override
  ThemeModeNotifier create() => ThemeModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeModeStateData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeModeStateData>(value),
    );
  }
}

String _$themeModeNotifierHash() => r'0d02842f35021c5cb5dfd83dbec5942308e1fd4e';

/// The app follows the system setting until the user picks light or dark
/// under Profile → Appearance. The choice is stored on the device.

abstract class _$ThemeModeNotifier extends $Notifier<ThemeModeStateData> {
  ThemeModeStateData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeModeStateData, ThemeModeStateData>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<ThemeModeStateData, ThemeModeStateData>,
        ThemeModeStateData,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
