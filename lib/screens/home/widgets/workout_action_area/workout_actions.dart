import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/util/color_utils.dart';
import 'package:gym_tracker_app/widgets/action_button.dart';
import 'package:gym_tracker_app/widgets/floating_action_row.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WorkoutActions extends ConsumerStatefulWidget {
  const WorkoutActions({
    super.key,
  });

  @override
  ConsumerState<WorkoutActions> createState() => _WorkoutActionsState();
}

class _WorkoutActionsState extends ConsumerState<WorkoutActions> {
  final _formKey = GlobalKey<FormState>();

  final exerciseController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return FloatingActionRow(
      children: [
        Expanded(
          flex: 7,
          child: ActionButton.primary(
            onPressed: () => {
              showModalBottomSheet<void>(
                  backgroundColor: Colors.white,
                  isScrollControlled: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  context: context,
                  builder: (BuildContext context) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 50,
                        left: 20,
                        right: 20,
                      ),
                      child: Center(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            spacing: 20,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              TextFormField(
                                cursorColor: Color.fromARGB(255, 38, 62, 35),
                                decoration: const InputDecoration(
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xff232F3E)),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color(0xff232F3E), width: 2),
                                  ),
                                ),
                                controller: exerciseController,
                                autofocus: true,
                                // The validator receives the text that the user has entered.
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an exercise name';
                                  }
                                  return null;
                                },
                              ),
                              ElevatedButton(
                                style: ButtonStyle(
                                  overlayColor: WidgetStatePropertyAll<Color?>(
                                    darken(
                                      primaryColour,
                                      0.08,
                                    ).withValues(alpha: 0.8),
                                  ),
                                  backgroundColor:
                                      WidgetStatePropertyAll<Color>(
                                          Color(0xffB6E3FF)),
                                ),
                                onPressed: () {
                                  startExercise(exerciseController.text);
                                },
                                child: const Text(
                                  'Start exercise',
                                  style: TextStyle(
                                    color: Color(0xff202730),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).whenComplete(() {
                if (mounted) {
                  setState(() {
                    exerciseController.text = "";
                  });
                }
              })
            },
            icon: LucideIcons.plus,
            label: 'Add exercise',
          ),
        ),
        Expanded(
          flex: 5,
          child: ActionButton.stop(
            onPressed: endWorkout,
            label: 'End workout',
          ),
        ),
      ],
    );
  }

  void startExercise(String exerciseName) {
    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      ref.read(currentWorkoutProvider.notifier).startExercise(exerciseName);

      Navigator.pop(context);
    }
  }

  void endWorkout() {
    // clear workout state
    ref.read(currentWorkoutProvider.notifier).endWorkout();
  }
}
