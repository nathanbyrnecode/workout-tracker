# FittenUp design handoff: kg/lb toggle + cardio exercises

Source: the "FittenUp current app" design canvas (rows "Exploration · kg / lb on the add-set sheet" → A2 frames, and "Exercise type · strength & cardio").
Everything not mentioned here stays as it is in the app today.

Sizes are logical pixels (Flutter dp). Fonts: Geist (UI) and Geist Mono (numbers, small caps labels), as already used in the app.

---

## 0. Design tokens used

These names match the design canvas. Map each one to the existing token in `lib/theme/app_tokens.dart` (the canvas was built from that file, so they should already exist). Don't add new hex values unless a token is really missing.

| Token | Dark | Light | Used for |
|---|---|---|---|
| `bg` | #0A0B0D | #F3F4EF | screen background |
| `card` | #15171A | #FFFFFF | cards, toggle track |
| `card2` | #1F2125 | #EBEDE6 | inner rows, inputs, tiles |
| `line` | white 8% | rgba(10,12,8,0.08) | borders, dashed outlines |
| `fg` | #F3F4EF | #0F110D | primary text |
| `muted` | #8B8F88 | #666B63 | secondary text, labels |
| `accent` | #C0F447 | #C0F447 | primary buttons, selected icon chip, live dot |
| `accentInk` | #0A0B0D | #0F110D | text/icons on accent |
| `accentBorder` | rgba(192,244,71,0.45) | same | running cardio card + running lap row outline |
| `danger` | #FF645F | #D02B31 | End exercise text |
| `sheet` | #141619 | #FFFFFF | bottom sheet background |

Small-caps label style (used for "WEIGHT", "REPS", "NAME", "TYPE", "ACTIVE TIME"): Geist Mono 11, letter-spacing 1.54, colour `muted`.

---

## Part A: Weight unit toggle on the Add/Edit set sheet (frames A2 · kg, A2 · lb, A2 · light)

### Layout

The set sheet keeps its current structure: title "Set N", a two-column grid (Weight card | Reps card) with a gap of 10, then the CTA. Only the top of the two cards changes.

**Weight card** (`card2`, radius 20, padding 14, column):
1. **Label row**: min height 32, row, space-between, vertically centred, gap 6.
   - Left: "WEIGHT" (small-caps label). Note that the unit is **no longer** in the label (it used to read "WEIGHT · KG").
   - Right: the **unit toggle** (below).
2. **Number**: margin 12 above and 14 below, size 40, weight 500, letter-spacing −1.6, line-height 1.2, no wrapping.
3. **− / + steppers**: unchanged.

**Reps card**: its label row ("REPS") also gets min height 32, so the two numbers stay level.

### Unit toggle (the "quiet" version)

- **One control, not two buttons.** A tap anywhere on it switches the unit, including a tap on the unit that's already selected.
- **Track**: background `card`, radius 9, padding 2, row.
- **Segments "KG" and "LB"**: height 28, min width 34, horizontal padding 8, radius 7, Geist Mono 11, letter-spacing 1.1, centred.
  - **Selected**: background `card2`, text `fg`, weight 600.
  - **Unselected**: transparent, text `muted`, weight 500.
  - **No border and no accent colour.** It should read as a setting, not a call to action. This was an explicit design decision.
- **Hit area**: it's only 32 tall visually. Extend the tap target to at least 44 (for example with padding or a larger `GestureDetector`/`InkWell` area) without changing the look.
- **Semantics**: a single button labelled "Weight in kg. Switch to lb" (or the reverse).

### Behaviour

- **Switching converts the weight in the sheet**: kg→lb = ×2.20462 and lb→kg = ÷2.20462, both rounded to the nearest 0.5. For example, 24 kg → 53 lb.
- **Stepper step**: 2.5 in kg and 5 in lb. The minimum is 0.
- **Display**: whole numbers show without a decimal, and fractions show one decimal (62.5).
- **Each set stores its own unit**, as `{weight, reps, unit}`.
  - **Add set** opens with the last set's weight and unit for this exercise. If there's no previous set, it uses 20 kg converted to the current unit.
  - **Edit set** opens with that set's weight and unit.
- **Anywhere a set is listed, show its own unit**: "53 lb", "60 kg". That covers the active exercise card, the expanded done-exercise rows and the workout detail rows.
- **Volume is always calculated and shown in kg.** Convert lb sets to kg (÷2.20462) before multiplying by reps. All "kg volume" / "kg vol" labels stay as they are.
- **Persistence**: add a `unit` field to the set model and to local storage and sync. Existing data defaults to `kg`.

---

## Part B: Exercise type (Strength / Cardio)

### B1. New exercise sheet (frames 1 · New exercise, 1b · cardio picked)

Top to bottom, inside the existing bottom sheet:

1. **Title**: "New exercise" (22, weight 600, letter-spacing −0.44).
2. **"NAME"**: small-caps label, 18 below the title. It's a real label linked to the input.
3. **Name input**: 8 below the label. Height 56, radius 16, 1px `line` border, `card2` fill, text 17 weight 500, horizontal padding 16.
   - Placeholder depends on the type: "e.g. Bench press" for Strength, "e.g. Treadmill run" for Cardio.
4. **"TYPE"**: small-caps label, 16 below the input.
5. **Type tiles**: 8 below the label. A two-column grid with a gap of 10.
   - **Tile**: `card2`, radius 20, padding 14, column, left-aligned, gap 14, **no border**.
     - **Icon chip**: 36×36, radius 11, icon 18.
       - Selected: background `accent`, icon `accentInk`.
       - Unselected: background `card`, icon `muted`.
     - **Text**: title (16, weight 600) above a subtitle (12, `muted`), gap 3.
       - Strength: "Strength" / "Sets, reps & weight". The icon is a dumbbell, the same icon the app uses for Gym.
       - Cardio: "Cardio" / "Timed, with laps". The icon is a heart with a pulse line (Lucide `heart-pulse`).
   - **The unselected tile is dimmed to 45% opacity.** The selected tile is at 100%.
   - **Semantics**: behaves as a single-choice group, with each tile reporting selected or not selected.
   - **Default**: Strength is selected, and it resets to Strength each time the sheet opens.
6. **"Add exercise" button**: 16 below the tiles. This replaces the old "Start exercise". Background `accent`, text `accentInk`, height 56, radius 18, text 16 weight 600. It shows at 50% opacity and does nothing until the name has text.

Strength exercises behave exactly as they do today after this sheet.

### B2. Active cardio card on Home → Current (frames 2, 3, 4, 5, 5-light)

While the active exercise is cardio, this card shows **instead of** the strength card. The strength card itself is unchanged and keeps its "In progress · mm:ss" line.

**Card**:
- **Base**: background `card`, radius 24, padding 20, column with a gap of 16.
- **Border**: 1px, `accentBorder` while running and `line` otherwise (not started or paused).

**1. Header row** (space-between, top-aligned):
- **Left: the exercise name**, 21, weight 600, letter-spacing −0.42.
  - **Nothing above the name.** There is deliberately no "Running" or "Paused" status line.
- **Right: a "CARDIO" pill**.
  - **Shape**: height 28, horizontal padding 10, radius 9, `card2` background.
  - **Content**: a heart-pulse icon 13 and the text "CARDIO" (Geist Mono 11, weight 600, letter-spacing 1.1), both `muted`, gap 6.

**2. Timer block** (column, gap 6):
- **"ACTIVE TIME"**: small-caps label.
- **The time**: Geist Mono 48, weight 500, letter-spacing −2, line-height 1. It's `fg` while running and `muted` when not started or paused.
  - Format is mm:ss, switching to h:mm:ss at an hour or more.

**3. Lap list**: shown **only when there are 2 or more laps**. With one lap, no lap wording appears anywhere. This is so a plain run without laps never mentions laps.
- **Layout**: rows in a column with a gap of 8.
- **Row**: height 56, radius 16, `card2`, padding left 10 and right 16, gap 12.
  - **Number chip**: 34×34, radius 10, `card` background, Geist Mono 14, `muted`.
  - **Label**: "Lap N" (15, `muted`), which fills the remaining width.
  - **Live dot**: on the current lap while running, a 7px `accent` dot.
  - **Lap time**: Geist Mono 20, weight 600.
  - **Border**: the current lap gets a 1px `accentBorder` while running. Other rows have a transparent border.

**4. "Start new lap" button**: shown once the timer has started, **both while running and while paused**.
- **Shape**: height 52, radius 16, 1.5px dashed `line` border, no fill.
- **Content**: a flag icon 17 and the text "Start new lap" (15, weight 600), centred, gap 8.
- **Hint below it**: only when paused **and** there are 2 or more laps, add "Resume carries on with lap N" (12, `muted`, centred) with a gap of 8.

**5. Footer row** (13, space-between; left text `muted`, right text weight 600):

| Situation | Left | Right |
|---|---|---|
| Not started | "Tap Start when you begin" | (empty) |
| 2 or more laps | "N laps" | (empty) |
| Paused (started) | (as above) | "Paused for mm:ss" |

Hide the whole footer row when both sides are empty, for example when running with a single lap.

### B3. Bottom action buttons (existing floating pair)

The pair is unchanged: the left primary button is 200 wide, `accent`, height 58, radius 18. The right secondary button is `card` with `danger` text and a stop-square icon.

While a cardio exercise is active:

| State | Primary button | Secondary button |
|---|---|---|
| Not started | ▶ "Start" | "End exercise" |
| Running | ❚❚ "Pause" | "End exercise" |
| Paused | ▶ "Resume" | "End exercise" |

The play and pause icons are filled glyphs, size 20.

### B4. Cardio behaviour

**States**: `notStarted` → `running` ⇄ `paused` → `ended`.

| Action | Effect |
|---|---|
| Add exercise (Cardio) | The exercise becomes active with no laps and the timer **not** running. |
| Start | Creates lap 1 and starts timing. |
| Pause | Stops timing and records when the pause began, which drives "Paused for". |
| Resume | Continues timing the current (last) lap. |
| Start new lap | Closes the current lap, opens a new one and starts timing. Works while running or paused, and from paused it also resumes. |
| End exercise | With 0 s of active time, the exercise is removed. Otherwise it's marked done, with duration = active time and its laps kept. |
| End workout while cardio is active | The cardio is saved with the time so far. One with zero time is dropped. |

- **Active time** = the sum of all lap durations, so time spent paused never counts.
- **Implementation note**: don't count timer ticks. Store timestamps (each lap's accumulated seconds plus a `runningSince` time) and work durations out from the clock. That way the timer stays correct if the app is backgrounded or killed, which matters because the app is offline-first.

### B5. Finished cardio in the workout (frame 6)

It uses the existing collapsible "done exercise" card:
- **Subtitle**: "Cardio", or "Cardio · N laps" when there are 2 or more laps.
- **Right-hand figure**:
  - **Value**: the active time (mm:ss, Geist Mono 16 weight 600).
  - **Label underneath**: **"time"** (11, `muted`), in place of the kg volume and "kg vol".
- **Expanded**: one row per lap, only when there are 2 or more laps. Otherwise expanding shows nothing extra.
  - **Row**: the existing 44-tall `card2` row with its 28px number chip.
  - **Content**: "Lap N" (12, `muted`) with the lap time on the right (Geist Mono 15, weight 600).

**Workout detail screen**: cardio exercises show the same lap rows (when there are 2 or more), and the header duration is the active time.

**Totals and summary**:
- **Exercise counts**: cardio counts as an exercise.
- **Sets, reps and volume**: cardio is left out of all three.
- **Summary screen**: the "Volume by exercise" bars leave cardio out.

### B6. Data model

- **Exercise**: add `type` (`strength` | `cardio`). Existing exercises default to `strength`.
- **Cardio**: add `laps` (an ordered list of durations in seconds, or start/stop segments) plus the live state needed for B4. Strength keeps `sets`.
- **Storage and sync**: update local storage, the sync payloads and the server schema, including a migration.

---

## Frames → states (for golden tests)

| Frame (PNG in `screens/`) | State |
|---|---|
| `A2-quiet-toggle-kg.png` | Add set sheet, dark, unit kg, 24 kg × 8 |
| `A2-quiet-toggle-lb.png` | Same, unit lb, 53 lb × 8 |
| `A2-quiet-toggle-light.png` | Same as kg, light theme |
| `1-new-exercise.png` | New exercise sheet, Strength selected, empty name |
| `1b-new-exercise-cardio.png` | New exercise sheet, Cardio selected, name "Treadmill run" |
| `2-cardio-added-not-started.png` | Home, "Treadmill run" active, not started |
| `3-cardio-running-timer-only.png` | Running, 1 lap (10:12) |
| `4-cardio-running-with-laps.png` | Running, laps 10:12 and 01:35 (lap 2 live) |
| `5-cardio-paused.png` | Paused, laps 10:12 and 09:00, paused for 00:42 |
| `6-cardio-finished.png` | Cardio done and expanded in the workout list |
| `5-cardio-paused-light.png` | Frame 5 in the light theme |

The seed workout behind each Home frame: Bench press (done), Incline DB press (done), then Treadmill run.
