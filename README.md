# FittenUp

A workout tracker for iOS and Android, built with Flutter, Riverpod and
Supabase. Start a workout, add exercises and sets, and look back over your
history.

The app is being redesigned. The spec, prototype and reference screenshots are
in [`design/workout-tracker/`](design/workout-tracker/README.md).

## Getting started

You need the Flutter version pinned under `environment.flutter` in
[`pubspec.yaml`](pubspec.yaml).

```bash
flutter pub get
```

```bash
flutter run
```

## Development

```bash
dart run build_runner build --delete-conflicting-outputs
```

```bash
dart format . && flutter analyze && flutter test
```

Pull requests run the same checks in GitHub Actions
([`.github/workflows/ci.yml`](.github/workflows/ci.yml)). TestFlight builds run
on Codemagic ([`codemagic.yaml`](codemagic.yaml)).

## Where things are

| Path | What |
|---|---|
| `lib/` | App code |
| `test/` | Unit, widget and golden tests |
| `supabase/` | Database migrations and edge functions |
| `design/workout-tracker/` | Redesign spec, prototype and screenshots |
| `dev/` | Internal docs: [architecture](dev/architecture.md), [decisions](dev/decisions.md) |
| `docs/` | The public website and privacy policy (GitHub Pages) |

## Working with coding agents

[`AGENTS.md`](AGENTS.md) is the guide for coding agents (Claude Code, Codex,
Cursor): stack, commands, design rules, workflow and definition of done.
Tasks are tracked with [beads](https://github.com/steveyegge/beads); run
`bd ready` to see what can be picked up next.
