import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Avatar, greeting over the user's name, and the bell button.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.firstName,
    required this.now,
    required this.onOpenNotifications,
    this.hasUnread = false,
  });

  /// Null or empty when the sign-in provider gave no name.
  final String? firstName;
  final DateTime now;
  final VoidCallback onOpenNotifications;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final name = firstName?.trim() ?? '';
    final greeting = greetingFor(now);

    return Padding(
      padding: EdgeInsets.fromLTRB(t.spacing.screen, 14, t.spacing.screen, 0),
      child: Row(
        spacing: t.spacing.gap12,
        children: [
          Container(
            width: t.spacing.iconButton,
            height: t.spacing.iconButton,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.accent,
              borderRadius: BorderRadius.circular(t.radii.iconButton),
            ),
            child: name.isEmpty
                ? Icon(LucideIcons.user, size: 20, color: t.accentInk)
                : Text(
                    name.characters.first.toUpperCase(),
                    style: AppTypography.avatar.copyWith(color: t.accentInk),
                  ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // With no name to show, the greeting takes the name's place.
                if (name.isNotEmpty)
                  Text(
                    greeting,
                    style: AppTypography.bodySmall.copyWith(color: t.muted),
                  ),
                Text(
                  name.isEmpty ? greeting : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headerName,
                ),
              ],
            ),
          ),
          _BellButton(onPressed: onOpenNotifications, hasUnread: hasUnread),
        ],
      ),
    );
  }
}

/// "Good morning" before noon, "Good afternoon" before 18:00, then
/// "Good evening".
String greetingFor(DateTime time) => time.hour < 12
    ? 'Good morning'
    : time.hour < 18
        ? 'Good afternoon'
        : 'Good evening';

class _BellButton extends StatelessWidget {
  const _BellButton({required this.onPressed, required this.hasUnread});

  final VoidCallback onPressed;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(t.radii.iconButton);
    return Semantics(
      button: true,
      label: 'Notifications',
      child: Material(
        color: t.card,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: t.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: t.spacing.iconButton,
            height: t.spacing.iconButton,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(LucideIcons.bell, size: 20, color: t.fg),
                if (hasUnread)
                  Positioned(
                    top: 7,
                    right: 8,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: t.accent,
                        shape: BoxShape.circle,
                        // The ring that separates the dot from the bell.
                        border: Border.all(color: t.card, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
