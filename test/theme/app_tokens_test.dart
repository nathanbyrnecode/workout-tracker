import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/theme/app_theme.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';

void main() {
  // Values from the colour table in design/workout-tracker/README.md. The
  // OKLCH entries are the sRGB values measured in the reference screenshots.
  test('dark tokens match the design', () {
    const t = AppTokens.dark;
    expect(t.bg, const Color(0xFF0A0B0D));
    expect(t.card, const Color(0xFF15171A));
    expect(t.card2, const Color(0xFF1F2125));
    expect(t.line, const Color(0x14FFFFFF));
    expect(t.fg, const Color(0xFFF3F4EF));
    expect(t.muted, const Color(0xFF8B8F88));
    expect(t.accent, const Color(0xFFC0F447));
    expect(t.accentInk, const Color(0xFF0A0B0D));
    expect(t.accentText, t.accent);
    expect(t.danger, const Color(0xFFFF645F));
    expect(t.dangerBg, t.danger.withValues(alpha: 0x21 / 255));
    expect(t.sheet, const Color(0xFF141619));
    expect(t.scrim, const Color(0x8C000000));
    expect(t.glass, const Color(0x12FFFFFF));
    expect(t.glassLine, const Color(0x24FFFFFF));
    expect(t.glassHi, const Color(0x52FFFFFF));
    expect(t.glassBubble, const Color(0x21FFFFFF));
    expect(t.glassBubbleMoving, const Color(0x00FFFFFF));
    expect(t.glassShadow, const Color(0x73000000));
    expect(t.orb1, t.accent.withValues(alpha: 0x24 / 255));
    expect(t.orb2, const Color(0x2400B4BC));
  });

  test('light tokens match the design', () {
    const t = AppTokens.light;
    expect(t.bg, const Color(0xFFF3F4EF));
    expect(t.card, const Color(0xFFFFFFFF));
    expect(t.card2, const Color(0xFFEBEDE6));
    expect(t.line, const Color(0x140A0C08));
    expect(t.fg, const Color(0xFF0F110D));
    expect(t.muted, const Color(0xFF666B63));
    expect(t.accent, const Color(0xFFC0F447));
    expect(t.accentInk, const Color(0xFF0F110D));
    expect(t.accentText, const Color(0xFF457200));
    expect(t.danger, const Color(0xFFD02B31));
    expect(t.dangerBg, t.danger.withValues(alpha: 0x1A / 255));
    expect(t.sheet, const Color(0xFFFFFFFF));
    expect(t.scrim, const Color(0x590A0C08));
    expect(t.glass, const Color(0x80FFFFFF));
    expect(t.glassLine, const Color(0xD9FFFFFF));
    expect(t.glassHi, const Color(0xFFFFFFFF));
    expect(t.glassBubble, const Color(0x120F110D));
    expect(t.glassBubbleMoving, const Color(0x2E0F110D));
    expect(t.glassShadow, const Color(0x24141810));
    expect(t.orb1, t.accent.withValues(alpha: 0x66 / 255));
    expect(t.orb2, const Color(0x4D6BD8DE));
  });

  test('heat levels run from card2 to accent', () {
    for (final t in [AppTokens.dark, AppTokens.light]) {
      expect(t.heat(0), t.card2);
      expect(t.heat(1), t.heat1);
      expect(t.heat(2), t.heat2);
      expect(t.heat(3), t.accent);
      // Out-of-range levels clamp.
      expect(t.heat(-1), t.card2);
      expect(t.heat(9), t.accent);
    }
    expect(AppTokens.dark.heat1, const Color(0xFF536433));
    expect(AppTokens.dark.heat2, const Color(0xFF83A33F));
    expect(AppTokens.light.heat1, const Color(0xFFDBF1B9));
    expect(AppTokens.light.heat2, const Color(0xFFCFF38E));
  });

  test('radii and spacing match the design', () {
    final radii = AppTokens.dark.radii;
    expect(radii.tabBar, 33);
    expect(radii.toggle, 23);
    expect(radii.cardLarge, 24);
    expect(radii.card, 20);
    expect(radii.button, 18);
    expect(radii.setRow, 16);
    expect(radii.input, 16);
    expect(radii.iconButton, 14);
    expect(radii.chip, 7);
    expect(radii.trackerSquare, 4);
    expect(radii.sheet, 32);

    final spacing = AppTokens.dark.spacing;
    expect(spacing.screen, 20);
    expect(spacing.buttonHeight, 56);
    expect(spacing.iconButton, 44);
    expect(spacing.contentBottom, 210);
  });

  test('lerp reaches both ends and copyWith replaces one value', () {
    expect(AppTokens.dark.lerp(AppTokens.light, 0).bg, AppTokens.dark.bg);
    expect(AppTokens.dark.lerp(AppTokens.light, 1).bg, AppTokens.light.bg);
    expect(AppTokens.dark.lerp(null, 0.5), AppTokens.dark);
    final changed = AppTokens.dark.copyWith(fg: AppTokens.light.fg);
    expect(changed.fg, AppTokens.light.fg);
    expect(changed.bg, AppTokens.dark.bg);
  });

  testWidgets('context.tokens follows the theme brightness', (tester) async {
    for (final brightness in Brightness.values) {
      late AppTokens tokens;
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(brightness),
        home: Builder(builder: (context) {
          tokens = context.tokens;
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();
      expect(tokens.bg, AppTokens.of(brightness).bg);
      expect(tokens.accentText, AppTokens.of(brightness).accentText);
    }
  });
}
