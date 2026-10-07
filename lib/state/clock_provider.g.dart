// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The current time. Widgets that show elapsed time or depend on the time of
/// day read it from here so tests can pin it.

@ProviderFor(clock)
final clockProvider = ClockProvider._();

/// The current time. Widgets that show elapsed time or depend on the time of
/// day read it from here so tests can pin it.

final class ClockProvider extends $FunctionalProvider<
    DateTime Function(),
    DateTime Function(),
    DateTime Function()> with $Provider<DateTime Function()> {
  /// The current time. Widgets that show elapsed time or depend on the time of
  /// day read it from here so tests can pin it.
  ClockProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'clockProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return clock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$clockHash() => r'3f65ad34ac6fcd532de9004042bdf2ed2bd85b13';
