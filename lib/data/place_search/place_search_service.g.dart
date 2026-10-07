// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_search_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The place search the app uses. Change the source here.

@ProviderFor(placeSearchService)
final placeSearchServiceProvider = PlaceSearchServiceProvider._();

/// The place search the app uses. Change the source here.

final class PlaceSearchServiceProvider extends $FunctionalProvider<
    PlaceSearchService,
    PlaceSearchService,
    PlaceSearchService> with $Provider<PlaceSearchService> {
  /// The place search the app uses. Change the source here.
  PlaceSearchServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'placeSearchServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$placeSearchServiceHash();

  @$internal
  @override
  $ProviderElement<PlaceSearchService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlaceSearchService create(Ref ref) {
    return placeSearchService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaceSearchService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaceSearchService>(value),
    );
  }
}

String _$placeSearchServiceHash() =>
    r'7b94c7e02e60f608ad640d0e451911771ebe4e83';
