# Handoff: Workout Tracker redesign (Flutter)

## Overview
A full redesign of the workout-tracking app: sign in → start workout → add exercises and sets → end workout (with location) → summary. Adds a GitHub-style **Tracker** (days worked out), manual logging of past days, location type + optional place search, and month/year-grouped workout history. Dark and light themes.

## About the Design Files
`Workout Tracker.dc.html` is a **design reference built in HTML** — a working prototype of the intended look and behaviour, not code to port line-by-line. Recreate it in the existing **Flutter** codebase using its established patterns (state management, routing, data layer). Open the HTML in a browser (keep `support.js` and `assets/` beside it) to click through every flow.

Where to look inside the HTML:
- Markup/layout: everything between `<x-dc>` and `</x-dc>` (all styles are inline, so every measurement is visible on the element).
- Logic + tokens: the `class Component` script near the bottom. Colour tokens are in `T = { dark, light }`; demo data in `PLACES` and `genHistory()`; tracker logic in `tracker()`; place search in `placeVals()`; hold-to-discard in `holdDown` / `holdUp`; detail edit/delete in `openEditW` / `saveEditW` / `confirmDelW`.

## Fidelity
**High-fidelity.** Match colours, type, spacing, radii and interactions exactly. Demo data (history, places, notifications, user name "Nathan") is placeholder — wire to real data.

## Platform notes (Flutter)
- **Liquid glass** is used in exactly two places: the floating **bottom tab bar** and the **Current/Previous segmented toggle**. Implement with a third-party package (e.g. `liquid_glass_renderer`), falling back to `BackdropFilter(blur 24, saturation ~1.9)` + translucent fill + 1px light border + top inner highlight on Android / older iOS. Do **not** apply glass anywhere else.
- Fonts: **Geist** (UI) and **Geist Mono** (numerals, timers, labels) — via `google_fonts` or bundled.
- Icons: simple 1.8px-stroke line icons (home, grid, bell, person, dumbbell, house, tree, pin, chevrons, plus, ⋮). Use Lucide (`lucide_icons`) or equivalent.
- Map/place search is mocked — back it with Google Places / Apple MapKit search (e.g. `google_places_flutter`, or a geocoding API) plus `geolocator` for "Use current location".

---

## Design Tokens

### Colours
Accent `oklch(0.9 0.2 125)` ≈ **#C6F432** (electric lime). Convert OKLCH values below to sRGB hex in your theme.

| Token | Dark | Light | Use |
|---|---|---|---|
| bg | #0A0B0D | #F3F4EF | Screen background |
| card | #15171A | #FFFFFF | Cards |
| card2 | #1F2125 | #EBEDE6 | Inset rows, chips, inputs, empty grid squares |
| line | rgba(255,255,255,.08) | rgba(10,12,8,.08) | 1px borders/dividers |
| fg | #F3F4EF | #0F110D | Primary text |
| muted | #8B8F88 | #666B63 | Secondary text, labels |
| accent | ≈#C6F432 | ≈#C6F432 | Primary buttons, active pill, filled squares |
| accentInk | #0A0B0D | #0F110D | Text/icons on accent |
| accentText | ≈#C6F432 | oklch(0.5 0.15 130) ≈ #4F7A12 | Accent-coloured text |
| danger | oklch(0.7 0.19 25) ≈ #F2645A | oklch(0.56 0.2 25) ≈ #C8302B | End / delete |
| dangerBg | danger @ 13% | danger @ 10% | Destructive button fill |
| sheet | #141619 | #FFFFFF | Bottom sheets |
| scrim | rgba(0,0,0,.55) | rgba(10,12,8,.35) | Behind sheets |
| glass | rgba(255,255,255,.07) | rgba(255,255,255,.5) | Glass fill |
| glassLine | rgba(255,255,255,.14) | rgba(255,255,255,.85) | Glass border |
| glassHi | rgba(255,255,255,.32) | #FFFFFF | Glass inner top highlight |
| glassBubble | rgba(255,255,255,.13) | rgba(15,17,13,.07) | Selected glass pill |
| glassShadow | rgba(0,0,0,.45) | rgba(20,24,16,.14) | Drop shadows |
| orb1 / orb2 | accent @14% / cyan @14% | accent @40% / cyan @30% | Two blurred (70px) background glows |

Tracker heat levels: 0 = card2, 1 = accent 35% mixed into card2, 2 = 65%, 3 = accent.

### Typography
- Screen titles: Geist 600, 30px, letter-spacing −0.035em
- Name (header): Geist 600, 20px, −0.02em; greeting 13px muted
- Main workout timer: Geist Mono 500, 64px, −0.05em, line-height 1
- Card titles: Geist 600, 16–22px
- Stat numbers: Geist Mono 500, 20–26px
- Micro labels: Geist Mono 500, 10–11px, letter-spacing 0.14–0.16em, UPPERCASE, muted
- Body/secondary: Geist 400–500, 13–15px
- Buttons: Geist 600, 16px (14–15 for secondary)

### Radii
Screen frame 54 · glass tab bar 33 (pill) · segmented toggle 23 / bubble 18 · cards 20–24 · set row 16 · buttons 18 · inputs 16 · icon buttons 14 · chips 7 · tracker squares 4 · sheets 32 (top corners).

### Spacing
Screen horizontal padding 20. Card padding 16–20. Gaps: 6/8/10/12/14/18/22. Primary buttons 56–58px tall. Icon buttons 44×44. Content bottom padding ~210 to clear floating buttons + tab bar.

### Shadows
Floating buttons: 0 10 30 glassShadow. Tab bar: 0 14 36 glassShadow + inset 0 1 1 glassHi + inset 0 −1 1 glassLo. Sheets: 0 −10 40 rgba(0,0,0,.3).

---

## Global chrome
- **Bottom tab bar** (glass): floating, centred, 340×66, bottom 26, padding 6. Four tabs (82px each): Home, Tracker, Notifications, Profile. Each tab = 22px icon + 10px/600 label. Selected tab gets a 82×52 `glassBubble` pill that slides with a springy curve (500ms, cubic-bezier(.3,1.4,.5,1)); selected label = fg, others = muted. Red 7px dot on bell when unread. Hidden on Welcome and Summary.
- **Floating action row** (Home only): bottom 106, left/right 20, gap 8. Contents depend on state (see Home).
- **Bottom sheets**: full-width, sheet colour, top radius 32, padding 10/20/40, 40×5 grab handle, scrim tap closes.

## Screens

### 1. Welcome / Sign in
Logo 64×64 (radius 18) top-left at ~96px from top. Label "WELCOME" (mono, accentText). Headline "Track your workouts. Crush your goals." Geist 600 44px −0.04em lh 1.02. Bottom: "Sign in with Apple" (fg fill, bg text, 56h r18), "Sign in with Google" (card fill, 1px line border), "Privacy Policy" link 13px muted.

### 2. Home
**Header**: 44×44 accent avatar (r14, initial, 700 17px) · greeting ("Good morning/afternoon/evening", 13px muted) over name (20px 600) · 44×44 bell button (card, 1px line, r14) with accent unread dot.

**Workout block** (padding-top 26): label "WORKOUT" + status pill — "ACTIVE" (accent fill, accentInk dot + mono 11px) or "INACTIVE" (card2, muted). Large timer `HH:MM:SS` (fg when active, muted `00:00:00` when idle). When active, a row "N EX · N SETS · N KG VOL" (mono 12px muted).

**Current / Previous toggle** (glass): margin-top 22, 46h, r23, padding 4; sliding 170×36 bubble (450ms spring).

**Current tab**
- Idle: centred "Get started by starting a workout!" (15px muted).
- Workout with no exercises: "No exercises have been added to this workout yet".
- **Active exercise card** (card, r24, padding 20): "In progress · MM:SS" (12px 600 accentText) over exercise name (21px 600). Right: **rest timer pill** (card2, r12, 34h, clock icon + mono MM:SS, counts up from last saved set). Set rows (card2, r16, 56h, gap 6): set-number tile 36×36 (card, r11, mono) · `kg` value (20px 600 + "kg" 13px muted) · reps · ⋮ button (40×40) → Set menu sheet. Empty: dashed 56h row "No sets added yet". Footer: "N sets · N reps" muted / "N kg volume" fg 600.
- **Completed exercise rows**: these expand in place when tapped.
  - Collapsed (card, r20, padding 16/18): 40×40 card2 tile with an accent check · name (16px 600, ellipsis) over "N sets · N reps · Xm Ys" · volume (mono 17) over "kg vol" · a 16px chevron.
  - Tapping toggles open. The chevron rotates 90° (250ms) and the border becomes accent at 45%. One card can be open at a time; tapping it again closes it.
  - Expanded body (padding 0/16/16, gap 6): one row per set (card2, r14, 44h), containing a 30×30 number tile (r10, mono) · "60 kg" · "8 reps" · volume (mono muted).
  - Expanded footer: "TOP SET 70 KG × 6" left and "AVG 66.4 KG" right (mono 11, muted). Top set = heaviest weight, with most reps breaking ties. Avg = volume ÷ total reps.

**Previous tab** — grouped by year then month, newest first; months with no workouts get no header.
- **Year header**: sticky at top:0 of the scroll area, 44h, Geist Mono 500 26px.
- **Month header**: sticky directly below the year (top:44), 34h, "OCTOBER" (mono 11px accentText) left, "N WORKOUTS" right, 1px bottom line. Each new month/year pushes the previous one off.
- Headers are transparent at rest; once the list has scrolled under the status bar, status bar + both headers get `bg @70%` fill + blur(20).
- **Workout card** (card, r20, padding 16/18, tap → Detail): date `DD/MM/YY` (16px 600) + **location chip** · chevron. No time, duration or title on the card. Below: 4-column stats — EX, SETS, REPS, KG (volume in accentText). Mono 20px values over 10px labels.
- **Location chip**: card2, r7, 22h, padding 0 8; 11px icon for the location **type** (dumbbell=Gym, house=Home, tree=Park, pin=Other) + place name (or type if no place). Truncates with ellipsis; date never shrinks.

**Floating actions**
- No workout: "Start workout" (accent, full width).
- Workout, no active exercise: "Add exercise" (accent, flex 1.4) + "End workout" (card, 1px line, danger text + 12px danger square).
- Active exercise: "Add set" + "End exercise" (same styles).

### 3. Tracker
Header: "ACTIVITY" label over "Tracker" title; right "＋ Log workout" button (card, 1px line, r14, 44h).
Stats row (3 cols, gap 8, r18): **DAY STREAK** (accent fill), **{MONTH}** days this month, **TOTAL DAYS**.
**Contribution grid** card (r24): 17 weeks × 7 days (Mon–Sun rows), 14×14 squares, gap 3, r4. Row labels M/W/F/S, month labels above the first week containing the 1st. Future days = transparent with 1px line ring and not tappable. Selected day = 2px bg + 1.5px fg double ring. Footer: "LAST 17 WEEKS" + Less→More legend.
Heat level by sets that day: 1–5 → 1, 6–9 → 2, 10+ → 3; manual-only day → 2.
**Selected day panel**: "Today" / "Yesterday" / "Monday 4 October" + "N ENTRIES". Entries are listed in order: recorded workouts, the live workout, then manual entries.

**Unified entry card** (card, 1px line, r20, padding 14/14/14/16, gap 12, whole card tappable):
- **Icon tile** 40×40, r12, card2 fill, location-type icon. Recorded = **accentText** icon; manual = **muted (grey)** icon. Nothing else differs visually.
- **Title row**: the title (15px 600) fills the remaining width and ellipsises. The **location chip** is right-aligned and sized to its content, capped at **50% of the row**: "Gym" gives a small chip, a long place name takes half the row and ellipsises.
- **Subtitle**: a single 13px muted line with one-line ellipsis.
  - Recorded: `HH:MM · 1h 2m · 2 ex · 6 sets · 1,240 kg`.
  - Manual: `Logged manually`.
  - Live workout: `N ex · N sets · N kg so far`, titled "In progress", and it opens Home.
- **Chevron** 16px on the right. There is no Remove button on cards.
- Tapping a card opens the Workout detail (recorded) or the Manual workout detail. Back returns to the Tracker.
- Empty day: dashed card "No workout logged on this day" + "Log a workout" (accent) → Log sheet pre-set to that day.

### 4. Workout detail (recorded)
- **Header row**: back button (44×44 r14) on the left; "✎ Edit" button (44h, r14, card + 1px line) on the right.
- **Title**: workout name, 26px 600, wraps.
- **Meta**: "DD/MM/YY · HH:MM" label + location chip, then duration in mono 52px.
- **Stat tiles**: SETS and REPS (card), plus TOTAL VOLUME full-width (accent fill).
- **Exercise cards** (card, r20, padding 16): name + duration, then set rows (card2, r14, 44h) containing a 30×30 number tile (r10) · "60 kg" · "8 reps" · volume (mono muted).
- **Bottom**: "Delete workout" (dangerBg, danger text, r18, 52h) → Delete workout sheet.

### 4b. Manual workout detail
- **Header row**: same as 4 (back + Edit).
- **Badge**: "✎ LOGGED MANUALLY" (mono 10, 1.5px dashed line border, r7).
- **Title**: 26px 600.
- **Meta**: "DD/MM/YY" + location chip.
- **Info card** (card, r20) with rows split by 1px lines:
  - DATE: "Tue 21 September 2026".
  - TYPE: type icon + label.
  - PLACE: name, with the address beneath it in 12px muted, or "Not set". Both ellipsise.
- **Note**: "No exercise details were recorded for this workout." (14px muted).
- **Bottom**: "Delete workout" (same as 4).

### 5. Workout summary (after ending)
52×52 accent check tile (r16). "WORKOUT COMPLETE" label, workout title (24px 600, ellipsis), duration mono 60px, "DD/MM/YY · HH:MM · {place}" (ellipsised). 3 stat tiles (Exercises/Sets/Reps). "VOLUME BY EXERCISE" card with total and per-exercise 8px bars (accent on card2, width = share of max). "Done" (fg fill) → Home/Current. No tab bar.

### 6. Notifications
Title + list of cards (r20): 8px unread dot (accent) · title 15/600 · time (mono 11) · body 14 muted. Opening the tab marks all read.

### 7. Profile
Title. Avatar 60×60 accent (r18) + name + "N WORKOUTS LOGGED". Settings card: Appearance (Dark/Light segmented, card2 track, r12), Privacy Policy, Sign out. "Delete account" (dangerBg, r18) → confirm sheet.

## Sheets
- **New exercise**: title, text input (card2, r16, 56h, placeholder "Exercise name"), "Start exercise". Empty name → "Exercise N".
- **Set (add/edit)**: title "Set N" / "Edit set N". Two tiles (card2, r20): "WEIGHT · KG" and "REPS" with large mono 40px numeric input and −/+ buttons (kg ±2.5, reps ±1, min 0). New set pre-fills from the last set. CTA "Add set" / "Save changes".
- **Set menu (⋮)**: "Set N" + "60 kg × 8 reps"; "Edit set" (card2) / "Delete set" (dangerBg).
- **End workout**: "End workout?" + "N exercises · N sets · N kg in HH:MM:SS".
  - **WORKOUT NAME** field (card2, r16, 56h, max 40 chars, placeholder "e.g. Push day"). Its "REQUIRED" label is danger-coloured while the field is empty and muted once filled.
  - **Location** section (below).
  - **End workout button** (danger fill, r18, **62h**): main label "End workout" with a second line "Hold to discard workout" (12px, white 82%). See *Hold to discard* below.
  - "Keep going" (card2) closes the sheet.
- **Log a workout**: "Log a workout" / "For workouts you didn't record in the app."
  - Date stepper (‹ date ›); you can't step past today.
  - **WORKOUT NAME** (required, placeholder "e.g. Morning run").
  - Location section.
  - "Add workout" (accent): disabled at 40% opacity until a name is entered. Each confirm **adds** a new manual entry, so a day can have any number.
- **Edit workout** (from either detail page): WORKOUT NAME (required, prefilled) + the full Location section (type + place, prefilled), for **both recorded and manual** workouts. "Save changes" (accent, disabled when the name is empty) and "Cancel".
- **Delete workout**: "Delete workout?" / "“{name}” will be removed from your history and the tracker." Options are "Delete workout" (danger) or "Cancel". Confirming returns to wherever the detail page was opened from (Tracker or Previous).
- **Delete account**: confirm / cancel.
- Sheets cap at 800px tall and scroll internally.

### Hold to discard (End workout button)
- **Tap**: saves the workout as normal. Requires a name.
- **Press and hold**: works even with no name. After 250ms a dark band (black 32%) fills the button left→right over **3 s**. The main label becomes "Keep holding to discard · 3s/2s/1s", the hint line hides, and the button goes to full opacity.
- **At 3 s**: the workout is discarded, nothing is saved and the tracker is not updated. The sheet closes and Home shows the idle state.
- **Releasing early**: resets the band and does nothing. A hold never also counts as a tap.
- **Flutter**: `GestureDetector(onLongPressStart/End)` or `onTapDown` + `AnimationController(duration: 3s)`. Add a medium haptic at the start and a heavy haptic on discard.

### Location section (End workout + Log a day)
1. **Type** — "LOCATION" label + 4-column grid of 64h tiles (r16): Gym, Home, Park, Other (icon + label). Selected = accent fill/accentInk; others card2. Defaults to the most recent workout's type.
2. **Place (optional, type-agnostic)** — dashed 52h button "Search for a location". Tapping expands an inline search panel (card2, r18): search field (placeholder "Name, address or postcode…") with close ✕; first row "Use current location"; then results labelled **NEARBY** (all places, sorted by distance) or **RESULTS** (filtered by name/address as you type); each result = pin tile + name + address + distance. "No results" state when the query matches nothing. Choosing a place collapses the panel into a selected-place row (name + address + clear ✕). Picking a place never changes the selected type.

## Interactions & Behaviour
- Timers tick every second: workout `HH:MM:SS`, exercise `MM:SS`, rest `MM:SS` since last set.
- Only one active exercise at a time; "End exercise" moves it to Completed.
- **Tracker rule**: a day is logged when a workout has ≥1 exercise with ≥1 saved set — the current day lights up as soon as the first set is saved, before the workout ends. Manual entries also count.
- Streak = consecutive logged days ending today (or yesterday if today isn't logged yet).
- Ending a workout saves `{title, start, duration, type, place?, exercises[]}` and opens Summary.
- Editing a workout updates every surface it appears on: the Previous card chip, the tracker card, and both detail pages.
- Deleting a workout removes it from Previous and the Tracker. If no other entries remain on that day, the square turns grey again.
- Transitions: tab bubble 500ms and toggle bubble 450ms, both springy overshoot; other state changes are instant/fade.
- Theme switch under Profile → Appearance (should default to system).

## State / Data model
```
Workout      { id, title, start, durationSec, locationType: Gym|Home|Park|Other, place?: {name, address, lat?, lng?}, exercises: Exercise[] }
Exercise     { name, start, end?, sets: Set[] }
Set          { kg: double, reps: int, savedAt }
ManualWorkout { id, date (yyyy-mm-dd), title, locationType, place? }   // many per date
UI state     screen, homeTab (current|previous), selectedDay, activeSheet, editingSetIndex, expandedExerciseId, theme, unread
```
Derived: per-day map of workouts + manual entries → heat level, streak, month count, total days; per-exercise volume = Σ kg×reps.

## Assets
- `assets/logo.png` — existing app logo (cropped from the original app screenshot). Consider recolouring to the lime palette.
- No other imagery. Icons are inline SVG line icons — swap for an icon package.

## Files
- `Workout Tracker.dc.html`: the prototype. Open it in a browser.
- `support.js` — runtime needed to open the prototype.
- `assets/logo.png` — logo.
