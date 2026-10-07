import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/number_format.dart';
import 'package:gym_tracker_app/util/single_period_enforcer.dart';
import 'package:gym_tracker_app/widgets/app_bottom_sheet.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';

typedef SetValues = ({double weight, int reps});

/// What a new set starts from when the exercise has no sets yet.
const SetValues defaultSetValues = (weight: 20, reps: 10);

const weightStep = 2.5;

/// Adds or edits a set. Completes with the weight and reps, or null if the
/// sheet was dismissed.
///
/// [number] is the set's number from 1. [initial] pre-fills the fields: the
/// previous set when adding, the set itself when editing.
Future<SetValues?> showSetSheet({
  required BuildContext context,
  required int number,
  required SetValues initial,
  bool editing = false,
}) {
  return showAppSheet<SetValues>(
    context: context,
    children: (sheetContext) => [
      _SetForm(number: number, initial: initial, editing: editing),
    ],
  );
}

class _SetForm extends StatefulWidget {
  const _SetForm({
    required this.number,
    required this.initial,
    required this.editing,
  });

  final int number;
  final SetValues initial;
  final bool editing;

  @override
  State<_SetForm> createState() => _SetFormState();
}

class _SetFormState extends State<_SetForm> {
  late final _weight =
      TextEditingController(text: formatWeight(widget.initial.weight));
  late final _reps = TextEditingController(text: '${widget.initial.reps}');

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  // Anything that is not a number counts as zero, as an empty field does.
  double get _weightValue => double.tryParse(_weight.text) ?? 0;
  int get _repsValue => int.tryParse(_reps.text) ?? 0;

  void _stepWeight(double by) {
    final next = (_weightValue + by).clamp(0, double.infinity).toDouble();
    _weight.text = formatWeight(next);
  }

  void _stepReps(int by) {
    _reps.text = '${(_repsValue + by).clamp(0, 1 << 31)}';
  }

  void _confirm() =>
      Navigator.of(context).pop((weight: _weightValue, reps: _repsValue));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [
        Text(
          widget.editing ? 'Edit set ${widget.number}' : 'Set ${widget.number}',
          style: AppTypography.sheetTitle,
        ),
        Row(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _NumberTile(
                label: 'WEIGHT · KG',
                controller: _weight,
                decimal: true,
                onDecrease: () => _stepWeight(-weightStep),
                onIncrease: () => _stepWeight(weightStep),
              ),
            ),
            Expanded(
              child: _NumberTile(
                label: 'REPS',
                controller: _reps,
                decimal: false,
                onDecrease: () => _stepReps(-1),
                onIncrease: () => _stepReps(1),
              ),
            ),
          ],
        ),
        AppButton(
          label: widget.editing ? 'Save changes' : 'Add set',
          onPressed: _confirm,
        ),
      ],
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({
    required this.label,
    required this.controller,
    required this.decimal,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final TextEditingController controller;
  final bool decimal;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.card2,
        borderRadius: BorderRadius.circular(t.radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: t.muted),
          ),
          TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(decimal ? r'[\d.]' : r'\d'),
              ),
              if (decimal) SinglePeriodEnforcer(),
              LengthLimitingTextInputFormatter(6),
            ],
            cursorColor: t.accentText,
            style: AppTypography.numberInput.copyWith(color: t.fg),
            decoration: const InputDecoration.collapsed(hintText: null),
          ),
          Row(
            spacing: 6,
            children: [
              Expanded(
                child: _StepButton(
                  symbol: '−',
                  semanticLabel: 'Decrease ${label.toLowerCase()}',
                  onPressed: onDecrease,
                ),
              ),
              Expanded(
                child: _StepButton(
                  symbol: '+',
                  semanticLabel: 'Increase ${label.toLowerCase()}',
                  onPressed: onIncrease,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.symbol,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String symbol;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radii.tile),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                symbol,
                style: AppTypography.input.copyWith(fontSize: 20, color: t.fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
