@AGENTS.md

# Claude Code notes

Everything above applies. These notes cover the Claude-specific setup in
`.claude/`.

## Skills

- `/next-task`: pick the next ready bead, claim it, branch from `redesign`,
  do the work, run the definition-of-done checks and close the bead.
- `/build-screen <name>`: build one screen or sheet from the design package,
  with widget and golden tests in both themes.
- `/capture-design`: re-render `design/workout-tracker/screens/` after the
  design package changes.
- `liquid-glass-widgets`: API guide for the `liquid_glass_widgets` package,
  copied unmodified from the package's `skills/` directory. Use it for setup
  and correct widget names. Where it disagrees with the design rules in
  `AGENTS.md`, `AGENTS.md` wins: its table of glass replacements for standard
  widgets does not apply here, because glass is allowed on the tab bar and the
  Current/Previous toggle only. To update it, re-run the `curl` command from
  the package's `skills/README.md`.

## Agents

- `design-reviewer` (read-only): compares a screen's golden PNGs with the
  reference screenshots and checks token and glass usage. Run it before closing
  any bead that touches UI.

## Hooks

- **SessionStart** (`.claude/hooks/session-start.sh`): in cloud sessions only,
  installs the pinned Flutter SDK and `bd` if they are missing, runs
  `flutter pub get` and prints `bd prime`. It does nothing on a local machine.
- **PostToolUse** (`.claude/hooks/format-dart.sh`): runs `dart format` on any
  `.dart` file you edit or write. Do not fight the formatter.

## Environment

- Cloud sessions run Linux, so goldens can be generated and checked there.
- Local macOS sessions cannot update goldens; leave that to a cloud session or CI.
