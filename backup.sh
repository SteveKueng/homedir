#!/usr/bin/env bash
# Pull current config from the live system into the repo and commit.
# Idempotent — if nothing changed, it just says so. Does NOT push.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"

# --- 1. Brewfile --------------------------------------------------------------
echo "==> brew bundle dump"
brew bundle dump --force --file="$REPO/Brewfile"

# --- 2. Dotfiles --------------------------------------------------------------
# Normally symlinked into $HOME, so edits are already in the repo. If a dotfile
# is still a real file (repo not yet applied), pull a portable copy.
for f in .zshrc .zprofile .zshenv .gitconfig; do
  if [ -f "$HOME/$f" ] && [ ! -L "$HOME/$f" ]; then
    sed "s|$HOME|\$HOME|g" "$HOME/$f" > "home/$f"   # ponytail: genericize home path
    echo "    captured $f"
  fi
done

# --- 3. Claude settings -------------------------------------------------------
# Copy live settings.json but rewrite the statusLine command to a portable form
# (no username, no plugin version) so nothing hardcoded gets committed.
if [ -f "$HOME/.claude/settings.json" ]; then
  echo "==> Claude settings"
  CMD='bash "$(ls -t "$HOME"/.claude/plugins/cache/ponytail/ponytail/*/hooks/ponytail-statusline.sh 2>/dev/null | head -1)"'
  jq --arg cmd "$CMD" \
     'if .statusLine.command then .statusLine.command = $cmd else . end' \
     "$HOME/.claude/settings.json" > "claude/settings.json"
fi

# --- 4. Commit (no push) ------------------------------------------------------
git add -A
if git diff --cached --quiet; then
  echo "==> Nothing changed."
else
  git commit -m "backup: $(date '+%Y-%m-%d %H:%M')"
  echo "==> Committed. Run 'git push' yourself when ready."
fi
