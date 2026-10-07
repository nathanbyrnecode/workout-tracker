import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Glass settings shared by the two glass surfaces, the tab bar and the
/// Current/Previous toggle: the design's blur 24 and saturation 190% over the
/// `glass` token.
LiquidGlassSettings appGlassSettings(AppTokens tokens) => LiquidGlassSettings(
      glassColor: tokens.glass,
      blur: 24,
      saturation: 1.9,
    );

/// Glass settings for the tab bar's bubble while it is pressed or dragged:
/// the package's lens with the theme's moving tint.
LiquidGlassSettings appTabBubbleSettings(AppTokens tokens) =>
    LiquidGlassSettings(glassColor: tokens.glassBubbleMoving);

/// The same for the toggle's bubble, which keeps the track's glass where the
/// theme has no moving tint.
LiquidGlassSettings appToggleBubbleSettings(AppTokens tokens) {
  final tint = tokens.glassBubbleMoving;
  return appGlassSettings(tokens).copyWith(
    glassColor: tint.a == 0 ? tokens.glass : tint,
  );
}
