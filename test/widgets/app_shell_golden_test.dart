import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/widgets/app_shell.dart';
import 'package:gym_tracker_app/widgets/app_tab_bar.dart';
import 'package:gym_tracker_app/widgets/floating_action_row.dart';

import '../helpers/golden.dart';

void main() {
  for (final tab in AppTab.values) {
    goldenTest(
      'shell with the ${tab.label} tab selected',
      name: 'app_shell_${tab.name}',
      builder: (context) => _Shell(selected: tab),
    );
  }

  goldenTest(
    'shell with floating actions and no unread dot',
    name: 'app_shell_actions',
    builder: (context) => const _Shell(
      selected: AppTab.home,
      hasUnread: false,
      showActions: true,
    ),
  );
}

class _Shell extends StatelessWidget {
  const _Shell({
    required this.selected,
    this.hasUnread = true,
    this.showActions = false,
  });

  final AppTab selected;
  final bool hasUnread;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppShell(
      selected: selected,
      onSelected: (_) {},
      hasUnread: hasUnread,
      floatingActions: showActions
          ? FloatingActionRow(
              children: [
                Expanded(
                  child: Container(
                    height: t.spacing.buttonHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(t.radii.button),
                      boxShadow: t.floatingShadow,
                    ),
                    child: Text(
                      'Start workout',
                      style: AppTypography.button.copyWith(color: t.accentInk),
                    ),
                  ),
                ),
              ],
            )
          : null,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(t.spacing.screen),
          child: Text(selected.label, style: AppTypography.screenTitle),
        ),
      ),
    );
  }
}
