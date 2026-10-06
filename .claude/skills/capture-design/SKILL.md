---
name: capture-design
description: Re-render the reference screenshots in design/workout-tracker/screens/ from the HTML prototype. Use after the design package (README, prototype HTML, support.js or assets) changes, or when a screenshot is missing or wrong.
---

# Capture design screenshots

The prototype keeps its screen in component state, so
`design/workout-tracker/scripts/capture_screens.mjs` clicks through it with
Playwright and writes one 390×844 PNG per state and theme.

## Run

```
npm --prefix design/workout-tracker/scripts install
node design/workout-tracker/scripts/capture_screens.mjs
```

- If Playwright has no browser, either run
  `npx --prefix design/workout-tracker/scripts playwright install chromium` or
  use an installed Chrome with `PW_CHANNEL=chrome` in front of the `node` command.
- `--theme dark` or `--theme light` captures one theme.
- The script needs network access once, to load Geist from Google Fonts.

## Check the result

1. `git status design/workout-tracker/screens` shows which PNGs changed.
2. Open several of the changed PNGs, including at least one sheet, in both
   themes. Confirm each shows the screen its name says, in the right theme,
   with Geist rendered (not a fallback serif or system font).
3. If the script fails on a click, the prototype's markup changed. Fix the
   selector in the script; do not edit the prototype to suit the script.

## Keep the index in step

If the prototype's structure changed, update the line ranges and the
screenshot names in `design/workout-tracker/INDEX.md`. If you added or renamed
a captured state, add it to INDEX.md too.

Screenshot changes alter the visual truth for every screen, so list the changed
files in the PR description.
