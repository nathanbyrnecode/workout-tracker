# Architecture

Internal reference for contributors and coding agents. Not published (the
public site lives in `docs/`).

## Data flow

```
Widget (ConsumerWidget)
   │  ref.watch(xProvider)            reads record-typed state
   │  ref.read(xProvider.notifier)    calls a method
   ▼
Notifier (@Riverpod class in lib/state/)
   │  ref.read(supabaseClientProvider)
   ▼
Supabase (Postgres + RLS, auth, edge functions)
```

- Widgets never talk to Supabase. They call notifier methods.
- Notifiers write to Supabase first and update local state from the response,
  so local state only holds rows that have reached the server.
- `supabaseClientProvider` (`lib/data/supabase_client_provider.dart`) is the
  single access point, which is what lets tests swap in a client backed by
  `MockClient`.
- Requests that can be overtaken by sign-out or a newer request carry a
  generation counter (`_recoveryGeneration`, `_requestGeneration`) and drop
  their result if it is stale. Copy this pattern for new async notifier methods.

### Notifiers

| Provider | File | Holds |
|---|---|---|
| `currentWorkoutProvider` | `lib/state/current_workout_state.dart` | The in-progress workout, its exercises, the active exercise, recovery status |
| `pastWorkoutsProvider` | `lib/state/past_workouts_state.dart` | Finished workouts with exercises and sets. Also defines the `Workout` class and `mapWorkoutRows` |
| `userAuthenticationProvider` | `lib/state/user_authentication_state.dart` | Session, Google and Apple sign-in, account deletion |
| `currentTabProvider` | `lib/state/current_tab_state.dart` | Home's Current/Previous tab |
| `manualWorkoutsProvider` | `lib/state/manual_workouts_state.dart` | Workouts logged by hand. Loaded at sign-in; adding and editing come with the Log workout and detail tasks |
| `notificationsProvider` | `lib/state/notifications_state.dart` | Notifications and their read state. Always empty until a real source exists (`dev/decisions.md` 17) |
| `themeModeProvider` | `lib/state/theme_mode_state.dart` | Light, dark or system; saved on the device |
| `clockProvider` | `lib/state/clock_provider.dart` | The current time. Timers and the greeting read it so tests can pin it |

### Navigation

There is no router package. `AuthenticatorController`
(`lib/widgets/authentication_controller.dart`) shows the Welcome screen or the
app shell depending on the session. `MainBottomNavigation`
(`lib/main_bottom_navigation.dart`) holds the selected `AppTab` in `setState`
and hands the screen for it to `AppShell`.

`AppShell` (`lib/widgets/app_shell.dart`) is the frame around the four main
screens. From back to front it stacks:

1. `AppBackground`: the background colour and the two blurred glows.
2. The current screen.
3. An optional row of floating actions, 106 above the bottom edge. Screens do
   not position these themselves; `MainBottomNavigation` passes them in.
4. `AppTabBar`, 26 above the bottom edge.

Screens pushed with `Navigator` (Summary, the detail screens) cover the shell,
which is how they hide the tab bar. Screens inside the shell should not paint
their own background, or they hide the glows.

Home's floating actions (`WorkoutActionArea`) are passed into that slot by
`MainBottomNavigation`; `HomeScreen` does not draw them. They show on both the
Current and the Previous tab.

`HomeScreen` is one `CustomScrollView`: the header, workout block and toggle
scroll away with the content. That is what lets the Previous tab's year and
month headers stick to the top of the screen (`SliverMainAxisGroup` with
pinned headers). Once they are stuck, they and the status bar get a blurred
fill (`StickyHeaderFill`). So `CurrentWorkoutArea` is a plain column and
`PreviousWorkoutsArea` is a sliver; neither scrolls by itself.

Screens that are not built yet open `WorkoutDetailScreen`, a placeholder that
the detail task replaces.

Bottom sheets open with `showAppSheet` (`lib/widgets/app_bottom_sheet.dart`),
which supplies the surface, grab handle, scrim and scrolling.

### Liquid glass

`AppTabBar` is `GlassTabBar.bottom` and `HomeToggle` is `GlassSegmentedControl`,
both from `liquid_glass_widgets`, sized and coloured from tokens and sharing
`appGlassSettings` (`lib/widgets/app_glass.dart`). Their drop shadows are drawn
with `OuterShadow` so they do not show through the glass. The package is initialised in `lib/main.dart`
(`LiquidGlassWidgets.initialize()` and `.wrap(...)`). It works without that
setup in tests, where it detects the test environment and draws a simplified
surface with no shaders, so goldens show the layout and colours but not the
real refraction. Check the real glass on a device.

`GlassScaffold` is not used: the bar has a fixed size and position and shares
the bottom of the screen with the floating actions, which a plain `Stack`
handles directly.

## Current schema

Defined in `supabase/migrations/`. Every table has row level security; `anon`
has no access.

```
workouts        id bigint PK, user_id uuid → auth.users (cascade),
                start_time, end_time, created_at,
                title, location_type (Gym|Home|Park|Other),
                place_name, place_address, place_lat, place_lng  (all nullable)
exercises       id bigint PK, workout_id → workouts (cascade), name,
                start_time, end_time, exercise_number,
                sets, reps, weight          (legacy columns, unused)
exercise_sets   id bigint PK, exercise_id → exercises (cascade),
                set_number, reps integer, weight double precision,
                created_at timestamptz default now() (null on older rows)
manual_workouts id bigint PK, user_id uuid → auth.users (cascade),
                date date, title, location_type, place_* columns, created_at.
                Many rows per date. Removed with the user by the cascade.
apple_auth_tokens  user_id PK → auth.users (cascade), encrypted refresh token.
                   service_role only; used by the edge functions.
```

- A workout is owned through `workouts.user_id`. Exercises and sets are
  authorised by joining up to the owning workout in their RLS policies.
- An unfinished workout is a row whose `end_time` is null.
- `title` and `location_type` are null while a workout is in progress and on
  rows written before the redesign (or by an older build). The UI falls back
  to `Workout.displayTitle` ("Workout") and `displayLocationType` (Gym).
- The redesign columns and `manual_workouts` come from
  `20261006232241_add_workout_details_and_manual_workouts.sql`, applied to the
  hosted project on 2026-10-06. The file's version matches the one recorded in
  the project's migration history. Builds from `redesign` select the new
  columns, so any other project they point at needs this migration too.

### When rows are written

| Event | Write |
|---|---|
| Workout started | insert `workouts` (user_id, start_time, created_at) |
| Workout ended | update `workouts.end_time` |
| Workout ended with no exercises | delete the `workouts` row |
| Exercise started | insert `exercises` (workout_id, name, start_time, exercise_number) |
| Exercise ended | update `exercises.end_time` |
| Exercise ended with no sets | delete the `exercises` row |
| Set added | insert `exercise_sets` (exercise_id, set_number, reps, weight) |
| Set removed | delete `exercise_sets` row, then renumber the remaining `set_number`s |
| Past workout deleted | delete `workouts` row (children cascade) |

### Edge functions

`supabase/functions/store-apple-token` and `delete-account` handle Apple token
storage and full account deletion. See
`supabase/functions/delete-account/README.md`.

## How the redesign's model maps onto the schema

The target model is in the design README under "State / Data model".

| Design model | Where it lives |
|---|---|
| `Workout.id`, `start` | `workouts.id`, `start_time` |
| `Workout.durationSec` | derived from `end_time − start_time` |
| `Workout.title`, `locationType`, `place` | `workouts.title`, `location_type`, `place_*`; `Workout` in `lib/models/workout.dart` |
| `Exercise {name, start, end}` | `exercises` |
| `Set {kg, reps, savedAt}` | `exercise_sets.weight`, `reps`, `created_at`; `ExerciseSet` holds `double`, `int`, `DateTime?` |
| `ManualWorkout` | `manual_workouts`; `lib/models/manual_workout.dart`, mapped by `lib/data/manual_workout_mapper.dart` |
| Notifications | not in the schema (`dev/decisions.md` 17) |
| UI state (screen, tab, selected day, sheet, theme) | client-side Riverpod state, nothing in Supabase |

`manual_workouts.date` is a calendar date, not an instant: the tracker groups
by the user's local day, so it is parsed with `parseCalendarDate` and never
shifted by time zone. The shared `location_type` and `place_*` columns are read
and written through `lib/data/location_mapper.dart`.

Sheets are functions that return what the user chose (`showNewExerciseSheet`,
`showSetSheet`, `showSetMenuSheet`, `showDeleteAccountSheet`). The caller
passes the result to a notifier; sheets do not touch state themselves.

The Tracker is derived entirely by pure functions in
`lib/data/tracker_stats.dart` from past workouts, the live workout and manual
workouts. The Previous tab's grouping is `lib/data/workout_history.dart`.

Derived values (per-day map, heat level, streak, month count, total days,
per-exercise volume) are computed on the client from workouts and manual
entries. Keep that logic in pure functions so it can be unit-tested.

## Workout recovery

Workout, exercise and set changes are written to Supabase as they happen, so
an unfinished workout can be restored after the app is killed.

**When it runs.** After a session is restored or after Google/Apple sign-in,
`CurrentWorkoutNotifier` loads the signed-in user's single latest workout,
ordered by start time and then ID.

**What resumes.** That workout resumes only if its `end_time` is null and it
started less than 12 hours ago (`workoutRecoveryWindow`). If the latest workout
is finished, expired, missing or dated in the future, nothing resumes; the app
does not go looking for an older unfinished one. The limit is measured from the
workout's start, not from when the app closed.

**What is preserved.** IDs, completed exercises, the active exercise, saved
sets, and the original start and end timestamps. Sets are ordered by set number
and then ID. Timers are computed from timestamps, so they include time spent
with the app closed and are correct as soon as the app is foregrounded. There
is no background timer service.

**Guarantees.**

- Workout actions are unavailable while recovery is in progress
  (`WorkoutRecoveryStatus.pending` / `loading`).
- A failed query times out after 15 seconds and shows a retry action
  (`WorkoutRecoveryStatus.failed`).
- Recovery never creates, deletes or finishes workout rows.
- Unfinished workouts, including expired ones, are excluded from history.
- A response that arrives after sign-out or reset cannot repopulate the next
  user's state (generation counter).
- Invalid child data produces a recoverable error instead of a partial restore.

**Limits.** Recovery is Supabase-only: it needs connectivity and restores only
what reached the server. Unsubmitted text fields and offline edits are not
recovered.

**Tests.** `test/state/current_workout_recovery_test.dart`,
`test/data/active_workout_mapper_test.dart` and
`test/widgets/current_workout_area_test.dart` cover the age boundary, time
zones, empty workouts and exercises, mapping, set order, the scoped latest-only
query, failure and retry, account and reset races, duplicate start prevention,
history filtering and the loading/retry UI.

**The redesign must keep this behaviour.** The redesigned Home screen still
needs the loading and retry states, even though the prototype does not show them.
