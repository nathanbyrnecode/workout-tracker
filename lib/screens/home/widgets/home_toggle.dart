import 'package:flutter/material.dart';
import 'package:gym_tracker_app/state/current_tab_state.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/widgets/app_glass.dart';
import 'package:gym_tracker_app/widgets/outer_shadow.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// The glass Current / Previous toggle. With the tab bar, one of the two
/// places liquid glass is allowed.
class HomeToggle extends StatelessWidget {
  const HomeToggle({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final TabItem selected;
  final ValueChanged<TabItem> onSelected;

  static const height = 46.0;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return OuterShadow(
      borderRadius: BorderRadius.circular(t.radii.toggle),
      shadows: t.toggleShadow,
      child: GlassSegmentedControl(
        segments: const [
          GlassSegment(label: 'Current'),
          GlassSegment(label: 'Previous'),
        ],
        selectedIndex: selected.index,
        onSegmentSelected: (index) => onSelected(TabItem.values[index]),
        height: height,
        borderRadius: t.radii.toggle,
        indicatorBorderRadius: t.radii.toggleBubble,
        padding: const EdgeInsets.all(4),
        selectedTextStyle: AppTypography.toggle.copyWith(color: t.fg),
        unselectedTextStyle: AppTypography.toggle.copyWith(color: t.muted),
        indicatorColor: t.glassBubble,
        settings: appGlassSettings(t),
      ),
    );
  }
}
