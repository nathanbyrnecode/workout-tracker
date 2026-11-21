Copy everything below the line into Claude Code, run from the root of the FittenUp Flutter repo, with this folder copied into the repo as `design/handoff-units-cardio/`.

---

I want you to implement two new features in the FittenUp Flutter app from a design handoff. The handoff is in `design/handoff-units-cardio/`:

- `SPEC.md` is the source of truth for layout, sizes, tokens, copy and behaviour.
- `screens/*.png` are the reference frames. Look at each one before building the matching state.

The two features are:

1. **Weight unit toggle (kg/lb)** on the Add/Edit set bottom sheet (SPEC Part A).
2. **Exercise types: Strength and Cardio**, including the new cardio timer card with laps (SPEC Part B).

Please work like this:

1. **Explore first and change nothing yet.** Find:
   - the theme tokens (`lib/theme/app_tokens.dart`, `app_typography.dart`);
   - the set bottom sheet, the new-exercise sheet, the Home "Current" exercise cards and the floating action pair;
   - the done-exercise card, the workout detail and summary screens;
   - the exercise, set and workout models, local storage, sync code and backend schema;
   - the existing golden and unit tests.

   Then write me a short plan: the files you'll touch, the model and migration changes, and anything in the spec that doesn't fit how the app currently works. **Wait for my OK before you change code.**
2. **Make a branch** for the work and don't commit to main.
3. **Build it in two phases**, Part A first and then Part B. Keep each phase in its own commits.
4. **Reuse what's there.** Use existing tokens, text styles, sheets, buttons and row widgets. Map the spec's token names to the ones in `app_tokens.dart` and don't add raw hex colours. If a token is really missing, add it to the tokens file for both themes and tell me.
5. **Get the behaviour details right.** These were deliberate design decisions:
   - **The kg/lb toggle**:
     - It's one control: a tap anywhere on it flips the unit.
     - It's quiet: the selected segment is `card2` with `fg` text, and there's no border or accent colour.
     - Its tap target is at least 44 tall.
   - **Units on sets and volume**:
     - Each set stores its own unit, and switching converts the weight in the sheet (rounded to 0.5).
     - The stepper moves 2.5 kg or 5 lb.
     - Volume always stays in kg.
   - **Exercise type tiles**:
     - The unselected tile is dimmed (45% opacity), and the selected tile's icon chip is `accent`.
     - The sheet's button says "Add exercise".
     - The name field comes before the type.
   - **Timer start**: adding a cardio exercise does **not** start the timer. The primary button reads Start, then Pause or Resume.
   - **Laps**:
     - No lap wording shows until there are 2 or more laps.
     - The button says "Start new lap" and works while running or paused.
     - There's no status text above the cardio exercise name.
   - **Time keeping**: active time excludes pauses. Calculate it from timestamps rather than timer ticks, so it survives backgrounding and app restarts.
   - **Totals**: cardio is left out of sets, reps and volume totals and out of the summary's volume bars.
6. **Data**: add `unit` to sets and `type` plus lap data to exercises. Existing data must default to kg and strength. Write any migration that local storage, sync and the backend need. **Ask me before you run anything against a remote database.**
7. **Tests**:
   - Unit tests for unit conversion and rounding, and for volume when units are mixed.
   - Unit tests for the cardio state machine: start, pause, resume, new lap while running and while paused, ending with zero time, and ending the workout while cardio is running.
   - Golden tests for each state in the frames table at the bottom of `SPEC.md`, in the themes listed.
8. **Don't change anything else.** The strength flow, the strength card (including its "In progress · mm:ss" line) and all other screens stay as they are.

When you're done:

- Run the analyzer and the full test suite.
- Compare your goldens against the PNGs in `screens/`.
- Give me a summary of what changed, any places you departed from the spec and why, and anything you'd like me to check on a device.
