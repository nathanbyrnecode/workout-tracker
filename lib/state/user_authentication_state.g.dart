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
    r'a6b1b1ac473f6d24587e4df049f056355ef842aa';

abstract class _$UserAuthenticationNotifier
    extends $Notifier<UserAuthenticationStateData> {
  UserAuthenticationStateData build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<UserAuthenticationStateData, UserAuthenticationStateData>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<UserAuthenticationStateData, UserAuthenticationStateData>,
        UserAuthenticationStateData,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
