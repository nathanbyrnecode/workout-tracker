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
  so that state only holds rows that have reached the server. The exception
  is workouts: the active workout lives on the device only, and finished and
  logged workouts are kept on the device until they upload (`dev/decisions.md`
  21; see "Workouts on the device" below).
- `supabaseClientProvider` (`lib/data/supabase_client_provider.dart`) is the
  single access point, which is what lets tests swap in a client backed by
  `MockClient`.
- Requests that can be overtaken by sign-out or a newer request carry a
  generation counter (`_recoveryGeneration`, `_requestGeneration`) and drop
  their result if it is stale. Copy this pattern for new async notifier methods.

### Notifiers

| Provider | File | Holds |
|---|---|---|
| `currentWorkoutProvider` | `lib/state/current_workout_state.dart` | The in-progress workout, its exercises and the active exercise, kept on the device; whether the device copy has been read |
| `workoutSyncProvider` | `lib/state/workout_sync_state.dart` | Finished and logged workouts kept on the device until they upload, and their uploads. Also defines `allWorkoutsProvider` and `allManualWorkoutsProvider` |
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

Screens pushed with `Navigator` (Summary) cover the shell, which is how they
hide the tab bar. The detail screens are not pushed; see below. Screens inside the shell should not paint
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
workouts        id uuid PK (made by the app), user_id uuid → auth.users (cascade),
                start_time, end_time, created_at,
                title, location_type (Gym|Home|Park|Other),
                place_name, place_address, place_lat, place_lng  (all nullable)
exercises       id bigint PK, workout_id uuid → workouts (cascade), name,
                start_time, end_time, exercise_number,
                sets, reps, weight          (legacy columns, unused)
exercise_sets   id bigint PK, exercise_id → exercises (cascade),
                set_number, reps integer, weight double precision,
                created_at timestamptz default now() (null on older rows)
manual_workouts id uuid PK (made by the app), user_id uuid → auth.users (cascade),
                date date, title, location_type, place_* columns, created_at.
                Many rows per date. Removed with the user by the cascade.
apple_auth_tokens  user_id PK → auth.users (cascade), encrypted refresh token.
                   service_role only; used by the edge functions.
```

- A workout is owned through `workouts.user_id`. Exercises and sets are
  authorised by joining up to the owning workout in their RLS policies.
- Workouts reach the server only once finished, so every row has an
  `end_time`. Unfinished rows written by older builds were deleted by
  `20261115120000_offline_first_workouts.sql`.
- `title` and `location_type` are null on rows written before the redesign
  (or by an older build). The UI falls back
  to `Workout.displayTitle` ("Workout") and `displayLocationType` (Gym).
- The redesign columns and `manual_workouts` come from
  `20261006232241_add_workout_details_and_manual_workouts.sql`, applied to the
  hosted project on 2026-10-06. The file's version matches the one recorded in
  the project's migration history. Builds from `redesign` select the new
  columns, so any other project they point at needs this migration too.
- `20261115120000_offline_first_workouts.sql` makes the workout and manual
  workout IDs UUIDs (`dev/decisions.md` 22), deletes unfinished workout rows,
  and adds `save_workout(payload jsonb)`. That function inserts one finished
  workout with its exercises and sets in a single transaction, owned by the
  caller (`auth.uid()`), runs as the caller so RLS applies, and returns the
  ID without changing anything if that ID is already saved. Builds from this
  change need the migration on the project they point at.

### When rows are written

| Event | Write |
|---|---|
| Workout started, exercise or set added, edited or removed | the user's `active.json` on the device only |
| Workout ended | finished copy kept on the device, then `save_workout` (workout, exercises and sets in one transaction); the device copy is deleted once that succeeds |
| Workout ended with no exercises | nothing kept; `active.json` deleted |
| Workout discarded (hold to discard) | `active.json` deleted |
| Manual workout logged | kept on the device, then upsert `manual_workouts` (id, user_id, date, title, location columns, created_at), ignoring an ID the server already has |
| Past workout deleted | delete `workouts` row (children cascade); for one still on the device, its file |
| Past workout edited | update `workouts.title`, `location_type`, `place_*`; for one still on the device, its file |
| Manual workout edited or deleted | update or delete the `manual_workouts` row |

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

Place search goes through `PlaceSearchService`
(`lib/data/place_search/place_search_service.dart`), supplied by
`placeSearchServiceProvider`. The app's implementation is
`OsmPlaceSearchService`: Photon for typed search, Overpass for the nearby
list, and Photon's reverse lookup for "Use current location". Everything
specific to those services is in that one file; to change the source, write
another `PlaceSearchService` and return it from the provider.

- The device's position comes through `DeviceLocation`
  (`device_location.dart`, backed by `geolocator`). Permission is asked for
  only when the user taps "Use current location". The nearby list and
  distances appear only once a position is known; they never trigger the
  permission prompt.
- The service's `attribution` ("© OpenStreetMap contributors") is shown beside
  the NEARBY / RESULTS label. The data's licence requires it.
- A service whose `isAvailable` is false hides the Place part of
  `LocationSection`. `UnavailablePlaceSearchService` does that, for tests and
  for any build that should not reach a place service.
- Tests override the provider with `FakePlaceSearchService`, and the OSM
  service itself is tested with recorded responses through `MockClient`.

Sheets that save something (End, Edit and Log workout) take a callback that
does the save and reports success. They close on success and stay open with a
message on failure, so a failed save never loses what was typed. Both use
`WorkoutForm` (`lib/widgets/workout_form_sheet.dart`): name, location section,
confirm and cancel.

`WorkoutDetailScreen` and `ManualWorkoutDetailScreen` take an id and watch
their provider, so an edit shows at once there and on every list behind them.
They are shown inside the shell, in place of the tab's screen, so the tab bar
stays visible as the design shows. `MainBottomNavigation` keeps the tab's
screen in the tree (offstage) while a detail screen is open, so closing it
(Back, the system back gesture, or after a delete) returns to the same scroll
position or selected day. Choosing a tab also closes it.

Other sheets are functions that return what the user chose (`showNewExerciseSheet`,
`showSetSheet`, `showSetMenuSheet`, `showDeleteAccountSheet`). The caller
passes the result to a notifier; sheets do not touch state themselves.

The Tracker is derived entirely by pure functions in
`lib/data/tracker_stats.dart` from past workouts, the live workout and manual
workouts. The Previous tab's grouping is `lib/data/workout_history.dart`.

Derived values (per-day map, heat level, streak, month count, total days,
per-exercise volume) are computed on the client from workouts and manual
entries. Keep that logic in pure functions so it can be unit-tested.

## Workouts on the device

The active workout is kept on the device, not on the server, so a workout can
be started and recorded with no signal (`dev/decisions.md` 21).

**Where.** `LocalWorkoutStore` (`lib/data/local_workout_store.dart`, supplied
by `localWorkoutStoreProvider`) keeps JSON files under the app support
directory, one folder per user:

```
workouts/<userId>/active.json                 the workout in progress
workouts/<userId>/pending/<uuid>.json         finished, not uploaded yet
workouts/<userId>/pending_manual/<uuid>.json  logged, not uploaded yet
```

Files are written to `<name>.tmp` and renamed, and writes to one file are
queued, so a crash or two quick changes never leave a half-written file. A
file that cannot be read is logged and skipped. The JSON format is in
`lib/data/workout_json.dart`; its keys are the server's column names, so a
finished workout's file is exactly the `save_workout` payload. Tests use
`MemoryWorkoutStore` from `test/helpers/fakes.dart`.

**Recording.** `CurrentWorkoutNotifier` changes its state and then writes
`active.json` on every action. Workout IDs are UUIDs made by the app;
exercise and set IDs are counters within the workout. A set's time is the
device clock (`clockProvider`).

**Ending.** The finished copy is written to `pending/` before `active.json`
is removed, so a crash in between leaves both; recovery then keeps the
finished copy. The upload goes to `save_workout` (`lib/data/workout_upload.dart`),
which skips an ID it already has, so retrying is always safe.

**Recovery.** After a session is restored or after sign-in,
`restoreActiveWorkout()` reads the signed-in user's `active.json`. Workout
actions wait until it has been read (`WorkoutRecoveryStatus.pending` /
`loading`), which is a local read and needs no network.

- A workout resumes if it started less than 12 hours ago
  (`workoutRecoveryWindow`), measured from its start. IDs, finished
  exercises, the active exercise, set order and timestamps are preserved.
  Timers are computed from timestamps, so they include time spent with the app
  closed.
- A workout found 12 hours or more after it started is ended instead
  (`finishExpiredWorkout`): it ends at the last thing recorded in it, an
  exercise still in progress is kept (ending at its last set) if it has sets,
  it is titled "Workout" with the latest workout's location type, and it is
  kept for upload. With nothing recorded it is dropped.
- A file written for another user, or one that cannot be read, is ignored.
- Signing out forgets the workout in memory but leaves its file, so the same
  user gets it back on signing in again. A response that arrives after
  sign-out or reset is dropped (generation counter).

**Uploading.** `WorkoutSyncNotifier` (`lib/state/workout_sync_state.dart`)
holds the finished and logged workouts that are on the device but not on the
server, and uploads them.

- `keepWorkout` / `keepManualWorkout` write the file and list the entry.
  Ending a workout and logging one both keep it first, then upload it, so a
  failed upload never loses anything.
- `uploadWorkout(id)` / `uploadManualWorkout(id)` are single-flight per ID,
  have a 30 s timeout (`uploadTimeout`) and refresh an expired access token
  first. On success the file is deleted, the entry moves to the
  server-backed list (`addSavedWorkout`) and history is reloaded in the
  background. On failure everything stays on the device.
- `syncAll()` uploads everything waiting, one at a time. It runs after
  sign-in (once the device copies have been read) and whenever the app comes
  back to the foreground (`AppLifecycleListener` in
  `AuthenticatorController`).
- Edits and deletes from the detail screens go through
  `updateWorkout` / `deleteWorkout` (and the manual equivalents): an entry
  still on the device is changed there; one on the server is changed there
  and needs the network. If an upload of that ID is running, the edit waits
  for it first.
- After ending or logging a workout the user waits at most 5 s
  (`uploadWait`, `waitForUpload`) for the upload. Saved in time: Summary
  opens (for an ended workout) with no message. Failed in time: the entry is
  marked not synced and a SnackBar says it is kept on the phone. Still
  running: the same mark, and a SnackBar reports the result when the server
  answers ("Workout saved" or the not-saved message). These SnackBars go
  through `appMessengerProvider` (`lib/widgets/app_messenger.dart`), which
  uses the `MaterialApp`'s root `ScaffoldMessenger`, so they show after the
  sheet has closed. A workout ended by the 12-hour rule gets its own message
  at sign-in.
- `allWorkoutsProvider` and `allManualWorkoutsProvider` are the lists every
  screen shows: the server's plus the device's, each workout once (the
  server's copy wins), with `synced` false on those still on the device.
- Sign-out forgets the list in memory; the files stay for the same user's
  next sign-in. Deleting the account removes the user's whole folder once
  the server has confirmed the deletion, since those workouts can no longer
  upload.

**Tests.** `test/state/current_workout_state_test.dart` (recording with no
network, ending, upload, recovery, the 12-hour rule, races),
`test/state/workout_sync_state_test.dart` (loading per user, syncing,
failures, single-flight uploads, edits during an upload, merged lists),
`test/data/local_workout_store_test.dart` and
`test/data/workout_json_test.dart`.

Home shows a short loading state while the device copy is read, even though
the prototype does not show it.
