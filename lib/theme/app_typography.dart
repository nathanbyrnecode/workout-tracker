import 'package:flutter/widgets.dart';

/// Text styles from the design README ("Typography"). Geist for UI text and
/// Geist Mono for numerals, timers and labels, both bundled in
/// `assets/fonts/`.
///
/// Styles carry no colour. Text takes `tokens.fg` from the theme by default;
/// use `copyWith(color: context.tokens.muted)` and similar for anything else.
abstract final class AppTypography {
  static const sans = 'Geist';
  static const mono = 'GeistMono';

  /// Screen titles: 30px, -0.035em.
  static const screenTitle = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w600,
    fontSize: 30,
    letterSpacing: -1.05,
  );

  /// Welcome headline: 44px, -0.04em.
  static const headline = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w600,
    fontSize: 44,
    letterSpacing: -1.76,
    height: 1.02,
  );

  /// The name in the Home header: 20px, -0.02em.
  static const headerName = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    letterSpacing: -0.4,
  );

  /// The main workout timer: 64px, -0.05em.
  static const timer = TextStyle(
    fontFamily: mono,
    fontWeight: FontWeight.w500,
    fontSize: 64,
    letterSpacing: -3.2,
    height: 1,
  );

  /// Card titles run from 16px to 22px.
  static const cardTitle = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );
  static const cardTitleLarge = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w600,
    fontSize: 22,
  );

  /// Stat numbers run from 20px to 26px.
  static const stat = TextStyle(
    fontFamily: mono,
    fontWeight: FontWeight.w500,
    fontSize: 20,
  );
  static const statLarge = TextStyle(
    fontFamily: mono,
    fontWeight: FontWeight.w500,
    fontSize: 26,
  );

  /// Micro labels: uppercase the text yourself. 11px at 0.14em.
  static const label = TextStyle(
    fontFamily: mono,
    fontWeight: FontWeight.w500,
    fontSize: 11,
    letterSpacing: 1.54,
  );

  /// 10px at 0.16em.
  static const labelSmall = TextStyle(
    fontFamily: mono,
    fontWeight: FontWeight.w500,
    fontSize: 10,
    letterSpacing: 1.6,
  );

  /// Body and secondary text run from 13px to 15px.
  static const body = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w400,
    fontSize: 15,
  );
  static const bodyMedium = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w400,
    fontSize: 14,
  );
  static const bodySmall = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w400,
    fontSize: 13,
  );

  static const button = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );
  static const buttonSecondary = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w600,
    fontSize: 15,
  );
}
