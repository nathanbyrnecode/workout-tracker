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
  return base.copyWith(textTheme: _textTheme(base.textTheme, tokens.fg));
}

/// Material 3's text theme carries its own letter spacing and line heights,
/// which every `Text` inherits unless its style overrides them. That made
/// text wider than the design. This keeps the sizes and weights and drops the
/// rest, so [AppTypography] styles render exactly as written.
TextTheme _textTheme(TextTheme base, Color color) {
  TextStyle? plain(TextStyle? style) => style == null
      ? null
      : TextStyle(
          fontFamily: AppTypography.sans,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
          letterSpacing: 0,
          color: color,
        );
  return TextTheme(
    displayLarge: plain(base.displayLarge),
    displayMedium: plain(base.displayMedium),
    displaySmall: plain(base.displaySmall),
    headlineLarge: plain(base.headlineLarge),
    headlineMedium: plain(base.headlineMedium),
    headlineSmall: plain(base.headlineSmall),
    titleLarge: plain(base.titleLarge),
    titleMedium: plain(base.titleMedium),
    titleSmall: plain(base.titleSmall),
    bodyLarge: plain(base.bodyLarge),
    bodyMedium: plain(base.bodyMedium),
    bodySmall: plain(base.bodySmall),
    labelLarge: plain(base.labelLarge),
    labelMedium: plain(base.labelMedium),
    labelSmall: plain(base.labelSmall),
  );
}
