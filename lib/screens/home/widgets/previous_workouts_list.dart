import 'package:flutter/material.dart';
import 'package:gym_tracker_app/screens/home/widgets/past_workout_card.dart';
import 'package:gym_tracker_app/models/workout.dart';

class PreviousWorkoutsList extends StatelessWidget {
  const PreviousWorkoutsList({
    super.key,
    required this.pastWorkouts,
  });

  final List<Workout> pastWorkouts;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: ListView.separated(
          padding: EdgeInsets.only(top: 20, bottom: 20),
          separatorBuilder: (context, index) => SizedBox(
            height: 10,
          ),
          shrinkWrap: true,
          itemCount: pastWorkouts.length,
          itemBuilder: (context, index) {
            return PastWorkoutCard(workout: pastWorkouts[index]);
          },
        ),
      ),
    );
  }
}
