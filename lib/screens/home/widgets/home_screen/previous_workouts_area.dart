import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/util/color_utils.dart';

class PreviousWorkoutsArea extends ConsumerStatefulWidget {
  const PreviousWorkoutsArea({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PreviousWorkoutsAreaState();
}

class _PreviousWorkoutsAreaState extends ConsumerState<PreviousWorkoutsArea> {
  @override
  Widget build(BuildContext context) {
    final previousWorkouts = ref.watch(pastWorkoutsProvider).workouts;
    if (previousWorkouts.isNotEmpty) {
      return ListView.separated(
        padding:
            const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 100),
        itemCount: previousWorkouts.length,
        itemBuilder: (context, index) {
          final workout = previousWorkouts[index];
          final workoutDuration =
              workout.endTime != null && workout.startTime != null
                  ? workout.endTime!.difference(workout.startTime!)
                  : Duration.zero;
          num numOfSets = 0;
          num numOfReps = 0;
          for (var exercise in workout.exercises.values) {
            numOfSets += exercise.sets.length;
            for (var set in exercise.sets.values) {
              numOfReps += set.reps;
            }
          }

          return SizedBox(
            key: ValueKey(workout.id),
            child: _SwipeWorkoutItem(
              onTap: () {
                ref
                    .read(pastWorkoutsProvider.notifier)
                    .deleteWorkout(workout.id);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment(0.00, 0.00),
                    end: Alignment(1.00, 1.00),
                    colors: [const Color(0xFF222E3D), const Color(0xFF131921)],
                  ),
                ),
                child: Column(
                  spacing: 8,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          spacing: 9,
                          children: [
                            Text(
                              '${workout.startTime?.day.toString().padLeft(2, "0")}/${workout.startTime?.month.toString().padLeft(2, "0")}/${workout.startTime?.year.toString().substring(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                height: 2,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffB6E3FF),
                              ),
                            ),
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 14,
                                height: 2,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffB6E3FF),
                              ),
                            ),
                            Text(
                              '${workout.startTime?.hour.toString().padLeft(2, "0")}:${workout.startTime?.minute.toString().padLeft(2, "0")}',
                              style: TextStyle(
                                fontSize: 14,
                                height: 2,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffB6E3FF),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Color(0xff1E252E),
                          ),
                          child: Text(
                            '${workoutDuration.inHours.toString().padLeft(2, "0")}:${(workoutDuration.inMinutes % 60).toString().padLeft(2, "0")}:${(workoutDuration.inSeconds % 60).toString().padLeft(2, "0")}',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1,
                              fontWeight: FontWeight.bold,
                              color: Color(0xffB6E3FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 14,
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.only(
                                top: 8, bottom: 8, left: 6, right: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Color.fromRGBO(255, 255, 255, .04),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  workout.exercises.length.toString(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xffB6E3FF),
                                  ),
                                ),
                                Text(
                                  workout.exercises.length == 1
                                      ? 'Exercise'
                                      : 'Exercises',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    color: Color(0xffB6E3FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.only(
                                top: 8, bottom: 8, left: 6, right: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Color.fromRGBO(255, 255, 255, .04),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$numOfSets',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xffB6E3FF),
                                  ),
                                ),
                                Text(
                                  'Sets',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    color: Color(0xffB6E3FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.only(
                                top: 8, bottom: 8, left: 6, right: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Color.fromRGBO(255, 255, 255, .04),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$numOfReps',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xffB6E3FF),
                                  ),
                                ),
                                Text(
                                  'Reps',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    color: Color(0xffB6E3FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return SizedBox(height: 10);
        },
      );
    } else {
      return Column(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 120),
              child: Text(
                'No workouts have been\ncompleted yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color.from(
                        alpha: 0.44, red: 0.714, green: 0.89, blue: 1),
                    fontSize: 16,
                    fontWeight: FontWeight.normal),
              ),
            ),
          )
        ],
      );
    }
  }
}

class _SwipeWorkoutItem extends StatefulWidget {
  const _SwipeWorkoutItem({
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_SwipeWorkoutItem> createState() => _SwipeWorkoutItemState();
}

class _SwipeWorkoutItemState extends State<_SwipeWorkoutItem> {
  static const double _actionWidth = 60;
  static const double _maxReveal = _actionWidth * 1 + 10;
  static const Duration _snapDuration = Duration(milliseconds: 160);
  double _offset = 0;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset = (_offset + details.delta.dx).clamp(-_maxReveal, 0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final shouldOpen = _offset.abs() > _maxReveal / 2;
    setState(() {
      _offset = shouldOpen ? -_maxReveal : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isOpen = _offset != 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: GestureDetector(
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !isOpen,
                child: Row(
                  spacing: 10,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: _ActionButton(
                        color: Colors.red,
                        icon: Icons.delete,
                        onTap: widget.onTap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedContainer(
              duration: _snapDuration,
              transform: Matrix4.translationValues(_offset, 0, 0),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.color,
    required this.icon,
    this.onTap,
  });

  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _SwipeWorkoutItemState._actionWidth,
      height: double.infinity,
      child: Material(
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        color: color,
        child: InkWell(
          splashColor: darken(
            color,
            0.08,
          ).withValues(alpha: 0.8),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
