import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/state/past_workouts_state.dart';
import 'package:gym_tracker_app/state/theme_mode_state.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/number_format.dart';
import 'package:gym_tracker_app/util/privacy_policy.dart';
import 'package:gym_tracker_app/widgets/app_bottom_sheet.dart';
import 'package:gym_tracker_app/widgets/app_button.dart';
import 'package:gym_tracker_app/widgets/screen_title.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Profile: who is signed in, the appearance setting, privacy policy, sign
/// out and account deletion.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isDeletingAccount = false;

  Future<void> _openPrivacyPolicy() async {
    final opened = await openPrivacyPolicy();

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the privacy policy.'),
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final shouldDelete = await showDeleteAccountSheet(context: context);

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() => _isDeletingAccount = true);
    try {
      await ref.read(userAuthenticationProvider.notifier).deleteAccount();
    } catch (error, stackTrace) {
      log(
        'Account deletion failed.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your account could not be deleted. Please try again.',
          ),
        ),
      );
      setState(() => _isDeletingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final name = ref.watch(userAuthenticationProvider).firstName?.trim() ?? '';
    final workouts = ref.watch(pastWorkoutsProvider).workouts.length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          t.spacing.screen,
          16,
          t.spacing.screen,
          t.spacing.contentBottom,
        ),
        children: [
          const ScreenTitle('Profile'),
          SizedBox(height: t.spacing.gap22),
          Row(
            spacing: t.spacing.gap14,
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.accent,
                  borderRadius: BorderRadius.circular(t.radii.button),
                ),
                child: name.isEmpty
                    ? Icon(LucideIcons.user, size: 26, color: t.accentInk)
                    : Text(
                        name.characters.first.toUpperCase(),
                        style: AppTypography.avatar.copyWith(
                          fontSize: 24,
                          color: t.accentInk,
                        ),
                      ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    if (name.isNotEmpty)
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTypography.headerName.copyWith(letterSpacing: 0),
                      ),
                    Text(
                      '${formatCount(workouts, 'workout')} logged'
                          .toUpperCase(),
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 12,
                        color: t.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: t.spacing.gap22),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(t.radii.card),
              border: Border.all(color: t.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Appearance', style: AppTypography.body),
                      _AppearanceToggle(
                        dark: Theme.of(context).brightness == Brightness.dark,
                        onChanged: (dark) =>
                            ref.read(themeModeProvider.notifier).setThemeMode(
                                  dark ? ThemeMode.dark : ThemeMode.light,
                                ),
                      ),
                    ],
                  ),
                ),
                const _RowDivider(),
                _SettingsRow(
                  label: 'Privacy Policy',
                  icon: LucideIcons.chevronRight,
                  onTap: _openPrivacyPolicy,
                ),
                const _RowDivider(),
                _SettingsRow(
                  label: 'Sign out',
                  icon: LucideIcons.logOut,
                  iconSize: 18,
                  onTap: _isDeletingAccount
                      ? null
                      : ref.read(userAuthenticationProvider.notifier).signOut,
                ),
              ],
            ),
          ),
          SizedBox(height: t.spacing.gap22),
          AppButton(
            label: _isDeletingAccount ? 'Deleting account…' : 'Delete account',
            style: AppButtonStyle.dangerSoft,
            height: 52,
            textStyle: AppTypography.buttonSecondary,
            onPressed: _isDeletingAccount ? null : _deleteAccount,
          ),
        ],
      ),
    );
  }
}

/// Asks before deleting the account. Completes with true only when the user
/// confirms.
Future<bool?> showDeleteAccountSheet({required BuildContext context}) {
  return showAppSheet<bool>(
    context: context,
    children: (sheetContext) {
      final t = sheetContext.tokens;
      return [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            const Text('Delete account?', style: AppTypography.cardTitleLarge),
            Text(
              'This permanently removes your account and all workout history.',
              style: AppTypography.body.copyWith(color: t.muted, height: 1.45),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            AppButton(
              label: 'Delete account',
              style: AppButtonStyle.danger,
              onPressed: () => Navigator.of(sheetContext).pop(true),
            ),
            AppButton(
              label: 'Cancel',
              style: AppButtonStyle.neutral,
              onPressed: () => Navigator.of(sheetContext).pop(false),
            ),
          ],
        ),
      ];
    },
  );
}

class _AppearanceToggle extends StatelessWidget {
  const _AppearanceToggle({required this.dark, required this.onChanged});

  /// Which side is highlighted. Follows the theme on screen, so it is right
  /// while the app is still following the system setting.
  final bool dark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget option(String label, bool value) {
      final selected = dark == value;
      return Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? t.card : t.card.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(9),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onChanged(value),
            child: Container(
              height: 30,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: t.fg,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.card2,
        borderRadius: BorderRadius.circular(t.radii.tile),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [option('Dark', true), option('Light', false)],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconSize = 16,
  });

  final String label;
  final IconData icon;
  final double iconSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(t.radii.rowSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.body),
            Icon(icon, size: iconSize, color: t.muted),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: context.tokens.line),
      ),
    );
  }
}
