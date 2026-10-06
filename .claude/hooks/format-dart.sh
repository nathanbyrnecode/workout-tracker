#!/usr/bin/env bash
# PostToolUse hook for Edit/Write: formats the edited file if it is Dart.
# Never blocks: a missing SDK or a syntax error mid-edit is not a failure here.
input="$(cat)"

if command -v jq >/dev/null 2>&1; then
  file="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"
else
  file="$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input", {}).get("file_path", ""))' 2>/dev/null)"
fi

case "$file" in
  *.g.dart) exit 0 ;;
  *.dart) ;;
  *) exit 0 ;;
esac

[ -f "$file" ] || exit 0
command -v dart >/dev/null 2>&1 || exit 0
dart format "$file" >/dev/null 2>&1 || true
exit 0
