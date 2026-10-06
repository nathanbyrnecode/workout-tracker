// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_storage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(themeModeStorage)
final themeModeStorageProvider = ThemeModeStorageProvider._();

final class ThemeModeStorageProvider extends $FunctionalProvider<
    ThemeModeStorage,
    ThemeModeStorage,
    ThemeModeStorage> with $Provider<ThemeModeStorage> {
  ThemeModeStorageProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'themeModeStorageProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$themeModeStorageHash();

  @$internal
  @override
  $ProviderElement<ThemeModeStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ThemeModeStorage create(Ref ref) {
    return themeModeStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeModeStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeModeStorage>(value),
    );
  }
}

String _$themeModeStorageHash() => r'70c7ca84b5c60f9f92c490f1deaa0336e4bb5e51';
