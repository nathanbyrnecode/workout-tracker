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

  /// The line height Geist and Geist Mono are designed with (ascent 1005,
  /// descent 295 per 1000 units), which is what the design's CSS uses.
  static const lineHeight = 1.3;

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

  /// The active exercise's name: 21px, -0.02em.
  static const exerciseName = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w600,
    fontSize: 21,
    letterSpacing: -0.42,
  );

  /// A set's weight or reps in the active exercise card.
  static const setValue = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w600,
    fontSize: 20,
  );

  /// A set's weight or reps in a compact row.
  static const setValueSmall = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w600,
    fontSize: 15,
  );

  /// Small emphasised text, such as "In progress · 00:55".
  static const caption = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w600,
    fontSize: 12,
  );

  /// Numbers in Geist Mono at body sizes: set numbers, row volumes, the rest
  /// timer. Set the size with `copyWith`.
  static const monoSmall = TextStyle(
    fontFamily: mono,
    fontWeight: FontWeight.w500,
    fontSize: 13,
  );

  /// The TOP SET / AVG footer: 11px at 0.08em.
  static const footnote = TextStyle(
    fontFamily: mono,
    fontWeight: FontWeight.w500,
    fontSize: 11,
    letterSpacing: 0.88,
  );

  /// Bottom sheet titles: 22px, -0.02em.
  static const sheetTitle = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w600,
    fontSize: 22,
    letterSpacing: -0.44,
  );

  /// Text typed into a field: 17px medium.
  static const input = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w500,
    fontSize: 17,
  );

  /// The large number typed into the set sheet: 40px, -0.04em.
  static const numberInput = TextStyle(
    fontFamily: mono,
    fontWeight: FontWeight.w500,
    fontSize: 40,
    letterSpacing: -1.6,
    height: 1.2,
  );

  /// The 12px mono label at 0.16em, as on WELCOME.
  static const labelLarge = TextStyle(
    fontFamily: mono,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    letterSpacing: 1.92,
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

  /// 11px at 0.16em, as on the WORKOUT label.
  static const labelWide = TextStyle(
    fontFamily: mono,
    fontWeight: FontWeight.w500,
    fontSize: 11,
    letterSpacing: 1.76,
  );

  /// 10px at 0.16em.
  static const labelSmall = TextStyle(
    fontFamily: mono,
    fontWeight: FontWeight.w500,
    fontSize: 10,
    letterSpacing: 1.6,
  );

  /// The ACTIVE / INACTIVE pill: 11px at 0.1em.
  static const pill = TextStyle(
    fontFamily: mono,
    fontWeight: FontWeight.w600,
    fontSize: 11,
    letterSpacing: 1.1,
  );

  /// The "N EX  N SETS  N KG VOL" row: 12px at 0.06em.
  static const statLine = TextStyle(
    fontFamily: mono,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    letterSpacing: 0.72,
  );

  /// The avatar initial.
  static const avatar = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w700,
    fontSize: 17,
  );

  /// Segmented toggle labels.
  static const toggle = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w600,
    fontSize: 14,
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

  /// Tab bar labels.
  static const tabLabel = TextStyle(
    fontFamily: sans,
    fontWeight: FontWeight.w600,
    fontSize: 10,
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
