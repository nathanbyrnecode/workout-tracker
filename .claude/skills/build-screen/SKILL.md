---
name: build-screen
description: Build, rebuild or restyle one screen or bottom sheet in Flutter from the design in its bead, with widget and golden tests in both themes. Use when asked to build, rebuild or restyle a specific screen such as home, tracker, detail, summary, notifications, profile, welcome, or any sheet.
argument-hint: <screen name, e.g. tracker or sheet-end-workout> [bead id]
---

# Build screen: $ARGUMENTS

## 1. Read the design, in this order

1. The bead (`bd show <id>`). Its description, notes and any design
   screenshots it links or names are the spec for what should change. If the
   bead has no design and doesn't say clearly what the screen should look like,
   stop and ask rather than inventing one.
2. The current goldens for this screen under `test/**/goldens/`, dark and
   light, for every state. They show the screen as it ships today: everything
   the bead does not ask to change should still look like this afterwards.
3. The current code for the screen and its widgets. Copy existing
   measurements, tokens and patterns from it and from neighbouring screens.

`design/workout-tracker/` is the original handoff and is out of date. Don't
match its screenshots. Read its README section only for background when the
bead and the code say nothing about a screen's intent. Where it disagrees with
the bead, the goldens or the code on `main`, they win.

## 2. Plan before writing

List the widgets you will create or replace and where each lives:

- screen: `lib/screens/<feature>/<feature>_screen.dart`
- widgets used only by this screen: `lib/screens/<feature>/widgets/`
- widgets shared with other screens: `lib/widgets/`

Check `lib/widgets/` first for something that already exists. Replace existing
widgets in place; never add a `_v2` copy.

## 3. Build

- Colours, radii and spacing only from `context.tokens` (`AppTokens`). If a
  value you need is missing, add it to `lib/theme/` rather than hard-coding it.
- Text styles only from `AppTypography` (Geist and Geist Mono).
- Lucide icons.
- Liquid glass only on the tab bar and the Current/Previous toggle.
- State through Riverpod notifiers. Widgets never call Supabase.
- Keep existing behaviour the bead does not mention, such as the workout
  recovery loading and retry states and the not-synced states
  (`dev/architecture.md`).
- Data in design screenshots (history, places, notifications, names) is
  placeholder. Wire to real state.

## 4. Test

- Widget tests for behaviour, using
  `ProviderScope(overrides: [...overrideWith(...)])` as in
  `test/widgets/current_workout_area_test.dart`.
- Golden tests through `test/helpers/golden.dart`, one per meaningful state,
  each in dark and light, on the fixed 390×844 surface. Tag them `golden`.
  Keep the existing goldens for this screen and update them; add new ones for
  any state the bead introduces.
- Pure logic (streaks, heat levels, top set, averages) gets unit tests.

## 5. Verify

```
dart format .
flutter analyze
flutter test
tool/check_colours.sh
```

On Linux, generate goldens with `flutter test --tags golden --update-goldens`
(on a Mac, take them from the CI run's `linux-goldens` artifact; see
`AGENTS.md`). Open each new PNG next to the same golden on `main` and the
bead's design yourself before going further: every difference should be one
the bead asked for.

## 6. Review

Run the `design-reviewer` agent with the bead id and the screen name. Fix what
it reports and run it again. Anything you decide not to fix goes in the PR under "Known gaps"
with the reason.
