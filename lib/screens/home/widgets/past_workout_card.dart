import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_tracker_app/screens/home/widgets/metric_card.dart';
import 'package:gym_tracker_app/models/workout.dart';

class PastWorkoutCard extends StatelessWidget {
  const PastWorkoutCard({
    super.key,
    required this.workout,
  });

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Color(0xffD9CDEE),
          ),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              "05/06/2025",
              style: TextStyle(fontSize: 14),
            ),
            Row(
              spacing: 8,
              children: [
                Icon(
                  Icons.timer,
                  color: Color(0xff5F5F5F),
                ),
                Text(
                  "01:24",
                  style: GoogleFonts.kodeMono(
                    color: Color(0xff5F5F5F),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ]),
        ),
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Color(0xffE8DEF8),
          ),
          child: Row(
            spacing: 14,
            children: [
              MetricCard(
                value: "4",
                label: "Exercises",
              ),
              MetricCard(
                value: "12",
                label: "Sets",
              ),
              MetricCard(
                value: "80",
                label: "Reps",
              ),
            ],
          ),
        )
      ]),
    );
  }
}
