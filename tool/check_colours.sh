#!/usr/bin/env bash
# Fails if a Dart file outside lib/theme/ hard-codes a colour with Color(0x...)
# or Colors.*. Colours must come from AppTokens (see AGENTS.md).
#
# Files that predate the redesign are listed in tool/colour_baseline.txt and are
# skipped. Remove a file from that list when it is rebuilt; delete the list once
# it is empty.
set -euo pipefail
cd "$(dirname "$0")/.."

baseline="tool/colour_baseline.txt"
status=0

while IFS= read -r file; do
  if [ -f "$baseline" ] && grep -qxF "$file" "$baseline"; then
    continue
  fi
  echo "Hard-coded colour in $file (use context.tokens):"
  grep -nE 'Color\(0x|Colors\.' "$file" | sed 's/^/  /'
  status=1
done < <(grep -rlE 'Color\(0x|Colors\.' lib --include='*.dart' | grep -v '^lib/theme/' | sort || true)

# Keep the baseline honest: every entry must still exist and still need it.
if [ -f "$baseline" ]; then
  while IFS= read -r file; do
    case "$file" in ''|'#'*) continue ;; esac
    if [ ! -f "$file" ] || ! grep -qE 'Color\(0x|Colors\.' "$file"; then
      echo "$file no longer needs to be in $baseline; remove it."
      status=1
    fi
  done < "$baseline"
fi

exit $status
