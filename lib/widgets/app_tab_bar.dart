import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/widgets/app_glass.dart';
import 'package:gym_tracker_app/widgets/outer_shadow.dart';
import 'package:gym_tracker_app/widgets/release_to_select.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum AppTab {
  home('Home', LucideIcons.house),
  tracker('Tracker', LucideIcons.layoutGrid),
  notifications('Notifications', LucideIcons.bell),
  profile('Profile', LucideIcons.user);

  const AppTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// The floating glass tab bar: 340×66 with a bubble that slides to the
/// selected tab. One of the two places liquid glass is allowed.
///
/// The design's bubble is 82×52, inset 7 from the bar's edge. The package
/// fixes the inset at 4, so the bubble here is about 5 taller and sits about
/// 2.5 closer to the edge.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.hasUnread = false,
  });

  final AppTab selected;
  final ValueChanged<AppTab> onSelected;

  /// Shows the dot on the bell.
  final bool hasUnread;

  static const width = 340.0;
  static const height = 66.0;
  static const _padding = 6.0;
  static const _iconSize = 22.0;
  static const _bubbleGrowth = EdgeInsets.symmetric(horizontal: 6, vertical: 4);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(t.radii.tabBar);
    return SizedBox(
      width: width,
      height: height,
      child: OuterShadow(
        borderRadius: radius,
        shadows: t.tabBarShadow,
        child: ReleaseToSelect(
          selectedIndex: selected.index,
          onSelected: (index) => onSelected(AppTab.values[index]),
          builder: (context, index, onTabSelected) => GlassTabBar.bottom(
            selectedIndex: index,
            onTabSelected: onTabSelected,
            tabs: [
              for (final tab in AppTab.values)
                GlassTab(
                  label: tab.label,
                  icon: tab == AppTab.notifications && hasUnread
                      ? _UnreadBell(icon: tab.icon)
                      : Icon(tab.icon),
                ),
            ],
            horizontalPadding: 0,
            verticalPadding: 0,
            barHeight: height,
            barBorderRadius: t.radii.tabBar,
            tabPadding: const EdgeInsets.symmetric(horizontal: _padding),
            // No bubble radius is given, so the bubble is a full capsule at any
            // size; a fixed one looks square once the bubble grows under a
            // finger. It grows by half the package's default.
            indicatorExpansion: _bubbleGrowth,
            iconSize: _iconSize,
            iconLabelSpacing: 3,
            magnification: 1,
            textStyle: AppTypography.tabLabel,
            selectedIconColor: t.fg,
            selectedLabelColor: t.fg,
            unselectedIconColor: t.muted,
            unselectedLabelColor: t.muted,
            indicatorColor: t.glassBubble,
            indicatorSettings: appTabBubbleSettings(t),
            settings: appGlassSettings(t),
          ),
        ),
      ),
    );
  }
}

class _UnreadBell extends StatelessWidget {
  const _UnreadBell({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          top: 0,
          right: 1,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: context.tokens.danger,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
