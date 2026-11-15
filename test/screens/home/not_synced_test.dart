import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/manual_workout.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/screens/home/home_screen.dart';
import 'package:gym_tracker_app/screens/home/widgets/sync_status_row.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_history_card.dart';
import 'package:gym_tracker_app/screens/tracker/tracker_screen.dart';
import 'package:gym_tracker_app/screens/workout_detail/workout_detail_screen.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_tab_state.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/manual_workouts_state.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/state/workout_sync_state.dart';
import 'package:gym_tracker_app/widgets/app_messenger.dart';
import 'package:gym_tracker_app/widgets/not_synced_marker.dart';

import '../../helpers/demo.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

class _PreviousTab extends CurrentTabNotifier {
  @override
  CurrentTabStateData build() => (currentTab: TabItem.previousWorkouts);
}

/// Home with [synced] on the server and [waiting] only on the device.
Future<({FakeWorkoutSyncNotifier sync, RecordingMessenger messenger})> pumpHome(
  WidgetTester tester, {
  List<Workout> synced = const [],
  List<Workout> waiting = const [],
  List<ManualWorkout> waitingManual = const [],
  bool previousTab = false,
}) async {
  final sync = FakeWorkoutSyncNotifier(
    workouts: waiting,
    manualWorkouts: waitingManual,
  );
  final messenger = RecordingMessenger();
  await pumpApp(
    tester,
    HomeScreen(onOpenNotifications: () {}, onOpenWorkout: (_) {}),
    overrides: [
      if (previousTab) currentTabProvider.overrideWith(_PreviousTab.new),
      currentWorkoutProvider.overrideWith(FakeWorkoutNotifier.new),
      userAuthenticationProvider.overrideWith(FakeAuthNotifier.new),
      pastWorkoutsProvider.overrideWith(() => FakePastWorkoutsNotifier(synced)),
      workoutSyncProvider.overrideWith(() => sync),
      appMessengerProvider.overrideWithValue(messenger),
      clockProvider.overrideWithValue(() => demoNow),
    ],
  );
  return (sync: sync, messenger: messenger);
}

ManualWorkout swim({bool synced = true}) => ManualWorkout(
      id: testId(50),
      date: DateTime(2026, 10, 6),
      title: 'Swim',
      locationType: LocationType.other,
      synced: synced,
    );

void main() {
  group('Home sync row', () {
    testWidgets('is hidden when nothing is waiting', (tester) async {
      await pumpHome(tester, synced: demoHistory());
      expect(find.byType(NotSyncedMarker), findsNothing);
      expect(find.text('Sync'), findsNothing);
    });

    testWidgets('counts what is waiting, logged workouts included',
        (tester) async {
      await pumpHome(
        tester,
        waiting: [notSynced(demoHistory().first)],
        waitingManual: [swim(synced: false)],
      );
      expect(find.text('2 workouts not synced'), findsOneWidget);
      expect(find.text('Sync'), findsOneWidget);
    });

    testWidgets('Sync uploads, says so and goes away', (tester) async {
      final home =
          await pumpHome(tester, waiting: [notSynced(demoHistory().first)]);
      expect(find.text('1 workout not synced'), findsOneWidget);

      await tester.tap(find.text('Sync'));
      await tester.pumpAndSettle();

      expect(home.sync.syncs, [1]);
      expect(home.messenger.messages, ['All workouts synced']);
      expect(find.byType(SyncStatusRow), findsOneWidget);
      expect(find.text('Sync'), findsNothing);
    });

    testWidgets('while syncing, shows progress instead of Sync',
        (tester) async {
      await pumpApp(
        tester,
        const SyncStatusRow(),
        overrides: [
          workoutSyncProvider.overrideWith(
            () => FakeWorkoutSyncNotifier(
              workouts: [notSynced(demoHistory().first)],
              syncing: true,
            ),
          ),
        ],
      );
      expect(find.text('1 workout not synced'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Sync'), findsNothing);
    });

    testWidgets('a failed Sync says so and stays', (tester) async {
      final home = await pumpHome(
        tester,
        waiting: [
          notSynced(demoHistory()[0]),
          notSynced(demoHistory()[1]),
        ],
      );
      home.sync.failSync.on = true;

      await tester.tap(find.text('Sync'));
      await tester.pumpAndSettle();

      expect(home.messenger.messages.single, startsWith("Couldn't sync 2"));
      expect(find.text('2 workouts not synced'), findsOneWidget);
    });
  });

  testWidgets('Previous marks only the workouts not synced', (tester) async {
    final history = demoHistory();
    await pumpHome(
      tester,
      previousTab: true,
      synced: history.skip(1).toList(),
      waiting: [notSynced(history.first)],
    );

    final unsyncedCard = find.ancestor(
      of: find.byType(NotSyncedMarker),
      matching: find.byType(WorkoutHistoryCard),
    );
    // One marker on the card, one in the sync row above.
    expect(find.byType(NotSyncedMarker), findsNWidgets(2));
    expect(unsyncedCard, findsOneWidget);
    expect(
      tester.widget<WorkoutHistoryCard>(unsyncedCard).workout.id,
      history.first.id,
    );
  });

  testWidgets('the Tracker marks a logged workout not synced', (tester) async {
    await pumpApp(
      tester,
      TrackerScreen(
        onOpenWorkout: (_) {},
        onOpenManualWorkout: (_) {},
        onOpenLiveWorkout: () {},
      ),
      overrides: [
        clockProvider.overrideWithValue(() => demoNow),
        currentWorkoutProvider.overrideWith(FakeWorkoutNotifier.new),
        pastWorkoutsProvider.overrideWith(FakePastWorkoutsNotifier.new),
        manualWorkoutsProvider.overrideWith(FakeManualWorkoutsNotifier.new),
        workoutSyncProvider.overrideWith(
          () => FakeWorkoutSyncNotifier(manualWorkouts: [swim(synced: false)]),
        ),
      ],
    );
    expect(find.text('Swim'), findsOneWidget);
    expect(find.byType(NotSyncedMarker), findsOneWidget);
  });

  testWidgets('a detail screen labels a workout not synced', (tester) async {
    final first = demoHistory().first;
    await pumpApp(
      tester,
      WorkoutDetailScreen(workoutId: first.id, onClose: () {}),
      overrides: [
        pastWorkoutsProvider.overrideWith(FakePastWorkoutsNotifier.new),
        workoutSyncProvider.overrideWith(
          () => FakeWorkoutSyncNotifier(workouts: [notSynced(first)]),
        ),
      ],
    );
    expect(find.text('NOT SYNCED'), findsOneWidget);
  });

  testWidgets('a synced detail screen has no label', (tester) async {
    final first = demoHistory().first;
    await pumpApp(
      tester,
      Consumer(
        builder: (context, ref, _) =>
            WorkoutDetailScreen(workoutId: first.id, onClose: () {}),
      ),
      overrides: [
        pastWorkoutsProvider
            .overrideWith(() => FakePastWorkoutsNotifier([first])),
      ],
    );
    expect(find.text('NOT SYNCED'), findsNothing);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
