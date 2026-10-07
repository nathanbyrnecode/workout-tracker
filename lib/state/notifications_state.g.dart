// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The user's notifications, newest first.
///
/// There is no source for notifications yet (`dev/decisions.md` 17), so this
/// starts empty and stays empty. The screen, the unread dots and marking as
/// read are built against it so a real source only has to fill the list.

@ProviderFor(NotificationsNotifier)
final notificationsProvider = NotificationsNotifierProvider._();

/// The user's notifications, newest first.
///
/// There is no source for notifications yet (`dev/decisions.md` 17), so this
/// starts empty and stays empty. The screen, the unread dots and marking as
/// read are built against it so a real source only has to fill the list.
final class NotificationsNotifierProvider
    extends $NotifierProvider<NotificationsNotifier, NotificationsStateData> {
  /// The user's notifications, newest first.
  ///
  /// There is no source for notifications yet (`dev/decisions.md` 17), so this
  /// starts empty and stays empty. The screen, the unread dots and marking as
  /// read are built against it so a real source only has to fill the list.
  NotificationsNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'notificationsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$notificationsNotifierHash();

  @$internal
  @override
  NotificationsNotifier create() => NotificationsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationsStateData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationsStateData>(value),
    );
  }
}

String _$notificationsNotifierHash() =>
    r'0283ef00f74ee88b4445a26f688a679e65b4a61d';

/// The user's notifications, newest first.
///
/// There is no source for notifications yet (`dev/decisions.md` 17), so this
/// starts empty and stays empty. The screen, the unread dots and marking as
/// read are built against it so a real source only has to fill the list.

abstract class _$NotificationsNotifier
    extends $Notifier<NotificationsStateData> {
  NotificationsStateData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<NotificationsStateData, NotificationsStateData>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<NotificationsStateData, NotificationsStateData>,
        NotificationsStateData,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
