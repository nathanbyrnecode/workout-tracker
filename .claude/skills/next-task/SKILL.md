---
name: next-task
description: Pick up the next ready redesign task from beads, do it on its own branch, verify it against the definition of done and close it. Use when asked to "do the next task", "continue the redesign" or "pick up a bead".
---

# Next task

Do exactly one bead per run. Stop after it is closed.

## 1. Pick and claim

1. Run `bd import .beads/issues.jsonl` to pick up issues merged since the
   last session, then `bd ready --json`. If the user named a bead, use that one; otherwise
   take the highest-priority ready bead. Skip `fit-epic` itself: it is the
   container, and closes when its children are done.
2. Run `bd show <id>` and read the whole thing: description, acceptance
   criteria, design section, dependencies and any notes left by earlier sessions.
3. Claim it: `bd update <id> --claim`.

If nothing is ready, say so and show `bd blocked`. Do not start blocked work.

## 2. Branch

```
git fetch origin
git switch -c <id>-<short-slug> origin/redesign
```

Branch from `redesign`, never from `main`. If `origin/redesign` does not exist,
stop and ask the user to create it.

## 3. Do the work

- Follow `AGENTS.md`. Read `dev/decisions.md` before adding a package or pattern.
- If the bead builds a screen or a sheet, follow the `build-screen` skill for it.
- Stay inside the bead's scope. For anything else you find, file a bead:
  `bd create "<title>" -t task -p 2 --deps discovered-from:<id>`.
- If the bead adds or changes `supabase/migrations/`, write the migration as a
  new timestamped file and do not apply it to the hosted project.

## 4. Definition of done

Run all of these and fix what they report:

```
dart format .
flutter analyze
flutter test
tool/check_colours.sh
```

For UI changes, also:

- Add or update goldens for every touched screen in both themes
  (`flutter test --tags golden --update-goldens`, Linux only). On macOS, say in
  the PR that the goldens still need generating; do not commit macOS goldens.
- Run the `design-reviewer` agent on the touched screens and fix what it finds,
  or list what you are leaving and why.

## 5. Hand over

1. Close the bead with a note the next session can use:
   `bd close <id> --reason "<what changed, what was left out>"`.
2. Run `bd export -o .beads/issues.jsonl` so the closed bead and any beads you
   filed are part of the change.
3. Commit (including `.beads/issues.jsonl`), push the branch and open a PR
   against `redesign` using the PR template. Mention any migration.
4. Report: the bead, the PR, the check results, and what `bd ready` shows next.

If you cannot finish, do not close the bead. Leave a note with
`bd update <id> --notes "<state, what is left, what blocked you>"` so the next
session can continue.
