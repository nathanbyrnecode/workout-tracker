import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';

/// The End workout button. A tap ends the workout; pressing and holding for
/// three seconds discards it.
///
/// - Tapping calls [onTap] and needs [enabled] (a workout name).
/// - Holding works even when not [enabled]. After a short delay a dark band
///   fills the button from the left and the label counts down. Letting go
///   early cancels and does nothing; a hold never also counts as a tap.
/// - At three seconds it calls [onDiscard].
class HoldToDiscardButton extends StatefulWidget {
  const HoldToDiscardButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.onDiscard,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onDiscard;

  static const holdDuration = Duration(seconds: 3);

  /// How long a press lasts before it counts as a hold rather than a tap.
  static const holdDelay = Duration(milliseconds: 250);

  static const height = 62.0;

  @override
  State<HoldToDiscardButton> createState() => _HoldToDiscardButtonState();
}

class _HoldToDiscardButtonState extends State<HoldToDiscardButton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: HoldToDiscardButton.holdDuration,
  )
    ..addListener(_onTick)
    ..addStatusListener(_onStatus);

  static final _holdStart = HoldToDiscardButton.holdDelay.inMilliseconds /
      HoldToDiscardButton.holdDuration.inMilliseconds;

  Offset? _pressedAt;
  bool _holding = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTick() {
    if (!_holding && _controller.value >= _holdStart) {
      _holding = true;
      HapticFeedback.mediumImpact();
    }
    setState(() {});
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      HapticFeedback.heavyImpact();
      _reset();
      widget.onDiscard();
    }
  }

  void _reset() {
    _pressedAt = null;
    _holding = false;
    _controller
      ..stop()
      ..value = 0;
  }

  void _press(PointerDownEvent event) {
    _pressedAt = event.position;
    _controller.forward(from: 0);
  }

  void _release(PointerEvent event) {
    if (_pressedAt == null) {
      return;
    }
    final wasHold = _holding;
    _reset();
    setState(() {});
    // A hold let go early does nothing at all.
    if (!wasHold && event is PointerUpEvent && widget.enabled) {
      widget.onTap();
    }
  }

  void _move(PointerMoveEvent event) {
    final start = _pressedAt;
    // A finger that wanders off is scrolling the sheet, not pressing.
    if (start != null && (event.position - start).distance > 24) {
      _reset();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final progress = _holding ? _controller.value : 0.0;
    final secondsLeft =
        (HoldToDiscardButton.holdDuration.inSeconds * (1 - progress))
            .ceil()
            .clamp(1, HoldToDiscardButton.holdDuration.inSeconds);

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      hint: 'Hold for three seconds to discard the workout',
      onTap: widget.enabled ? widget.onTap : null,
      onLongPress: widget.onDiscard,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: _press,
        onPointerUp: _release,
        onPointerCancel: _release,
        onPointerMove: _move,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.enabled || _holding ? 1 : 0.4,
          child: Container(
            height: HoldToDiscardButton.height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: t.danger,
              borderRadius: BorderRadius.circular(t.radii.button),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: ColoredBox(color: t.holdBand),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 2,
                  children: [
                    Text(
                      _holding
                          ? 'Keep holding to discard · ${secondsLeft}s'
                          : widget.label,
                      style: AppTypography.button.copyWith(color: t.onDanger),
                    ),
                    if (!_holding)
                      Text(
                        'Hold to discard workout',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w500,
                          color: t.onDanger.withValues(alpha: 0.82),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
