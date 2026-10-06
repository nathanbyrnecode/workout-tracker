# Design package index

A map from each section of [README.md](README.md) (the spec) to the part of the
prototype that implements it and the screenshots that show it. Read this before
opening `Workout Tracker.dc.html`: the file is 117 KB with very long lines, so
read it by line range (`offset`/`limit`) rather than whole.

- **Spec:** `README.md`. Where it disagrees with the prototype, the README wins.
- **Visual truth:** `screens/<name>-dark.png` and `screens/<name>-light.png`, 390×844.
- **Prototype:** `Workout Tracker.dc.html` (needs `support.js` and `assets/` beside it).
- **Regenerate screenshots:** `node design/workout-tracker/scripts/capture_screens.mjs`
  (see the `capture-design` skill).

The screenshots include the prototype's fake status bar and notch (top 54px).
Those are device chrome, not something to build.

## Prototype layout

| Lines | What |
|---|---|
| 9–628 | Markup, between `<x-dc>` and `</x-dc>`. All styles are inline. |
| 13 | Device frame: 390×844, defines every `--token` CSS variable from `t`. |
| 630–861 | `class Component`: tokens, demo data, state and handlers. |
| 631–634 | `T = { dark, light }` colour tokens (source for `AppTokens`). |
| 635–647 | `PLACES` demo data for place search. |
| 648 | `ICONS` SVG paths per location type (Gym, Home, Park, Other). |
| 650–658 | `init()`: initial state. `screen` is one of `home`, `tracker`, `detail`, `mdetail`, `summary`, `notif`, `profile`, `welcome`. |
| 677–684 | `view(p)`: derives the display model for a recorded workout. |
| 688–703 | `placeVals()`: place search state (idle / searching / selected, NEARBY vs RESULTS). |
| 704–718 | `genHistory()`: seeded demo history. |
| 719–762 | `tracker()`: per-day map, heat levels, 17-week grid, streak, selected-day items, log sheet. |
| 764–860 | `renderVals()`: everything the markup binds to, including all handlers. |

Bindings in the markup look like `{{ name }}`, `<sc-if value="{{ flag }}">` and
`<sc-for list="{{ items }}" as="x">`. To find a piece of UI, grep for the flag
or handler name from the tables below.

## Screens

| README section | Markup lines | Flag | Key functions | Screenshots |
|---|---|---|---|---|
| Design Tokens | 13 | `t` | `T` (631–634) | every screen |
| Global chrome: tab bar | 365–374 | `showTabBar` | `tabLeft`, `goHome`, `goTracker`, `goNotif`, `goProfile` | every in-app screen |
| Global chrome: floating action row | 349–363 | `showActions`, `actStart`, `actWorkout`, `actExercise` | `startWorkout`, `openAddEx`, `openEndWorkout`, `openAddSet`, `endExercise` | `home-*` |
| Global chrome: bottom sheets | 376–379 | `anySheet` | `closeSheet` | `sheet-*` |
| 1. Welcome / Sign in | 27–43 | `isWelcome` | `signIn` | `welcome` |
| 2. Home: header, workout block, toggle | 47–79 | `isHome` | `greeting`, `workoutTimer`, `segLeft`, `tabCurrent`, `tabPrevious` | `home-idle`, `home-empty-workout`, `home-active-workout`, `home-active-exercise` |
| 2. Home: Current tab, active exercise card | 80–115 | `isCurrent`, `hasActive`, `hasRest` | `activeSets`, `restTimer` | `home-active-exercise` |
| 2. Home: completed exercise rows | 116–141 | `hasDone`, `e.open` | `doneList` (801–805) | `home-active-exercise`, `home-completed-expanded`, `home-active-workout` |
| 2. Home: Previous tab | 142–177 | `isPrevious` | `prevYears` (808), `onScroll`/`stuck` (786), `view()` | `home-previous`, `home-previous-scrolled` |
| 3. Tracker | 178–229 | `isTracker` | `tracker()` | `tracker`, `tracker-manual-day`, `tracker-empty-day` |
| 4. Workout detail (recorded) | 230–257 | `isDetail` | `dv`, `openEditW`, `openDelW`, `back` | `detail` |
| 4b. Manual workout detail | 258–278 | `isMDetail` | `mv` (809) | `manual-detail` |
| 5. Workout summary | 279–305 | `isSummary` | `sv`, `closeSummary` | `summary` |
| 6. Notifications | 306–322 | `isNotif` | `notifs`, `hasUnread` | `notifications` |
| 7. Profile | 323–348 | `isProfile` | `setDark`, `setLight`, `signOut`, `openDelete` | `profile` |

## Sheets

All sheets render inside the shared scaffold at lines 376–379.

| README section | Markup lines | Flag | Key functions | Screenshots |
|---|---|---|---|---|
| New exercise | 380–384 | `sheetAddEx` | `openAddEx`, `confirmAddEx` | `sheet-new-exercise` |
| Set (add/edit) | 385–400 | `sheetSet` | `openAddSet`, `kgDec`/`kgInc`, `repsDec`/`repsInc`, `confirmSet` | `sheet-set-add`, `sheet-set-edit` |
| Set menu (⋮) | 401–407 | `sheetMenu` | `editSet`, `deleteSet` | `sheet-set-menu` |
| End workout | 408–467 | `sheetEnd` | `openEndWorkout`, `confirmEndWorkout` (854) | `sheet-end-workout`, `sheet-end-workout-search`, `sheet-end-workout-filled` |
| Hold to discard | 461–464 | `holdPct`, `notHolding` | `holdDown` / `holdUp` (848–849), `endLabel` | not captured (time-based) |
| Location section | 413–459 (End), 478–523 (Log), 558–604 (Edit) | `hasPlace`, `placeIdle`, `placeSearching`, `noResults` | `locOpts` (757), `placeVals()` | `sheet-end-workout*`, `sheet-log-workout`, `sheet-edit-workout` |
| Log a workout | 468–526 | `sheetLog` | `openLog`, `logPrev`/`logNext`, `confirmLog` (760) | `sheet-log-workout` |
| Edit workout | 552–610 | `sheetEditW` | `openEditW` / `saveEditW` (814–815) | `sheet-edit-workout` |
| Delete workout | 611–617 | `sheetDelW` | `openDelW`, `confirmDelW` (817) | `sheet-delete-workout` |
| Delete account | 618–624 | `sheetDelete` | `openDelete`, `confirmDelete` | `sheet-delete-account` |

Lines 527–551 (`sheetEx`) are an alternative "exercise info" sheet behind the
`exDetail: 'sheet'` prop. The README specifies the expand-in-place rows instead,
so do not build it.

## Behaviour not visible in a screenshot

| Behaviour | Where |
|---|---|
| Tracker rule, heat levels, streak | `tracker()` 722–742, README "Interactions & Behaviour" |
| Top set and average on completed rows | `doneList` 801–803 |
| Sticky header fill once scrolled under the status bar | `onScroll` 786 |
| Tab bubble and toggle bubble spring | markup 368 and 75, README "Global chrome" |
| Default location type = most recent workout's type | `openEndWorkout` 847, `openLog` 758 |
