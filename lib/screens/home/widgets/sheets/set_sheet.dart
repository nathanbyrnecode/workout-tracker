import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_tracker_app/models/exercise_set.dart';
import 'package:gym_tracker_app/models/weight_unit.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/number_format.dart';
import 'package:gym_tracker_app/util/single_period_enforcer.dart';
import 'package:gym_tracker_app/widgets/app_bottom_sheet.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';

typedef SetValues = ({double weight, int reps, WeightUnit unit});

/// What a new set starts from when the exercise has no sets yet, in kg.
const SetValues defaultSetValues = (weight: 20, reps: 10, unit: WeightUnit.kg);

/// What the sheet opens with for a new set: the exercise's last set, or
/// otherwise the default weight converted to [unit].
SetValues newSetValues(Iterable<ExerciseSet> sets, {required WeightUnit unit}) {
  if (sets.isNotEmpty) {
    final last = sets.last;
    return (weight: last.weight, reps: last.reps, unit: last.unit);
  }
  return (
    weight: defaultSetValues.unit.convert(defaultSetValues.weight, unit),
    reps: defaultSetValues.reps,
    unit: unit,
  );
}

/// Adds or edits a set. Completes with the weight, reps and unit, or null if
/// the sheet was dismissed.
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
  late WeightUnit _unit = widget.initial.unit;

  /// What the field held before the last unit switch, and what the switch
  /// put there. Converting rounds to 0.5, so converting back could land on a
  /// different number (46 lb → 21 kg → 46.5 lb). Switching back without
  /// editing restores the original instead.
  ({String text, WeightUnit unit, String converted})? _lastSwitch;

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

  void _switchUnit() {
    final from = _unit;
    final to = from.other;
    final text = _weight.text;
    final last = _lastSwitch;
    final converted = last != null && last.unit == to && last.converted == text
        ? last.text
        : formatWeight(from.convert(_weightValue, to));
    setState(() {
      _lastSwitch = (text: text, unit: from, converted: converted);
      _unit = to;
    });
    _weight.text = converted;
  }

  void _stepReps(int by) {
    _reps.text = '${(_repsValue + by).clamp(0, 1 << 31)}';
  }

  void _confirm() => Navigator.of(context)
      .pop((weight: _weightValue, reps: _repsValue, unit: _unit));

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
                label: 'WEIGHT',
                trailing: _UnitToggle(unit: _unit, onToggle: _switchUnit),
                controller: _weight,
                decimal: true,
                onDecrease: () => _stepWeight(-_unit.step),
                onIncrease: () => _stepWeight(_unit.step),
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

/// The tap target of the unit toggle, and so the height of the label rows.
const _labelRowHeight = 44.0;

class _NumberTile extends StatelessWidget {
  const _NumberTile({
    required this.label,
    required this.controller,
    required this.decimal,
    required this.onDecrease,
    required this.onIncrease,
    this.trailing,
  });

  final String label;

  /// Sits at the end of the label row.
  final Widget? trailing;
  final TextEditingController controller;
  final bool decimal;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      // The label row is 32 tall to the eye. It is laid out at 44, taking 6
      // from the space above and below, so the unit toggle's tap target
      // reaches 44 without moving anything.
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      decoration: BoxDecoration(
        color: t.card2,
        borderRadius: BorderRadius.circular(t.radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _labelRowHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: t.spacing.gap6,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(color: t.muted),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          SizedBox(height: t.spacing.gap6),
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
          SizedBox(height: t.spacing.gap14),
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

/// One control that flips between kg and lb: a tap anywhere on it switches,
/// including on the unit already selected. Deliberately quiet, with no border
/// or accent, because it is a setting and not a call to action.
class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.unit, required this.onToggle});

  final WeightUnit unit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: 'Weight in ${unit.name}. Switch to ${unit.other.name}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        child: SizedBox(
          height: _labelRowHeight,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(t.radii.tag),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in WeightUnit.values)
                    _UnitSegment(unit: option, selected: option == unit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitSegment extends StatelessWidget {
  const _UnitSegment({required this.unit, required this.selected});

  final WeightUnit unit;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: 28,
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? t.card2 : t.card2.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(t.radii.chip),
      ),
      child: Text(
        unit.name.toUpperCase(),
        style: AppTypography.pill.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? t.fg : t.muted,
        ),
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
