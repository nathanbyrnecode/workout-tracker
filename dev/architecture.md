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

### Navigation

There is no router package. `AuthenticatorController`
(`lib/widgets/authentication_controller.dart`) shows the Welcome screen or the
app shell depending on the session. `MainBottomNavigation`
(`lib/main_bottom_navigation.dart`) holds the selected tab index in `setState`.

## Current schema

Defined in `supabase/migrations/`. Every table has row level security; `anon`
has no access.

```
workouts        id bigint PK, user_id uuid → auth.users (cascade),
                start_time, end_time, created_at
exercises       id bigint PK, workout_id → workouts (cascade), name,
                start_time, end_time, exercise_number,
                sets, reps, weight          (legacy columns, unused)
exercise_sets   id bigint PK, exercise_id → exercises (cascade),
                set_number, reps integer, weight double precision
apple_auth_tokens  user_id PK → auth.users (cascade), encrypted refresh token.
                   service_role only; used by the edge functions.
```

- A workout is owned through `workouts.user_id`. Exercises and sets are
  authorised by joining up to the owning workout in their RLS policies.
- An unfinished workout is a row whose `end_time` is null.

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

| Design model | Today | Change needed |
|---|---|---|
| `Workout.id`, `start` | `workouts.id`, `start_time` | none |
| `Workout.durationSec` | derived from `end_time − start_time` | none; keep deriving it |
| `Workout.title` | missing | add `workouts.title text` |
| `Workout.locationType` (Gym, Home, Park, Other) | missing | add `workouts.location_type` with a check constraint |
| `Workout.place {name, address, lat?, lng?}` | missing | add nullable `place_name`, `place_address`, `place_lat`, `place_lng` |
| `Exercise {name, start, end}` | `exercises` | none |
| `Set {kg, reps}` | `exercise_sets.weight`, `reps` | none in the schema; the Dart `ExerciseSet` holds both as `String` and should become `double` / `int` |
| `Set.savedAt` (drives the rest timer) | missing | add `exercise_sets.created_at timestamptz default now()` |
| `ManualWorkout {id, date, title, locationType, place?}` | missing | new `manual_workouts` table with RLS, many rows per date |
| Notifications | none | not in the schema yet; the design uses placeholder data |
| UI state (screen, tab, selected day, sheet, theme) | `currentTabProvider` only | client-side Riverpod state, nothing in Supabase except possibly theme (kept local) |

Notes for the migration task:

- Existing rows have no title or location. Columns must be nullable or have
  defaults, and the UI needs a fallback (the prototype uses "Workout" and "Gym").
- `title` is required by the UI when ending a workout, but is written at the
  end, so the column cannot be `not null` while a workout is in progress.
- `manual_workouts.date` is a calendar date (`date`, not `timestamptz`): the
  tracker groups by the user's local day.
- New migrations are new timestamped files. Never edit an applied migration.

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
