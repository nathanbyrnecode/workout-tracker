import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/main_bottom_navigation.dart';
import 'package:gym_tracker_app/models/app_notification.dart';
import 'package:gym_tracker_app/screens/notifications/notifications_screen.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/manual_workouts_state.dart';
import 'package:gym_tracker_app/state/notifications_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/widgets/app_tab_bar.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

final now = DateTime(2026, 10, 7, 9, 41);

final demoNotifications = [
  AppNotification(
    id: 'a',
    title: 'Time to train',
    body: "You haven't logged a workout in 3 days.",
    time: DateTime(2026, 10, 7, 9),
  ),
  AppNotification(
    id: 'b',
    title: 'Workout saved',
    body: '03/10/26 · 1 exercise · 2 sets · 20 reps',
    time: DateTime(2026, 10, 2, 18),
    read: true,
  ),
  AppNotification(
    id: 'c',
    title: 'Welcome aboard',
    body: 'Start your first workout from the Home tab.',
    time: DateTime(2026, 8, 24, 12),
    read: true,
  ),
];

/// The dot the tab bar and the Home bell draw when something is unread.
Finder unreadDots() => find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).shape == BoxShape.circle &&
          (widget.constraints?.maxWidth == 7 ||
              widget.constraints?.maxWidth == 11),
    );

void main() {
  testWidgets('the app has no notifications and shows an empty state',
      (tester) async {
    await pumpApp(
      tester,
      const NotificationsScreen(),
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('No notifications yet'), findsOneWidget);

    final container =
        ProviderScope.containerOf(tester.element(find.byType(Scaffold)));
    expect(container.read(notificationsProvider).notifications, isEmpty);
    expect(hasUnread(container.read(notificationsProvider)), isFalse);
  });

  testWidgets('lists notifications with their times and marks them read',
      (tester) async {
    await pumpApp(
      tester,
      const NotificationsScreen(),
      overrides: [
        clockProvider.overrideWithValue(() => now),
        notificationsProvider
            .overrideWith(() => FakeNotificationsNotifier(demoNotifications)),
      ],
    );
    await tester.pump();

    expect(find.text('Time to train'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);
    expect(find.text('24 Aug'), findsOneWidget);
    // The one that was unread on opening keeps its dot for this visit.
    expect(find.bySemanticsLabel(RegExp('Unread')), findsOneWidget);

    final container =
        ProviderScope.containerOf(tester.element(find.byType(Scaffold)));
    expect(hasUnread(container.read(notificationsProvider)), isFalse);
  });

  testWidgets('opening the tab clears the dots on the tab bar and Home bell',
      (tester) async {
    await pumpApp(
      tester,
      const MainBottomNavigation(),
      overrides: [
        clockProvider.overrideWithValue(() => now),
        currentWorkoutProvider.overrideWith(FakeWorkoutNotifier.new),
        userAuthenticationProvider.overrideWith(FakeAuthNotifier.new),
        pastWorkoutsProvider.overrideWith(FakePastWorkoutsNotifier.new),
        manualWorkoutsProvider.overrideWith(FakeManualWorkoutsNotifier.new),
        notificationsProvider
            .overrideWith(() => FakeNotificationsNotifier(demoNotifications)),
      ],
    );
    // One on the Home bell, and the tab bar draws its bell twice.
    expect(unreadDots(), findsWidgets);

    await tester.tap(
      find
          .descendant(
              of: find.byType(AppTabBar), matching: find.text('Notifications'))
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(unreadDots(), findsNothing);

    await tester.tap(
      find
          .descendant(of: find.byType(AppTabBar), matching: find.text('Home'))
          .first,
    );
    await tester.pumpAndSettle();
    expect(unreadDots(), findsNothing);
  });

  test('times are the clock today, the weekday this week, then the date', () {
    String at(DateTime time) => formatNotificationTime(time, now: now);
    expect(at(DateTime(2026, 10, 7, 0, 5)), '00:05');
    expect(at(DateTime(2026, 10, 6, 23, 59)), 'Tue');
    expect(at(DateTime(2026, 10, 1, 8)), 'Thu');
    expect(at(DateTime(2026, 9, 30, 8)), '30 Sept');
    expect(at(DateTime(2026, 8, 24, 8)), '24 Aug');
  });
}
