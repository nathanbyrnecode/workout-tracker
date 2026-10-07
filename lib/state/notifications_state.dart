import 'package:gym_tracker_app/models/app_notification.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_state.g.dart';

typedef NotificationsStateData = ({
  List<AppNotification> notifications,
});

const NotificationsStateData initialNotificationsStateData =
    (notifications: [],);

/// The user's notifications, newest first.
///
/// There is no source for notifications yet (`dev/decisions.md` 17), so this
/// starts empty and stays empty. The screen, the unread dots and marking as
/// read are built against it so a real source only has to fill the list.
@Riverpod(keepAlive: true)
class NotificationsNotifier extends _$NotificationsNotifier {
  @override
  NotificationsStateData build() => initialNotificationsStateData;

  /// Opening the Notifications tab calls this, which clears the bell dots.
  void markAllRead() {
    if (!hasUnread(state)) {
      return;
    }
    state = (
      notifications: [
        for (final notification in state.notifications) notification.asRead(),
      ],
    );
  }

  void resetState() => state = initialNotificationsStateData;
}

bool hasUnread(NotificationsStateData state) =>
    state.notifications.any((notification) => !notification.read);
