#!/usr/bin/env bash
# SessionStart hook. In Claude Code cloud sessions it installs the pinned
# Flutter SDK and bd (beads) if they are missing, fetches packages and prints
# the beads workflow context. On a local machine it does nothing.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"

# Setup output goes to stderr so that stdout carries only the context for Claude.
log() { echo "[session-start] $*" >&2; }

# The pinned version is `environment.flutter` in pubspec.yaml.
FLUTTER_VERSION="$(awk '
  /^environment:/ { in_env = 1; next }
  /^[^[:space:]#]/ { in_env = 0 }
  in_env && /^[[:space:]]+flutter:/ { gsub(/["'\'' ]/, "", $2); print $2; exit }
' pubspec.yaml)"
if [ -z "$FLUTTER_VERSION" ]; then
  log "no environment.flutter in pubspec.yaml"
  exit 1
fi

FLUTTER_HOME="$HOME/flutter"
export PATH="$FLUTTER_HOME/bin:$HOME/.local/bin:$PATH"

installed_flutter_version() {
  cat "$FLUTTER_HOME/version" 2>/dev/null || true
}

if [ "$(installed_flutter_version)" != "$FLUTTER_VERSION" ]; then
  log "installing Flutter $FLUTTER_VERSION"
  rm -rf "$FLUTTER_HOME"
  git clone --quiet --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_HOME" >&2
  flutter config --no-analytics >&2 || true
  flutter precache --universal >&2
  echo "$FLUTTER_VERSION" > "$FLUTTER_HOME/version"
fi

if ! command -v bd >/dev/null 2>&1; then
  log "installing bd"
  npm install -g @beads/bd >&2 ||
    curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash >&2 ||
    log "could not install bd; task tracking is unavailable this session"
fi

# Make the tools available to every later command in the session.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$FLUTTER_HOME/bin:\$HOME/.local/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

log "flutter pub get"
flutter pub get >&2

if command -v bd >/dev/null 2>&1 && [ -f .beads/issues.jsonl ]; then
  # The Dolt database is not in git. A fresh clone rebuilds it from the
  # committed JSONL export; an existing one picks up issues merged since.
  if [ ! -d .beads/embeddeddolt ]; then
    head_before="$(git rev-parse HEAD)"
    bd --sandbox init --prefix fit --non-interactive --skip-agents --skip-hooks --from-jsonl >&2 ||
      log "bd init failed; task tracking is unavailable this session"
    # bd init commits its files. Sessions must not gain commits they did not make.
    if [ "$(git rev-parse HEAD)" != "$head_before" ]; then
      git reset --soft "$head_before" >&2
    fi
  else
    bd --sandbox import .beads/issues.jsonl >&2 || true
  fi
  bd prime || true
fi
