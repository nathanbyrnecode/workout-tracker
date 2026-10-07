import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/screens/home/widgets/active_exercise_card.dart';
import 'package:gym_tracker_app/screens/home/widgets/completed_exercise_card.dart';
import 'package:gym_tracker_app/screens/home/widgets/sheets/set_menu_sheet.dart';
import 'package:gym_tracker_app/screens/home/widgets/sheets/set_sheet.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';

/// Home's Current tab: the exercise in progress, then the finished exercises
/// of this workout, newest first. With nothing to list it shows a message.
class CurrentWorkoutArea extends ConsumerStatefulWidget {
  const CurrentWorkoutArea({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CurrentWorkoutAreaState();
}

class _CurrentWorkoutAreaState extends ConsumerState<CurrentWorkoutArea> {
  /// The finished exercise whose sets are showing. One at a time.
  int? _openExerciseId;

  Future<void> _openSetMenu(ExerciseSet set, int number) async {
    final action = await showSetMenuSheet(
      context: context,
      set: set,
      number: number,
    );
    if (!mounted) {
      return;
    }
    final notifier = ref.read(currentWorkoutProvider.notifier);
    switch (action) {
      case SetMenuAction.delete:
        await notifier.removeSetFromCurrentExercise(set.id);
      case SetMenuAction.edit:
        final values = await showSetSheet(
          context: context,
          number: number,
          initial: (weight: set.weight, reps: set.reps),
          editing: true,
        );
        if (values != null) {
          await notifier.updateSet(
            set.id,
            weight: values.weight,
            reps: values.reps,
          );
        }
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final workout = ref.watch(currentWorkoutProvider);

    if (workout.recoveryStatus == WorkoutRecoveryStatus.pending ||
        workout.recoveryStatus == WorkoutRecoveryStatus.loading) {
      return _Message(
        'Checking for an unfinished workout…',
        leading: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: t.accentText,
          ),
        ),
      );
    }
    if (workout.recoveryStatus == WorkoutRecoveryStatus.failed) {
      return const _Message(
        'Could not check your saved workout. Check your connection and retry.',
      );
    }
    if (!workout.isInProgress) {
      return const _Message('Get started by starting a workout!');
    }

    final active = workout.currentExercise;
    final finished = workout.exercises.reversed.toList();
    if (active == null && finished.isEmpty) {
      return const _Message('No exercises have been added to this workout yet');
    }

    // Home scrolls as one page, so this is a plain column, not a list.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        t.spacing.screen,
        t.spacing.gap18,
        t.spacing.screen,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (active != null)
            ActiveExerciseCard(exercise: active, onSetMenu: _openSetMenu),
          for (final exercise in finished)
            Padding(
              padding: EdgeInsets.only(
                top: active != null || exercise != finished.first
                    ? t.spacing.gap10
                    : 0,
              ),
              child: CompletedExerciseCard(
                key: ValueKey(exercise.id),
                exercise: exercise,
                open: _openExerciseId == exercise.id,
                onTap: () => setState(() {
                  _openExerciseId =
                      _openExerciseId == exercise.id ? null : exercise.id;
                }),
              ),
            ),
        ],
      ),
    );
  }
}

/// A centred line of muted text for the states with nothing to list.
class _Message extends StatelessWidget {
  const _Message(this.text, {this.leading});

  final String text;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      // The design's 18 above the tab's content plus 64 around the message.
      padding: const EdgeInsets.fromLTRB(60, 82, 60, 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: t.spacing.gap18,
        children: [
          if (leading != null) leading!,
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: t.muted),
          ),
        ],
      ),
    );
  }
}
