import 'package:flutter/material.dart';

/// Colour, radius and spacing tokens from the "Design Tokens" section of
/// `design/workout-tracker/README.md`. This is the only place colours are
/// defined; read them with `context.tokens`.
///
/// The design gives some colours in OKLCH. They are converted to sRGB here and
/// match the pixels in `design/workout-tracker/screens/`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.bg,
    required this.card,
    required this.card2,
    required this.line,
    required this.fg,
    required this.muted,
    required this.accent,
    required this.accentInk,
    required this.accentText,
    required this.danger,
    required this.dangerBg,
    required this.sheet,
    required this.scrim,
    required this.glass,
    required this.glassLine,
    required this.glassHi,
    required this.glassLo,
    required this.glassBubble,
    required this.glassBubbleMoving,
    required this.glassShadow,
    required this.sheetShadow,
    required this.orb1,
    required this.orb2,
    required this.heat1,
    required this.heat2,
  });

  /// Screen background.
  final Color bg;

  /// Cards.
  final Color card;

  /// Inset rows, chips, inputs and empty tracker squares.
  final Color card2;

  /// 1px borders and dividers.
  final Color line;

  /// Primary text.
  final Color fg;

  /// Secondary text and labels.
  final Color muted;

  /// Primary buttons, the active pill and filled tracker squares.
  final Color accent;

  /// Text and icons on [accent].
  final Color accentInk;

  /// Accent-coloured text.
  final Color accentText;

  /// End and delete actions.
  final Color danger;

  /// Destructive button fill.
  final Color dangerBg;

  /// Bottom sheets.
  final Color sheet;

  /// Behind bottom sheets.
  final Color scrim;

  /// Glass fill.
  final Color glass;

  /// Glass border.
  final Color glassLine;

  /// Glass inner top highlight.
  final Color glassHi;

  /// Glass inner bottom shade.
  final Color glassLo;

  /// Selected glass pill.
  final Color glassBubble;

  /// Tint of the glass pill while it is pressed or dragged. Clear in the dark
  /// theme, where the bare lens already stands out.
  final Color glassBubbleMoving;

  /// Drop shadows under floating buttons and the tab bar.
  final Color glassShadow;

  /// Drop shadow above bottom sheets.
  final Color sheetShadow;

  /// The two blurred background glows.
  final Color orb1;
  final Color orb2;

  /// Tracker heat levels 1 and 2: [accent] mixed into [card2] at 35% and 65%.
  final Color heat1;
  final Color heat2;

  static const _accent = Color(0xFFC0F447);

  static const dark = AppTokens(
    bg: Color(0xFF0A0B0D),
    card: Color(0xFF15171A),
    card2: Color(0xFF1F2125),
    line: Color(0x14FFFFFF),
    fg: Color(0xFFF3F4EF),
    muted: Color(0xFF8B8F88),
    accent: _accent,
    accentInk: Color(0xFF0A0B0D),
    accentText: _accent,
    danger: Color(0xFFFF645F),
    dangerBg: Color(0x21FF645F),
    sheet: Color(0xFF141619),
    scrim: Color(0x8C000000),
    glass: Color(0x12FFFFFF),
    glassLine: Color(0x24FFFFFF),
    glassHi: Color(0x52FFFFFF),
    glassLo: Color(0x0DFFFFFF),
    glassBubble: Color(0x21FFFFFF),
    glassBubbleMoving: Color(0x00FFFFFF),
    glassShadow: Color(0x73000000),
    sheetShadow: Color(0x4D000000),
    orb1: Color(0x24C0F447),
    orb2: Color(0x2400B4BC),
    heat1: Color(0xFF536433),
    heat2: Color(0xFF83A33F),
  );

  static const light = AppTokens(
    bg: Color(0xFFF3F4EF),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFEBEDE6),
    line: Color(0x140A0C08),
    fg: Color(0xFF0F110D),
    muted: Color(0xFF666B63),
    accent: _accent,
    accentInk: Color(0xFF0F110D),
    accentText: Color(0xFF457200),
    danger: Color(0xFFD02B31),
    dangerBg: Color(0x1AD02B31),
    sheet: Color(0xFFFFFFFF),
    scrim: Color(0x590A0C08),
    glass: Color(0x80FFFFFF),
    glassLine: Color(0xD9FFFFFF),
    glassHi: Color(0xFFFFFFFF),
    glassLo: Color(0x0A000000),
    glassBubble: Color(0x120F110D),
    glassBubbleMoving: Color(0x2E0F110D),
    glassShadow: Color(0x24141810),
    sheetShadow: Color(0x4D000000),
    orb1: Color(0x66C0F447),
    orb2: Color(0x4D6BD8DE),
    heat1: Color(0xFFDBF1B9),
    heat2: Color(0xFFCFF38E),
  );

  static AppTokens of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// Radii and spacing are the same in both themes.
  AppRadii get radii => const AppRadii();
  AppSpacing get spacing => const AppSpacing();

  /// Text on a solid [danger] button. White in both themes.
  Color get onDanger => const Color(0xFFFFFFFF);

  /// The dark band that fills the End workout button while it is held:
  /// black at 32%.
  Color get holdBand => const Color(0x52000000);

  /// Border of the completed exercise row that is open: accent at 45%.
  Color get accentBorder => accent.withValues(alpha: 0.45);

  /// Tracker square colour for a heat level from 0 (nothing logged) to 3.
  Color heat(int level) => switch (level) {
        <= 0 => card2,
        1 => heat1,
        2 => heat2,
        _ => accent,
      };

  /// Under floating buttons: 0 10 30.
  List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: glassShadow,
          offset: const Offset(0, 10),
          blurRadius: 30,
        ),
      ];

  /// Under the Current/Previous toggle: 0 6 18.
  List<BoxShadow> get toggleShadow => [
        BoxShadow(
          color: glassShadow,
          offset: const Offset(0, 6),
          blurRadius: 18,
        ),
      ];

  /// Under the tab bar: 0 14 36.
  List<BoxShadow> get tabBarShadow => [
        BoxShadow(
          color: glassShadow,
          offset: const Offset(0, 14),
          blurRadius: 36,
        ),
      ];

  /// Above bottom sheets: 0 -10 40.
  List<BoxShadow> get sheetShadows => [
        BoxShadow(
          color: sheetShadow,
          offset: const Offset(0, -10),
          blurRadius: 40,
        ),
      ];

  @override
  AppTokens copyWith({
    Color? bg,
    Color? card,
    Color? card2,
    Color? line,
    Color? fg,
    Color? muted,
    Color? accent,
    Color? accentInk,
    Color? accentText,
    Color? danger,
    Color? dangerBg,
    Color? sheet,
    Color? scrim,
    Color? glass,
    Color? glassLine,
    Color? glassHi,
    Color? glassLo,
    Color? glassBubble,
    Color? glassBubbleMoving,
    Color? glassShadow,
    Color? sheetShadow,
    Color? orb1,
    Color? orb2,
    Color? heat1,
    Color? heat2,
  }) {
    return AppTokens(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      card2: card2 ?? this.card2,
      line: line ?? this.line,
      fg: fg ?? this.fg,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentText: accentText ?? this.accentText,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      sheet: sheet ?? this.sheet,
      scrim: scrim ?? this.scrim,
      glass: glass ?? this.glass,
      glassLine: glassLine ?? this.glassLine,
      glassHi: glassHi ?? this.glassHi,
      glassLo: glassLo ?? this.glassLo,
      glassBubble: glassBubble ?? this.glassBubble,
      glassBubbleMoving: glassBubbleMoving ?? this.glassBubbleMoving,
      glassShadow: glassShadow ?? this.glassShadow,
      sheetShadow: sheetShadow ?? this.sheetShadow,
      orb1: orb1 ?? this.orb1,
      orb2: orb2 ?? this.orb2,
      heat1: heat1 ?? this.heat1,
      heat2: heat2 ?? this.heat2,
    );
  }

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      bg: mix(bg, other.bg),
      card: mix(card, other.card),
      card2: mix(card2, other.card2),
      line: mix(line, other.line),
      fg: mix(fg, other.fg),
      muted: mix(muted, other.muted),
      accent: mix(accent, other.accent),
      accentInk: mix(accentInk, other.accentInk),
      accentText: mix(accentText, other.accentText),
      danger: mix(danger, other.danger),
      dangerBg: mix(dangerBg, other.dangerBg),
      sheet: mix(sheet, other.sheet),
      scrim: mix(scrim, other.scrim),
      glass: mix(glass, other.glass),
      glassLine: mix(glassLine, other.glassLine),
      glassHi: mix(glassHi, other.glassHi),
      glassLo: mix(glassLo, other.glassLo),
      glassBubble: mix(glassBubble, other.glassBubble),
      glassBubbleMoving: mix(glassBubbleMoving, other.glassBubbleMoving),
      glassShadow: mix(glassShadow, other.glassShadow),
      sheetShadow: mix(sheetShadow, other.sheetShadow),
      orb1: mix(orb1, other.orb1),
      orb2: mix(orb2, other.orb2),
      heat1: mix(heat1, other.heat1),
      heat2: mix(heat2, other.heat2),
    );
  }
}

/// Corner radii from the design README ("Radii").
@immutable
class AppRadii {
  const AppRadii();

  double get tabBar => 33;
  double get toggle => 23;
  double get cardLarge => 24;
  double get card => 20;
  double get button => 18;
  double get setRow => 16;
  double get input => 16;
  double get iconButton => 14;
  double get chip => 7;

  /// Set rows inside a completed exercise or a detail card.
  double get rowSmall => 14;

  /// The square tiles that hold an icon or a set number, largest first.
  double get tile => 12;
  double get tileMedium => 11;
  double get tileSmall => 10;
  double get pill => 6;
  double get trackerSquare => 4;

  /// Top corners of bottom sheets.
  double get sheet => 32;
}

/// Spacing and fixed sizes from the design README ("Spacing").
@immutable
class AppSpacing {
  const AppSpacing();

  /// Horizontal padding of every screen.
  double get screen => 20;

  double get cardPadding => 16;
  double get cardPaddingLarge => 20;

  /// The gap scale: 6, 8, 10, 12, 14, 18, 22.
  double get gap6 => 6;
  double get gap8 => 8;
  double get gap10 => 10;
  double get gap12 => 12;
  double get gap14 => 14;
  double get gap18 => 18;
  double get gap22 => 22;

  double get buttonHeight => 56;

  /// The floating action buttons above the tab bar.
  double get floatingButtonHeight => 58;
  double get iconButton => 44;

  /// Bottom padding that clears the floating actions and the tab bar.
  double get contentBottom => 210;
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
