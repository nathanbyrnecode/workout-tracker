import 'package:flutter/material.dart';
import 'package:gym_tracker_app/state/current_tab_state.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/widgets/app_glass.dart';
import 'package:gym_tracker_app/widgets/glass_rim.dart';
import 'package:gym_tracker_app/widgets/outer_shadow.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// The glass Current / Previous toggle. With the tab bar, one of the two
/// places liquid glass is allowed.
///
/// The package makes only the sliding bubble from glass; its track is a plain
/// fill. So the track takes the `glass` token as its colour and [GlassRim]
/// draws the design's border and highlights over it. There is no blur behind
/// the track: nothing scrolls under it, only the background glows.
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
    final radius = BorderRadius.circular(t.radii.toggle);
    return OuterShadow(
      borderRadius: radius,
      shadows: t.toggleShadow,
      child: GlassRim(
        borderRadius: radius,
        child: GlassSegmentedControl(
          segments: const [
            GlassSegment(label: 'Current'),
            GlassSegment(label: 'Previous'),
          ],
          selectedIndex: selected.index,
          onSegmentSelected: (index) => onSelected(TabItem.values[index]),
          height: height,
          borderRadius: t.radii.toggle,
          // As on the tab bar: a capsule at any size, growing by half the
          // package's default while pressed.
          indicatorExpansion:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          // The 1px border plus the design's 4, which leaves a 170×36 bubble.
          padding: const EdgeInsets.all(5),
          backgroundColor: t.glass,
          selectedTextStyle: AppTypography.toggle.copyWith(color: t.fg),
          unselectedTextStyle: AppTypography.toggle.copyWith(color: t.muted),
          indicatorColor: t.glassBubble,
          indicatorSettings: appToggleBubbleSettings(t),
        ),
      ),
    );
  }
}
