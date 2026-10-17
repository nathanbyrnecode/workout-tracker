// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_authentication_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserAuthenticationNotifier)
final userAuthenticationProvider = UserAuthenticationNotifierProvider._();

final class UserAuthenticationNotifierProvider extends $NotifierProvider<
    UserAuthenticationNotifier, UserAuthenticationStateData> {
  UserAuthenticationNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'userAuthenticationProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userAuthenticationNotifierHash();

  @$internal
  @override
  UserAuthenticationNotifier create() => UserAuthenticationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserAuthenticationStateData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserAuthenticationStateData>(value),
    );
  }
}

String _$userAuthenticationNotifierHash() =>
    r'c1d998bae1bd48b2fe4f651516172d9c31ea5df0';

abstract class _$UserAuthenticationNotifier
    extends $Notifier<UserAuthenticationStateData> {
  UserAuthenticationStateData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref
        as $Ref<UserAuthenticationStateData, UserAuthenticationStateData>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<UserAuthenticationStateData, UserAuthenticationStateData>,
        UserAuthenticationStateData,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
