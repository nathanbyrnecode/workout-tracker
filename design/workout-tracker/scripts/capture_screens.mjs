// Renders reference screenshots from the HTML prototype.
//
//   npm --prefix design/workout-tracker/scripts install     (once)
//   node design/workout-tracker/scripts/capture_screens.mjs [--theme dark|light] [--scale 2]
//
// Writes 390x844 PNGs to design/workout-tracker/screens/<name>-<theme>.png.
//
// The prototype keeps its screen in component state, not in the URL, so every
// state is reached by clicking through the UI the way a user would. The clock
// is frozen so history, timers and the tracker grid are identical on each run.
//
// Set PW_CHANNEL=chrome to use an installed Chrome instead of Playwright's
// bundled Chromium.

import { mkdir, readdir, rm } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { chromium } from 'playwright';

const here = path.dirname(fileURLToPath(import.meta.url));
const designDir = path.resolve(here, '..');
const outDir = path.join(designDir, 'screens');
const prototype = pathToFileURL(path.join(designDir, 'Workout Tracker.dc.html')).href;

// Tuesday 6 October 2026, 09:41 local. Matches the prototype's status bar.
const FROZEN_NOW = new Date('2026-10-06T09:41:00+01:00');
const FRAME = { width: 390, height: 844 };

const args = process.argv.slice(2);
const flag = (name) => {
  const i = args.indexOf(`--${name}`);
  return i === -1 ? undefined : args[i + 1];
};
const themes = flag('theme') ? [flag('theme')] : ['dark', 'light'];
const scale = Number(flag('scale') ?? 1);

const pad = (n) => String(n).padStart(2, '0');
const dayKey = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const daysAgo = (n) => {
  const d = new Date(FROZEN_NOW);
  d.setDate(d.getDate() - n);
  return dayKey(d);
};

async function capture(browser, theme) {
  const context = await browser.newContext({
    viewport: { width: FRAME.width + 22, height: FRAME.height + 22 },
    deviceScaleFactor: scale,
    locale: 'en-GB',
    timezoneId: 'Europe/London',
    colorScheme: theme,
  });
  const page = await context.newPage();
  await page.clock.setFixedTime(FROZEN_NOW);
  await page.goto(prototype, { waitUntil: 'networkidle' });

  const frame = page.locator('div[style*="width: 390px"]').first();
  await frame.waitFor();
  await page.evaluate(() => document.fonts.ready);
  // Drop the device bezel so the PNG is a flat 390x844 surface.
  await frame.evaluate((el) => {
    el.style.borderRadius = '0';
    el.style.boxShadow = 'none';
  });

  const settle = () => page.waitForTimeout(700); // longest transition is 500ms
  const button = (name) => page.getByRole('button', { name, exact: true });
  const click = async (locator) => {
    await locator.click();
    await settle();
  };
  const tab = (name) => click(button(name).first());
  const closeSheet = async () => {
    await page.locator('div[style*="var(--scrim)"]').dispatchEvent('click');
    await settle();
  };
  const shot = async (name) => {
    const file = path.join(outDir, `${name}-${theme}.png`);
    await frame.screenshot({ path: file, animations: 'disabled' });
    console.log(`  ${path.relative(designDir, file)}`);
  };
  const back = () => click(page.locator('button:has(path[d="m15 18-6-6 6-6"])').first());

  // The prototype opens mid-workout: one completed exercise, one in progress.

  // Profile first: it holds the theme switch and does not mark notifications read.
  await tab('Profile');
  await click(button(theme === 'dark' ? 'Dark' : 'Light'));
  await shot('profile');
  await click(button('Delete account').first());
  await shot('sheet-delete-account');
  await closeSheet();

  // Home, Current tab, active exercise.
  await tab('Home');
  await shot('home-active-exercise');
  await click(page.getByText('Bench press', { exact: true }));
  await shot('home-completed-expanded');
  await click(page.getByText('Bench press', { exact: true }));

  await click(page.locator('button:has(circle[r="2"])').first());
  await shot('sheet-set-menu');
  await click(button('Edit set'));
  await shot('sheet-set-edit');
  await closeSheet();
  await click(button('Add set').first());
  await shot('sheet-set-add');
  await closeSheet();

  // Workout running, no active exercise.
  await click(button('End exercise'));
  await shot('home-active-workout');
  await click(button('Add exercise'));
  await shot('sheet-new-exercise');
  await closeSheet();

  // End workout sheet: empty, place search open, then filled in.
  await click(button('End workout').first());
  await shot('sheet-end-workout');
  await click(button('Search for a location'));
  await shot('sheet-end-workout-search');
  await click(page.getByText('PureGym Manchester Piccadilly', { exact: true }));
  await page.getByPlaceholder('e.g. Push day').fill('Push day');
  await settle();
  await shot('sheet-end-workout-filled');
  await click(page.getByRole('button', { name: /Hold to discard/ }));
  await shot('summary');

  // Idle, then a fresh workout with no exercises yet.
  await click(button('Done'));
  await shot('home-idle');
  await click(button('Start workout'));
  await shot('home-empty-workout');

  // Previous tab, at rest and scrolled far enough for the sticky headers to fill.
  await click(button('Previous'));
  await shot('home-previous');
  const scroller = page.locator('div[style*="overflow-y: auto"]').first();
  await scroller.evaluate((el) => el.scrollTo(0, 900));
  await settle();
  await shot('home-previous-scrolled');
  await scroller.evaluate((el) => el.scrollTo(0, 0));
  await settle();

  // Recorded workout detail, opened from Previous. The newest card is the
  // "Push day" workout saved above.
  await click(page.getByText('06/10/26', { exact: true }).first());
  await shot('detail');
  await click(button('Edit'));
  await shot('sheet-edit-workout');
  await closeSheet();
  await click(button('Delete workout').first());
  await shot('sheet-delete-workout');
  await closeSheet();
  await back();

  // Tracker: today, a day with manual entries, and an empty day.
  await tab('Tracker');
  await shot('tracker');
  await click(page.locator(`button[title="${daysAgo(16)}"]`));
  await shot('tracker-manual-day');
  await click(page.getByText('Park run', { exact: true }));
  await shot('manual-detail');
  await back();
  for (let n = 1; n < 60; n++) {
    await page.locator(`button[title="${daysAgo(n)}"]`).click();
    if (await page.getByText('No workout logged on this day').isVisible()) break;
  }
  await settle();
  await shot('tracker-empty-day');
  await click(button('Log workout'));
  await shot('sheet-log-workout');
  await closeSheet();

  await tab('Notifications');
  await shot('notifications');

  await tab('Profile');
  await click(button('Sign out'));
  await shot('welcome');

  await context.close();
}

await mkdir(outDir, { recursive: true });
for (const file of await readdir(outDir)) {
  if (themes.some((t) => file.endsWith(`-${t}.png`))) await rm(path.join(outDir, file));
}

const browser = await chromium.launch({ channel: process.env.PW_CHANNEL || undefined });
try {
  for (const theme of themes) {
    console.log(`${theme}:`);
    await capture(browser, theme);
  }
} finally {
  await browser.close();
}
