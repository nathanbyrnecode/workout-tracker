import 'package:flutter/material.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';

/// Material theme for one brightness, carrying [AppTokens] as an extension.
ThemeData buildAppTheme(Brightness brightness) {
  final tokens = AppTokens.of(brightness);
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: AppTypography.sans,
    scaffoldBackgroundColor: tokens.bg,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: tokens.accent,
      onPrimary: tokens.accentInk,
      secondary: tokens.accent,
      onSecondary: tokens.accentInk,
      error: tokens.danger,
      onError: tokens.bg,
      surface: tokens.bg,
      onSurface: tokens.fg,
      onSurfaceVariant: tokens.muted,
      outline: tokens.line,
      outlineVariant: tokens.line,
      scrim: tokens.scrim,
    ),
    dividerColor: tokens.line,
    extensions: [tokens],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: tokens.fg,
      displayColor: tokens.fg,
    ),
  );
}
