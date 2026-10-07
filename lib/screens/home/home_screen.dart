import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/data/workout_stats.dart';
import 'package:gym_tracker_app/models/workout.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_header.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_screen/current_workout_area.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_screen/previous_workouts_area.dart';
import 'package:gym_tracker_app/screens/home/widgets/home_toggle.dart';
import 'package:gym_tracker_app/screens/home/widgets/workout_block.dart';
import 'package:gym_tracker_app/state/clock_provider.dart';
import 'package:gym_tracker_app/state/current_tab_state.dart';
import 'package:gym_tracker_app/state/current_workout_state.dart';
import 'package:gym_tracker_app/state/user_authentication_state.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';

/// Home: header, workout block, the Current / Previous toggle and the tab it
/// selects, all in one scrolling page. The floating actions belong to the
/// shell; see `MainBottomNavigation`.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenNotifications,
    required this.onOpenWorkout,
    this.hasUnread = false,
  });

  final VoidCallback onOpenNotifications;
  final ValueChanged<Workout> onOpenWorkout;
  final bool hasUnread;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();
  final _topKey = GlobalKey();

  /// True once the history list has scrolled up to the status bar, which is
  /// when the sticky headers and the status bar get their blurred fill.
  bool _headersStuck = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateStuck);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _updateStuck() {
    final top = _topKey.currentContext?.findRenderObject() as RenderBox?;
    if (top == null || !_scroll.hasClients) {
      return;
    }
    final stuck =
        _scroll.offset >= top.size.height + PreviousWorkoutsArea.topPadding;
    if (stuck != _headersStuck) {
      setState(() => _headersStuck = stuck);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tab = ref.watch(currentTabProvider).currentTab;
    final workout = ref.watch(currentWorkoutProvider);
    final user = ref.watch(userAuthenticationProvider);
    final activeExercise = workout.currentExercise;
    final filled = _headersStuck && tab == TabItem.previousWorkouts;
    final statusBar = MediaQuery.paddingOf(context).top;

    // Going back to Current starts from the top again.
    ref.listen(currentTabProvider, (previous, next) {
      if (previous?.currentTab != next.currentTab && _scroll.hasClients) {
        _scroll.jumpTo(0);
      }
    });

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(top: statusBar),
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              // The Current tab shares a sliver with the header. A scroll view
              // paints earlier slivers over later ones, which would put the
              // toggle's shadow on top of the first card.
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      key: _topKey,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HomeHeader(
                          firstName: user.firstName,
                          now: ref.watch(clockProvider)(),
                          onOpenNotifications: widget.onOpenNotifications,
                          hasUnread: widget.hasUnread,
                        ),
                        WorkoutBlock(
                          startTime: workout.isInProgress
                              ? workout.workoutStartDateTime
                              : null,
                          totals: workoutTotals([
                            ...workout.exercises,
                            if (activeExercise != null) activeExercise,
                          ]),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            t.spacing.screen,
                            t.spacing.gap22,
                            t.spacing.screen,
                            0,
                          ),
                          child: HomeToggle(
                            selected: tab,
                            onSelected: ref
                                .read(currentTabProvider.notifier)
                                .setCurrentTab,
                          ),
                        ),
                      ],
                    ),
                    if (tab == TabItem.currentWorkout)
                      const CurrentWorkoutArea(),
                  ],
                ),
              ),
              if (tab == TabItem.previousWorkouts)
                PreviousWorkoutsArea(
                  onOpenWorkout: widget.onOpenWorkout,
                  headersFilled: filled,
                ),
              // Room to scroll the last item clear of the floating actions
              // and the tab bar.
              SliverToBoxAdapter(
                child: SizedBox(height: t.spacing.contentBottom),
              ),
            ],
          ),
        ),
        // The status bar takes the same fill as the headers stuck under it.
        if (statusBar > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: statusBar,
            child: IgnorePointer(child: StickyHeaderFill(filled: filled)),
          ),
      ],
    );
  }
}
