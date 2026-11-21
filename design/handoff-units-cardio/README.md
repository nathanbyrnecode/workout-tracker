# FittenUp handoff: kg/lb toggle + cardio exercises

What's in this folder:

- **PROMPT.md** is the prompt to paste into Claude Code, run from your Flutter repo.
- **SPEC.md** is the full spec: tokens, measurements, copy, behaviour, the data model, and the frame-to-state table for golden tests.
- **screens/** is where the reference PNGs go. It needs one step from you, below.

## Before running the prompt

The `screens/` folder holds all 11 frames as PNGs at 2× (780×1688). They're named to match the frames table at the bottom of SPEC.md:

| Canvas frame | File |
|---|---|
| A2 · quiet toggle (kg) | A2-quiet-toggle-kg.png |
| A2 · quiet toggle (lb) | A2-quiet-toggle-lb.png |
| A2 · quiet toggle · light | A2-quiet-toggle-light.png |
| 1 · New exercise | 1-new-exercise.png |
| 1b · New exercise, cardio picked | 1b-new-exercise-cardio.png |
| 2 · Added, not started | 2-cardio-added-not-started.png |
| 3 · Running: just the timer | 3-cardio-running-timer-only.png |
| 4 · Running with laps | 4-cardio-running-with-laps.png |
| 5 · Paused | 5-cardio-paused.png |
| 6 · Finished, in the workout | 6-cardio-finished.png |
| 5 · Paused (light) | 5-cardio-paused-light.png |

The floating buttons and tab bar sit over the bottom of the list on purpose; the list scrolls underneath them, as in the app.

1. Copy this whole folder into your repo as `design/handoff-units-cardio/`.
2. Open Claude Code at the repo root and paste the text from PROMPT.md, starting below the line.
