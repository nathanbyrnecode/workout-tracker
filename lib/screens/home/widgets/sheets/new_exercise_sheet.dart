import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:gym_tracker_app/models/cardio_timer.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/widgets/app_bottom_sheet.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';
import 'package:gym_tracker_app/widgets/app_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

typedef NewExercise = ({String name, ExerciseType type});

/// Asks for the name and type of the exercise to add. Completes with them,
/// the name trimmed and never empty, or null if the sheet was dismissed. The
/// type starts on Strength each time the sheet opens.
Future<NewExercise?> showNewExerciseSheet({required BuildContext context}) {
  return showAppSheet<NewExercise>(
    context: context,
    children: (sheetContext) => [const _NewExerciseForm()],
  );
}

class _NewExerciseForm extends StatefulWidget {
  const _NewExerciseForm();

  @override
  State<_NewExerciseForm> createState() => _NewExerciseFormState();
}

class _NewExerciseFormState extends State<_NewExerciseForm> {
  final _name = TextEditingController();
  ExerciseType _type = ExerciseType.strength;

  bool get _hasName => _name.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_hasName) {
      Navigator.of(context).pop((name: _name.text.trim(), type: _type));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final labelStyle = AppTypography.label.copyWith(color: t.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('New exercise', style: AppTypography.sheetTitle),
        SizedBox(height: t.spacing.gap18),
        // Merged so a screen reader announces the label with the field.
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: t.spacing.gap8,
            children: [
              Semantics(
                label: 'Name',
                excludeSemantics: true,
                child: Text('NAME', style: labelStyle),
              ),
              AppTextField(
                controller: _name,
                placeholder: _type == ExerciseType.cardio
                    ? 'e.g. Treadmill run'
                    : 'e.g. Bench press',
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _confirm(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('TYPE', style: labelStyle),
        SizedBox(height: t.spacing.gap8),
        Semantics(
          container: true,
          explicitChildNodes: true,
          role: SemanticsRole.radioGroup,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: t.spacing.gap10,
              children: [
                Expanded(
                  child: _TypeTile(
                    icon: LucideIcons.dumbbell,
                    title: 'Strength',
                    subtitle: 'Sets, reps & weight',
                    selected: _type == ExerciseType.strength,
                    onTap: () => setState(() => _type = ExerciseType.strength),
                  ),
                ),
                Expanded(
                  child: _TypeTile(
                    icon: LucideIcons.heartPulse,
                    title: 'Cardio',
                    subtitle: 'Timed, with laps',
                    selected: _type == ExerciseType.cardio,
                    onTap: () => setState(() => _type = ExerciseType.cardio),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Add exercise',
          onPressed: _hasName ? _confirm : null,
          disabledOpacity: 0.5,
        ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: '$title. $subtitle',
      onTap: onTap,
      excludeSemantics: true,
      child: Opacity(
        opacity: selected ? 1 : 0.45,
        child: Material(
          color: t.card2,
          borderRadius: BorderRadius.circular(t.radii.card),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: t.spacing.gap14,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected ? t.accent : t.card,
                      borderRadius: BorderRadius.circular(t.radii.tileMedium),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: selected ? t.accentInk : t.muted,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: [
                      Text(title, style: AppTypography.cardTitle),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          color: t.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
