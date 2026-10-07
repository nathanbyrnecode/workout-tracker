import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/screens/workout_summary/workout_summary_screen.dart';
import 'package:gym_tracker_app/widgets/app_tab_bar.dart';

import '../../helpers/demo.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  testWidgets('shows the title, duration, when and where, and totals',
      (tester) async {
    await pumpApp(tester, WorkoutSummaryScreen(workout: demoHistory().first));

    expect(find.text('WORKOUT COMPLETE'), findsOneWidget);
    expect(find.text('Push day'), findsOneWidget);
    expect(find.text('00:02:27'), findsOneWidget);
    expect(
      find.text('06/10/26 · 07:30 · PureGym Manchester Piccadilly'),
      findsOneWidget,
    );
    expect(find.text('EXERCISES'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('38'), findsOneWidget);
    expect(find.text('VOLUME BY EXERCISE'), findsOneWidget);
    expect(find.text('1,702 kg'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('1,290'), findsOneWidget);
    expect(find.text('Incline DB press'), findsOneWidget);
    expect(find.text('412'), findsOneWidget);
    // No tab bar on this screen.
    expect(find.byType(AppTabBar), findsNothing);
  });

  testWidgets('with no place it names the location type', (tester) async {
    await pumpApp(
      tester,
      WorkoutSummaryScreen(
        workout: testWorkout(
          1,
          DateTime(2026, 10, 6, 7, 30),
          title: 'Legs',
          type: LocationType.home,
        ),
      ),
    );
    expect(find.text('06/10/26 · 07:30 · Home'), findsOneWidget);
  });

  testWidgets('long titles and places stay on one line', (tester) async {
    await pumpApp(
      tester,
      WorkoutSummaryScreen(
        workout: testWorkout(
          1,
          DateTime(2026, 10, 6, 7, 30),
          title: 'A very long workout name that goes on and on',
          type: LocationType.gym,
          place: gymGroup,
        ),
      ),
    );

    final title = tester.widget<Text>(
      find.text('A very long workout name that goes on and on'),
    );
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.byWidget(title)).height, lessThan(40));
    final meta = tester.widget<Text>(find.textContaining('06/10/26 · 07:30'));
    expect(meta.maxLines, 1);
    expect(meta.overflow, TextOverflow.ellipsis);
  });

  testWidgets('Done leaves the summary', (tester) async {
    await pumpApp(tester, const SizedBox());
    await openWith(tester, (context) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WorkoutSummaryScreen(workout: demoHistory().first),
        ),
      );
    });
    expect(find.byType(WorkoutSummaryScreen), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Done'), 200);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutSummaryScreen), findsNothing);
  });

  test('a bar is the exercise\'s share of the largest, never under 4%', () {
    expect(volumeShare(1290, 1290), 1);
    expect(volumeShare(412, 1290), closeTo(0.319, 0.001));
    expect(volumeShare(10, 1290), 0.04);
    expect(volumeShare(0, 1290), 0.04);
    expect(volumeShare(0, 0), 0.04);
  });
}
