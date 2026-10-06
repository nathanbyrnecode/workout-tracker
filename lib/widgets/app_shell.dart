import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/widgets/app_background.dart';
import 'package:gym_tracker_app/widgets/app_tab_bar.dart';

/// The frame around the four main screens: background glows, the current
/// screen, an optional row of floating actions and the glass tab bar.
///
/// Screens pushed with `Navigator` cover the shell, which is how Summary and
/// the detail screens hide the tab bar.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.child,
    this.floatingActions,
    this.hasUnread = false,
  });

  final AppTab selected;
  final ValueChanged<AppTab> onSelected;

  /// The screen for [selected].
  final Widget child;

  /// Shown above the tab bar, usually a `FloatingActionRow`.
  final Widget? floatingActions;
  final bool hasUnread;

  /// Distance from the bottom of the screen to the tab bar and to the
  /// floating actions, on the design's 844pt frame.
  static const tabBarBottom = 26.0;
  static const floatingActionsBottom = 106.0;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // The design draws to the bottom edge of an iPhone. Where the system
    // inset is taller than that (Android button navigation), move up.
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    final lift = max(0.0, inset + 8 - tabBarBottom);

    return Scaffold(
      backgroundColor: t.bg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackground(),
          child,
          if (floatingActions != null)
            Positioned(
              left: t.spacing.screen,
              right: t.spacing.screen,
              bottom: floatingActionsBottom + lift,
              child: floatingActions!,
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: tabBarBottom + lift,
            child: Center(
              child: AppTabBar(
                selected: selected,
                onSelected: onSelected,
                hasUnread: hasUnread,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
