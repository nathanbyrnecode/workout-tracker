import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/models/app_notification.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/notifications_state.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/date_format.dart';
import 'package:gym_tracker_app/widgets/screen_title.dart';

/// The Notifications tab. Opening it marks everything as read, which clears
/// the dots on the tab bar and the Home bell. The cards that were unread when
/// it opened keep their dot until the user leaves.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late final Set<String> _unreadWhenOpened;

  @override
  void initState() {
    super.initState();
    _unreadWhenOpened = {
      for (final notification in ref.read(notificationsProvider).notifications)
        if (!notification.read) notification.id,
    };
    // Providers cannot change while the tree is still being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(notificationsProvider.notifier).markAllRead();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final notifications = ref.watch(notificationsProvider).notifications;
    final now = ref.watch(clockProvider)();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          t.spacing.screen,
          16,
          t.spacing.screen,
          t.spacing.contentBottom,
        ),
        children: [
          const ScreenTitle('Notifications'),
          SizedBox(height: t.spacing.gap18),
          if (notifications.isEmpty)
            const _EmptyState()
          else
            for (final (index, notification) in notifications.indexed)
              Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : t.spacing.gap8),
                child: _NotificationCard(
                  notification: notification,
                  unread: _unreadWhenOpened.contains(notification.id),
                  now: now,
                ),
              ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 64, 40, 0),
      child: Column(
        spacing: t.spacing.gap6,
        children: [
          const Text('No notifications yet', style: AppTypography.cardTitle),
          Text(
            'Updates about your workouts will show up here.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: t.muted),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.unread,
    required this.now,
  });

  final AppNotification notification;
  final bool unread;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radii.card),
        border: Border.all(color: t.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: t.spacing.gap12,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Semantics(
              label: unread ? 'Unread' : null,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  // Read cards keep the space so the text stays aligned.
                  color: unread ? t.accent : t.accent.withValues(alpha: 0),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: t.spacing.gap8,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: AppTypography.setValueSmall,
                      ),
                    ),
                    Text(
                      formatNotificationTime(notification.time, now: now),
                      style: AppTypography.footnote.copyWith(
                        letterSpacing: 0,
                        color: t.muted,
                      ),
                    ),
                  ],
                ),
                Text(
                  notification.body,
                  style: AppTypography.bodyMedium.copyWith(
                    color: t.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// How the design dates a notification: the time if it was today (`09:00`),
/// the weekday if it was in the last week (`Fri`), otherwise the day and
/// month (`24 Aug`).
String formatNotificationTime(DateTime time, {required DateTime now}) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(time.year, time.month, time.day);
  final daysAgo = today.difference(day).inDays;
  if (daysAgo <= 0) {
    return formatClockTime(time);
  }
  if (daysAgo < 7) {
    return shortWeekdayName(time.weekday);
  }
  return '${time.day} ${shortMonthName(time.month)}';
}
