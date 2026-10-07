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

/// Glass settings for the sliding bubble on both surfaces while it is pressed
/// or dragged. It keeps the bubble's tint and does not bend what is under it,
/// so icons and labels stay readable as it passes over them.
LiquidGlassSettings appBubbleSettings(AppTokens tokens) => LiquidGlassSettings(
      glassColor: tokens.glassBubble,
      refractiveIndex: 1,
    );
