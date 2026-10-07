# Decisions

Short records of settled questions, so they are not reopened in every session.
To change one, add a new entry that supersedes it; don't edit history.

Status is **Accepted** unless marked **Open**.

## 1. Supabase is the backend

Postgres with row level security, Supabase Auth (Google and Apple), and Deno
edge functions. No local database: the earlier on-device store was removed
(`lib/util/legacy_database_cleanup.dart` deletes what it left behind). All
access goes through `supabaseClientProvider`.

## 2. Riverpod 3 with code generation

State lives in `@Riverpod` notifier classes with record-typed state. Generated
`*.g.dart` files are committed so the app builds without running `build_runner`.
No other state management library.

## 3. No router package

Tabs are switched with `setState` in the app shell and other screens are pushed
with `Navigator`. The redesign has eight screens and no deep links, so a router
would add weight without solving a problem. Revisit only if deep links or web
are added.

## 4. Liquid glass: `liquid_glass_renderer`, with a `BackdropFilter` fallback

Used on the tab bar and the Current/Previous toggle only. Where the package is
not supported (Android, older iOS), fall back to `BackdropFilter` (blur 24,
saturation about 1.9) with a translucent fill, a 1px light border and a top
inner highlight, as described in the design README. Both paths sit behind one
widget so screens don't branch on platform.

## 5. Fonts are bundled, not fetched

Geist and Geist Mono ship as assets and are used through `AppTypography`.
`google_fonts` fetches at runtime, which makes golden tests non-deterministic
and the first launch dependent on the network. `google_fonts` is removed once
nothing uses it.

## 6. Icons are Lucide

The design's line icons map onto Lucide. Use one icon package, not a mix with
Material icons.

## 7. Place search provider (**Open**)

The prototype mocks place search. The choice is between Google Places and
Apple MapKit search; it affects cost, API keys and Android support. Until it is
decided, place search sits behind an interface with a fake implementation, and
the real provider is its own task. Decide before starting that task.

## 8. `geolocator` for "Use current location"

Request location permission only when the user taps "Use current location",
never at launch.

## 9. Theme defaults to system

The app follows the system light/dark setting until the user picks one under
Profile → Appearance. The choice is stored on the device.

## 10. Redesign work integrates on the `redesign` branch

Task branches start from `redesign` and merge back into it. `main` stays
shippable to TestFlight throughout. `redesign` merges into `main` when the
redesign is complete, or earlier at a point where the app is coherent.

## 11. Golden tests run on Linux only

Text rendering differs between macOS and Linux, so goldens are generated and
compared on Linux only: in CI and in cloud agent sessions. Golden tests carry
the `golden` tag so they can be skipped locally on macOS.

## 12. Colours, radii and spacing come from `AppTokens`

A `ThemeExtension` with dark and light values taken from the design README's
token table. No `Color(0x…)` or `Colors.*` outside `lib/theme/`.
`tool/check_colours.sh` enforces this in CI; files that predate the redesign
are listed in `tool/colour_baseline.txt` and leave that list as they are rebuilt.

## 13. Internal docs live in `dev/`

`docs/` is the public GitHub Pages site, so anything placed there is published.
Agent and contributor docs go in `dev/`.

## 14. Flutter version is pinned in `pubspec.yaml`

`environment.flutter` holds the exact version. CI and the cloud session hook
both read it from there, so there is one place to bump.

## 15. Liquid glass: `liquid_glass_widgets` on iOS and Android

Supersedes 4. Glass comes from the `liquid_glass_widgets` package on both
platforms, pinned to an exact version. The package vendors its renderer and
falls back to a lighter shader where Impeller is unavailable, so there is no
hand-written `BackdropFilter` fallback. Still used on the tab bar and the
Current/Previous toggle only; the package's other glass components (cards,
sheets, buttons, app bars) are not used. The design's geometry and tokens take
priority over the package's default look. Golden tests run on Linux without
Impeller, so the golden harness selects a render setting that is deterministic
there and the real glass is checked on devices.

## 16. Place search: OpenStreetMap behind `PlaceSearchService`

Supersedes 7. The design has no map view, only a text search, a nearby list and
"Use current location", so no maps SDK is needed. Place search sits behind a
`PlaceSearchService` interface supplied by a Riverpod provider, so the backend
can be replaced without touching UI. The first implementation uses
OpenStreetMap data: Photon for typed search and Overpass for the nearby list.
Nominatim is not used because its usage policy forbids search-as-you-type.
"© OpenStreetMap contributors" must be shown in the search panel. Tests use a
fake implementation.

## 17. Notifications ship as an empty state

There is no notifications backend. The Notifications screen and the unread dot
are built against a provider that returns no items, so users see an empty
state rather than placeholder content. A real source is separate work outside
the redesign epic.

## 18. Detail screens keep the tab bar; Summary hides it

The design shows the tab bar on the workout detail screens and hides it only
on Welcome and Summary. So the detail screens are shown inside the app shell,
in place of the tab's screen, and Summary is pushed over the shell with
`Navigator`.
