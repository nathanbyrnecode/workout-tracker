import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
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

/// The floating glass tab bar: 340×66 with an 82×52 bubble that slides to the
/// selected tab. One of the two places liquid glass is allowed.
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

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.radii.tabBar),
          boxShadow: t.tabBarShadow,
        ),
        child: GlassTabBar.bottom(
          selectedIndex: selected.index,
          onTabSelected: (index) => onSelected(AppTab.values[index]),
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
          indicatorBorderRadius: (height - _padding * 2) / 2,
          iconSize: _iconSize,
          iconLabelSpacing: 3,
          magnification: 1,
          textStyle: AppTypography.buttonSecondary.copyWith(fontSize: 10),
          selectedIconColor: t.fg,
          selectedLabelColor: t.fg,
          unselectedIconColor: t.muted,
          unselectedLabelColor: t.muted,
          indicatorColor: t.glassBubble,
          settings: LiquidGlassSettings(
            glassColor: t.glass,
            blur: 24,
            saturation: 1.9,
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
