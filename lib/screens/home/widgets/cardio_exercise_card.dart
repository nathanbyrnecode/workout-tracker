import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/models/cardio_timer.dart';
import 'package:gym_tracker_app/models/exercise.dart';
import 'package:gym_tracker_app/screens/home/widgets/set_number_tile.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/number_format.dart';
import 'package:gym_tracker_app/widgets/dashed_border.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The cardio exercise in progress: its active time and, from two laps up,
/// the laps. Shown instead of the strength card.
///
/// Every value is worked out from the clock when it is drawn. The one-second
/// timer only asks for a redraw, so it stays right after the app has been in
/// the background.
class CardioExerciseCard extends ConsumerStatefulWidget {
  const CardioExerciseCard({
    super.key,
    required this.exercise,
    required this.onNewLap,
  });

  final Exercise exercise;
  final VoidCallback onNewLap;

  @override
  ConsumerState<CardioExerciseCard> createState() => _CardioExerciseCardState();
}

class _CardioExerciseCardState extends ConsumerState<CardioExerciseCard>
    with WidgetsBindingObserver {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant CardioExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  /// Before the start nothing on the card changes, so nothing needs to tick.
  void _syncTicker() {
    final started = widget.exercise.cardio.status != CardioStatus.notStarted;
    if (started && _ticker == null) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    } else if (!started) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final timer = widget.exercise.cardio;
    final now = ref.read(clockProvider)();
    final status = timer.status;
    final running = status == CardioStatus.running;
    final paused = status == CardioStatus.paused;
    final laps = timer.lapSeconds(now);
    final showLaps = laps.length >= 2;

    // With one lap no lap wording appears, so a plain run never mentions laps.
    final footerLeft = status == CardioStatus.notStarted
        ? 'Tap Start when you begin'
        : showLaps
            ? '${laps.length} laps'
            : '';
    final footerRight =
        paused ? 'Paused for ${formatActiveTime(timer.pausedFor(now))}' : '';

    return Container(
      padding: EdgeInsets.all(t.spacing.cardPaddingLarge),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radii.cardLarge),
        border: Border.all(color: running ? t.accentBorder : t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: t.spacing.gap10,
            children: [
              Expanded(
                child: Text(
                  widget.exercise.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.exerciseName,
                ),
              ),
              const _CardioPill(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: t.spacing.gap6,
            children: [
              Text(
                'ACTIVE TIME',
                style: AppTypography.label.copyWith(color: t.muted),
              ),
              Text(
                formatActiveTime(timer.activeTime(now)),
                maxLines: 1,
                softWrap: false,
                style: AppTypography.timer.copyWith(
                  fontSize: 48,
                  letterSpacing: -2,
                  color: running ? t.fg : t.muted,
                ),
              ),
            ],
          ),
          if (showLaps)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: t.spacing.gap8,
              children: [
                for (final (index, seconds) in laps.indexed)
                  _LapRow(
                    number: index + 1,
                    time: Duration(seconds: seconds),
                    live: running && index == laps.length - 1,
                  ),
              ],
            ),
          if (status != CardioStatus.notStarted)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: t.spacing.gap8,
              children: [
                _NewLapButton(onPressed: widget.onNewLap),
                if (paused && showLaps)
                  Text(
                    'Resume carries on with lap ${laps.length}',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      color: t.muted,
                    ),
                  ),
              ],
            ),
          if (footerLeft.isNotEmpty || footerRight.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  footerLeft,
                  style: AppTypography.bodySmall.copyWith(color: t.muted),
                ),
                Text(
                  footerRight,
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CardioPill extends StatelessWidget {
  const _CardioPill();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: t.card2,
        borderRadius: BorderRadius.circular(t.radii.tag),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: t.spacing.gap6,
        children: [
          Icon(LucideIcons.heartPulse, size: 13, color: t.muted),
          Text('CARDIO', style: AppTypography.pill.copyWith(color: t.muted)),
        ],
      ),
    );
  }
}

class _LapRow extends StatelessWidget {
  const _LapRow({
    required this.number,
    required this.time,
    required this.live,
  });

  final int number;
  final Duration time;

  /// The lap being timed right now.
  final bool live;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 10, right: 16),
      decoration: BoxDecoration(
        color: t.card2,
        borderRadius: BorderRadius.circular(t.radii.setRow),
        // Always 1 wide, so the row's content does not shift when it goes live.
        border: Border.all(
          color: live ? t.accentBorder : t.accentBorder.withValues(alpha: 0),
        ),
      ),
      child: Row(
        spacing: t.spacing.gap12,
        children: [
          SetNumberTile(
            number: number,
            size: 34,
            radius: t.radii.tileSmall,
            fontSize: 14,
          ),
          Expanded(
            child: Text(
              'Lap $number',
              style: AppTypography.body.copyWith(color: t.muted),
            ),
          ),
          if (live)
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: t.accent,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            formatActiveTime(time),
            style: AppTypography.stat.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _NewLapButton extends StatelessWidget {
  const _NewLapButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = t.radii.setRow;
    return Semantics(
      button: true,
      label: 'Start new lap',
      excludeSemantics: true,
      child: DashedBorder(
        color: t.line,
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: onPressed,
            child: SizedBox(
              height: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: t.spacing.gap8,
                children: [
                  Icon(LucideIcons.flag, size: 17, color: t.fg),
                  Text('Start new lap', style: AppTypography.buttonSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
