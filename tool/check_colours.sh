#!/usr/bin/env bash
# Fails if a Dart file outside lib/theme/ hard-codes a colour with Color(0x...)
# or Colors.*. Colours must come from AppTokens (see AGENTS.md).
set -euo pipefail
cd "$(dirname "$0")/.."

status=0

while IFS= read -r file; do
  echo "Hard-coded colour in $file (use context.tokens):"
  grep -nE 'Color\(0x|Colors\.' "$file" | sed 's/^/  /'
  status=1
done < <(grep -rlE 'Color\(0x|Colors\.' lib --include='*.dart' | grep -v '^lib/theme/' | sort || true)

exit $status
