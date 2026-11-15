# FittenUp: agent guide

FittenUp is a workout tracker for iOS and Android (Dart package name
`gym_tracker_app`). The app was built from the design handoff in
`design/workout-tracker/` and has changed a lot since; the shipped app and its
goldens are now the reference (see "Design rules"). This file is the source of
truth for every coding agent; `CLAUDE.md` imports it.

## Stack

- **Flutter**, version pinned in `pubspec.yaml` (`environment.flutter`). Mobile
  only: iOS and Android. No web or desktop targets.
- **Riverpod 3 with `riverpod_generator`.** State is `@Riverpod` notifier
  classes with record-typed state, e.g. `CurrentWorkoutStateData` in
  `lib/state/current_workout_state.dart`. Generated `*.g.dart` files are
  committed.
- **Supabase** is the backend, reached only through `supabaseClientProvider`
  (`lib/data/supabase_client_provider.dart`). Never call
  `Supabase.instance.client` directly; tests override the provider.
- **No router.** Tabs are switched with `setState` in
  `lib/main_bottom_navigation.dart`, which also shows the workout detail
  screens inside the shell. Only the Summary screen is pushed with `Navigator`.

More detail: `dev/architecture.md`. Settled questions: `dev/decisions.md`.
Read `dev/decisions.md` before proposing a new package or pattern.

## Layout

```
lib/models/                    plain data classes
lib/data/                      Supabase client provider, mappers
lib/state/                     Riverpod notifiers (+ committed *.g.dart)
lib/screens/<feature>/         one folder per screen
lib/screens/<feature>/widgets/ widgets used by that screen only
lib/widgets/                   shared widgets
lib/theme/                     AppTokens, AppTypography, ThemeData
test/                          mirrors lib/; test/helpers/ for shared harnesses
supabase/migrations/           timestamped SQL files; every table has RLS
supabase/functions/            Deno edge functions
design/workout-tracker/        original handoff (historical; see "Design rules")
dev/                           internal docs for agents and contributors
```

The public website, including the privacy policy at
<https://fittenup.app/privacy>, lives in the separate `fittenup-site` repo. The
app only links to it (`lib/util/privacy_policy.dart`).

## Commands

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after changing any @Riverpod class
dart format .
flutter analyze
flutter test
flutter test --tags golden                     # Linux only
flutter test --tags golden --update-goldens    # Linux only
tool/check_colours.sh                          # no hard-coded colours outside lib/theme/
```

Golden files are generated and compared on Linux only (CI and cloud sessions).
On macOS the golden tests skip themselves. Every CI run uploads a
`linux-goldens` artifact rendered from the PR's code: to add or update goldens
from a Mac, push, download it with `gh run download <run-id> -n linux-goldens -D test`,
look at the images, and commit them. Never commit goldens rendered on macOS.

## Test patterns to copy

- **Widget tests:** wrap in `ProviderScope(overrides: [someProvider.overrideWith(() => FakeNotifier())])`.
  See `test/widgets/current_workout_area_test.dart`.
- **Supabase:** build a real `SupabaseClient` whose `httpClient` is a
  `MockClient` from `package:http/testing.dart`, and override
  `supabaseClientProvider` with it. See
  `test/state/current_workout_recovery_test.dart`.
- **Goldens:** use the harness in `test/helpers/golden.dart` (both themes, a
  fixed 390×844 surface, bundled fonts loaded). Tag golden tests `golden`.

## Design rules

- **The visual truth is the golden images on `main`** (`test/**/goldens/`).
  They show every screen and sheet as it ships, in both themes. A change should
  alter only the goldens its task asks it to change.
- **The design for new work is in the bead.** Ideas are explored in a
  Claude Design canvas outside the repo; when one is approved, its screenshots
  and a description go on the bead. Build from that, not from the canvas.
- **`design/workout-tracker/` is historical.** It is the original handoff and
  is out of date: many screens have changed since. Read it for background
  (for example, the intent behind a screen), never as the target. Where it
  disagrees with the goldens or the code on `main`, they win. Do not "fix" a
  screen to match its old screenshot.
- Colours, radii and spacing come only from `AppTokens` (`context.tokens`).
  No `Color(0x…)` and no `Colors.*` outside `lib/theme/`.
- Liquid glass goes on exactly two things: the bottom tab bar and the
  Current/Previous toggle. Nowhere else. It comes from `liquid_glass_widgets`
  on both iOS and Android (`dev/decisions.md` 15). The package also offers
  glass cards, sheets, buttons and app bars; do not use them.
- Text uses Geist and Geist Mono through `AppTypography`. The fonts are bundled
  assets; do not fetch fonts at runtime.
- Icons are Lucide.
- Every screen must work in both the dark and the light theme.

## Workflow

Work is tracked with [beads](https://github.com/steveyegge/beads) (`bd`).

1. `bd ready` lists tasks with no open blockers. Pick one and claim it:
   `bd update <id> --claim`.
2. Branch from `main`. The redesign has landed there, so the `redesign`
   branch is no longer used.
3. One bead per pull request. Open the PR against `main`.
4. Replace widgets in place. Never create `_v2` copies or parallel
   implementations.
5. Don't add ad-hoc markdown files at the repo root. Durable notes go in
   `dev/`; task notes go on the bead.
6. If a PR adds or changes anything under `supabase/migrations/`, say so in the
   PR description. Never edit a migration that has already been applied; add a
   new one.
7. If you find work that is out of scope, file a bead for it
   (`bd create ... --deps discovered-from:<id>`) instead of doing it.
8. Issues travel through git as `.beads/issues.jsonl` (the bd database itself
   is not committed). After pulling, run `bd import .beads/issues.jsonl`.
   Before committing, run `bd export -o .beads/issues.jsonl` and commit the
   file with your change. Never run `bd dolt push`.

## Definition of done

- `dart format .` leaves no changes.
- `flutter analyze` reports no issues.
- `flutter test` passes.
- `tool/check_colours.sh` passes.
- Goldens exist, in both themes, for every screen the change touched, and are
  added or updated on Linux.
- The `design-reviewer` agent has compared those goldens with the goldens on
  `main` and the design in the bead, and its findings are fixed or listed in
  the PR.
- The bead is closed with a note: `bd close <id> --reason "<what changed>"`.

## Never

- Commit secrets, `.p8` keys or env files.
- Edit signing configuration under `ios/` or `android/`, or `codemagic.yaml`,
  unless the task explicitly asks for it.
- Run `supabase db push` or apply migrations to the hosted project without
  being asked.
- Commit, push or open a PR on `main` directly.
