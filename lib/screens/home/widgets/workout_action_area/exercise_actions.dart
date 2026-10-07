import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/util/color_utils.dart';
import 'package:gym_tracker_app/util/single_period_enforcer.dart';
import 'package:gym_tracker_app/widgets/action_button.dart';
import 'package:gym_tracker_app/widgets/floating_action_row.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ExerciseActions extends ConsumerStatefulWidget {
  const ExerciseActions({
    super.key,
  });

  @override
  ConsumerState<ExerciseActions> createState() => _ExerciseActionsState();
}

class _ExerciseActionsState extends ConsumerState<ExerciseActions> {
  final _formKey = GlobalKey<FormState>();

  final weightController = TextEditingController();
  final repsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FloatingActionRow(
      children: [
        Expanded(
          flex: 7,
          child: ActionButton.primary(
            onPressed: () => showModalBottomSheet<void>(
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
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d\.]')),
                                SinglePeriodEnforcer()
                              ],
                              decoration: InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xff232F3E)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xff232F3E), width: 2),
                                ),
                                suffixIcon: Align(
                                    widthFactor: double.minPositive,
                                    alignment: Alignment.centerRight,
                                    child: Text("KG")),
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              controller: weightController,
                              autofocus: true,
                              // The validator receives the text that the user has entered.
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the weight';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              cursorColor: Color.fromARGB(255, 38, 62, 35),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d]'))
                              ],
                              decoration: InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xff232F3E)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xff232F3E), width: 2),
                                ),
                                suffixIcon: Align(
                                    widthFactor: double.minPositive,
                                    alignment: Alignment.centerRight,
                                    child: Text("Reps")),
                              ),
                              keyboardType: TextInputType.numberWithOptions(),
                              controller: repsController,
                              // The validator receives the text that the user has entered.
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the number of reps';
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
                                backgroundColor: WidgetStatePropertyAll<Color>(
                                    Color(0xffB6E3FF)),
                              ),
                              onPressed: () {
                                addSet(
                                    weightController.text, repsController.text);
                              },
                              child: const Text(
                                'Add set',
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
                  weightController.text = "";
                  repsController.text = "";
                });
              }
            }),
            label: 'Add set',
            icon: LucideIcons.plus,
          ),
        ),
        Expanded(
          flex: 5,
          child: ActionButton.stop(
            onPressed: endExercise,
            label: 'End exercise',
          ),
        ),
      ],
    );
  }

  void addSet(String weight, String reps) {
    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState!.validate()) {
      var parsedWeight = num.tryParse(weight);
      var parsedReps = num.tryParse(reps);

      if (parsedWeight != null && parsedReps != null) {
        ref
            .read(currentWorkoutProvider.notifier)
            .addSetToCurrentExercise(reps, weight);

        // Unfocus the text fields first
        FocusScope.of(context).unfocus();

        Navigator.pop(context);
      }
    }
  }

  void endExercise() {
    ref.read(currentWorkoutProvider.notifier).endExercise();
  }
}
