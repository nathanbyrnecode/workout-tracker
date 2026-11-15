// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_messenger.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appMessenger)
final appMessengerProvider = AppMessengerProvider._();

final class AppMessengerProvider
    extends $FunctionalProvider<AppMessenger, AppMessenger, AppMessenger>
    with $Provider<AppMessenger> {
  AppMessengerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appMessengerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appMessengerHash();

  @$internal
  @override
  $ProviderElement<AppMessenger> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppMessenger create(Ref ref) {
    return appMessenger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppMessenger value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppMessenger>(value),
    );
  }
}

String _$appMessengerHash() => r'a1e687aba816f18fe6a5bcd0bf8a804b09ff4481';
