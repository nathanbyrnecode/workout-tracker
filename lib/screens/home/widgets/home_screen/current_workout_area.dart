import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/screens/home/widgets/stat_pair.dart';
import 'package:gym_tracker_app/screens/home/widgets/timer_count.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/number_format.dart';

class CurrentWorkoutArea extends ConsumerStatefulWidget {
  const CurrentWorkoutArea({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CurrentWorkoutAreaState();
}

class _CurrentWorkoutAreaState extends ConsumerState<CurrentWorkoutArea> {
  @override
  Widget build(BuildContext context) {
    var workoutProvider = ref.watch(currentWorkoutProvider);
    if (workoutProvider.recoveryStatus == WorkoutRecoveryStatus.pending ||
        workoutProvider.recoveryStatus == WorkoutRecoveryStatus.loading) {
      return _Message(
        'Checking for an unfinished workout…',
        leading: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: context.tokens.accentText,
          ),
        ),
      );
    }
    if (workoutProvider.recoveryStatus == WorkoutRecoveryStatus.failed) {
      return const _Message(
        'Could not check your saved workout. Check your connection and retry.',
      );
    }
    bool workoutInProgress = workoutProvider.isInProgress;
    bool exerciseInProgress = workoutProvider.currentExercise != null;
    final sets = workoutProvider.currentExercise?.sets.values
            .toList()
            .reversed
            .toList() ??
        [];
    final exercises = workoutProvider.exercises.reversed.toList();

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        if (!workoutInProgress)
          const _Message('Get started by starting a workout!')
        else if (!exerciseInProgress && exercises.isEmpty)
          const _Message('No exercises have been added to this workout yet'),
        if (workoutInProgress && exerciseInProgress)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        workoutProvider.currentExercise?.name ?? "",
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    TimerCount(
                      startTime: workoutProvider.currentExercise?.startTime ??
                          DateTime.now(),
                      style: AppTypography.stat.copyWith(
                        fontSize: 14,
                        color: context.tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 167,
                child: ListView.separated(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: max(sets.length, 1),
                  itemBuilder: (context, index) {
                    final exerciseSet = sets.isEmpty ? null : sets[index];
                    return sets.isEmpty
                        ? Container(
                            height: 167,
                            width: 121,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Color(0xff2A343E),
                            ),
                            padding: const EdgeInsets.only(
                                bottom: 16, top: 16, left: 6, right: 6),
                            child: Center(
                              child: Text(
                                'No sets\nadded yet',
                                style: TextStyle(
                                    color: Color(0xff5B7182),
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : CurrentExerciseSetCard(
                            weight: formatWeight(exerciseSet!.weight),
                            reps: exerciseSet.reps.toString(),
                            onRemove: () {
                              ref
                                  .read(currentWorkoutProvider.notifier)
                                  .removeSetFromCurrentExercise(exerciseSet.id);
                            },
                          );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return SizedBox(width: 10);
                  },
                ),
              ),
            ],
          ),
        if (workoutInProgress && exercises.isNotEmpty) ...[
          SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 10, bottom: 100),
              scrollDirection: Axis.vertical,
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                int exerciseReps = 0;
                int exerciseSets = exercises[index].sets.length;
                for (var set in exercises[index].sets.values) {
                  exerciseReps += set.reps;
                }
                final exerciseDuration = exercises[index]
                    .endTime
                    ?.difference(exercises[index].startTime);
                final minutes = exerciseDuration?.inMinutes ?? 0;
                final seconds = exerciseDuration?.inSeconds ?? 0;
                final durationValue =
                    minutes > 0 ? minutes : (seconds > 0 ? seconds : 0);
                return Container(
                  height: 87,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment(0.00, 0.50),
                      end: Alignment(1.00, 0.50),
                      colors: [
                        Colors.white.withValues(alpha: 0.03),
                        const Color.fromRGBO(153, 153, 153, 0.04)
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.only(
                      bottom: 10, top: 10, left: 14, right: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          exercises[index].name,
                          style: TextStyle(
                            height: 2,
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            overflow: TextOverflow.ellipsis,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: StatPair(
                              value: durationValue.toString(),
                              label: minutes > 1
                                  ? 'Mins'
                                  : minutes == 1
                                      ? 'Min'
                                      : seconds == 1
                                          ? 'Sec'
                                          : 'Secs',
                            ),
                          ),
                          Expanded(
                            child: StatPair(
                              value: exerciseSets.toString(),
                              label: exerciseSets == 1 ? 'Set' : 'Sets',
                            ),
                          ),
                          Expanded(
                            child: StatPair(
                              value: exerciseReps.toString(),
                              label: exerciseReps == 1 ? 'Rep' : 'Reps',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return SizedBox(height: 10);
              },
            ),
          ),
        ]
      ],
    );
  }
}

enum _ExerciseSetAction { remove }

class CurrentExerciseSetCard extends StatelessWidget {
  const CurrentExerciseSetCard({
    super.key,
    required this.weight,
    required this.reps,
    required this.onRemove,
  });

  final String weight;
  final String reps;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 167,
      width: 121,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xff2A343E),
      ),
      padding: const EdgeInsets.only(
        bottom: 16,
        top: 16,
        left: 6,
        right: 6,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  weight,
                  style: const TextStyle(
                    height: 0.78,
                    color: Color(0xff5B7182),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'KG',
                  style: TextStyle(
                    height: 1.16,
                    color: Color(0xff5B7182),
                    fontSize: 24,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  reps,
                  style: const TextStyle(
                    color: Color(0xff5B7182),
                    height: 0.78,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'Reps',
                  style: TextStyle(
                    height: 1.16,
                    color: Color(0xff5B7182),
                    fontSize: 24,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(
            top: -16,
            right: -6,
            child: SizedBox(
              height: 36,
              width: 36,
              child: PopupMenuButton<_ExerciseSetAction>(
                tooltip: 'Set options',
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xffB6E3FF),
                  size: 20,
                ),
                onSelected: (action) {
                  if (action == _ExerciseSetAction.remove) {
                    onRemove();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<_ExerciseSetAction>(
                    value: _ExerciseSetAction.remove,
                    child: Text('Remove set'),
                  ),
                ],
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 64),
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
