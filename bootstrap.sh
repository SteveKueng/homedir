#!/usr/bin/env bash
# One-liner bootstrap for a fresh Mac:
#   curl -fsSL https://raw.githubusercontent.com/SteveKueng/homedir/main/bootstrap.sh | bash
# Pass setup flags after --, e.g.:  ... | bash -s -- --defaults
set -euo pipefail

DEST="$HOME/Git/homedir"

if ! command -v git >/dev/null 2>&1; then
  echo "Installing Xcode Command Line Tools (provides git)…"
  xcode-select --install || true
  echo "Re-run this command once the install finishes."
  exit 1
fi

if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only
else
  mkdir -p "$(dirname "$DEST")"
  git clone https://github.com/SteveKueng/homedir.git "$DEST"
fi

exec "$DEST/setup.sh" "$@"
