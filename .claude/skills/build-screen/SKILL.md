---
name: build-screen
description: Build one redesign screen or bottom sheet in Flutter from the design package, with widget and golden tests in both themes. Use when asked to build, rebuild or restyle a specific screen such as home, tracker, detail, summary, notifications, profile, welcome, or any sheet.
argument-hint: <screen name, e.g. tracker or sheet-end-workout>
---

# Build screen: $ARGUMENTS

## 1. Read the design, in this order

1. `design/workout-tracker/INDEX.md`: find the row for this screen. It gives
   the README section, the prototype line ranges and the screenshot names.
2. The matching section of `design/workout-tracker/README.md`, plus "Design
   Tokens", "Global chrome" and "Interactions & Behaviour". This is the spec.
3. The screenshots: `design/workout-tracker/screens/<name>-dark.png` and
   `<name>-light.png`. This is the visual truth. Look at both.
4. Only the prototype line ranges INDEX.md lists, read with `offset`/`limit`.
   Use them for exact measurements. Never read the whole HTML file.

Where the prototype and the README disagree, the README wins.

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
- Keep existing behaviour the prototype does not show, such as the workout
  recovery loading and retry states (`dev/architecture.md`).
- Demo data in the prototype (history, places, notifications, the name
  "Nathan") is placeholder. Wire to real state.

## 4. Test

- Widget tests for behaviour, using
  `ProviderScope(overrides: [...overrideWith(...)])` as in
  `test/widgets/current_workout_area_test.dart`.
- Golden tests through `test/helpers/golden.dart`, one per meaningful state
  (the states with their own screenshot in INDEX.md), each in dark and light,
  on the fixed 390×844 surface. Tag them `golden`.
- Pure logic (streaks, heat levels, top set, averages) gets unit tests.

## 5. Verify

```
dart format .
flutter analyze
flutter test
tool/check_colours.sh
```

On Linux, generate goldens with `flutter test --tags golden --update-goldens`
and open the PNGs next to the design screenshots yourself before going further.

## 6. Review

Run the `design-reviewer` agent with the screen name. Fix what it reports and
run it again. Anything you decide not to fix goes in the PR under "Known gaps"
with the reason.
