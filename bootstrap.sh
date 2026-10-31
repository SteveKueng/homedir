#!/usr/bin/env bash
# One-liner bootstrap for a fresh Mac:
#   curl -fsSL https://www.ikueng.ch/install | bash
# Pass setup flags after --, e.g.:  ... | bash -s -- --no-defaults
set -euo pipefail

# Wrapped in main so a truncated download never runs half a script.
main() {
  local dest="$HOME/Git/homedir"

  if [ "$(uname -m)" != "arm64" ]; then
    echo "Apple Silicon only." >&2
    exit 1
  fi

  # /usr/bin/git exists on every Mac as a stub; xcode-select -p tells the truth.
  if ! xcode-select -p >/dev/null 2>&1; then
    echo "==> Installing Xcode Command Line Tools — confirm the dialog."
    xcode-select --install || true
    until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  fi

  if [ -d "$dest/.git" ]; then
    git -C "$dest" pull --ff-only
  else
    mkdir -p "$HOME/Git"
    git clone https://github.com/SteveKueng/homedir.git "$dest"
  fi

  # stdin is the curl pipe; give setup the terminal so sudo/ssh-keygen can prompt.
  exec "$dest/setup.sh" "$@" </dev/tty
}

main "$@"
