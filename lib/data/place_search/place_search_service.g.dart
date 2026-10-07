// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_search_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(placeSearchService)
final placeSearchServiceProvider = PlaceSearchServiceProvider._();

final class PlaceSearchServiceProvider extends $FunctionalProvider<
    PlaceSearchService,
    PlaceSearchService,
    PlaceSearchService> with $Provider<PlaceSearchService> {
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
    r'4ce63ce65fba39a95c48d8b72ea51fb9d9e98f8a';
