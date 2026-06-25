#!/usr/bin/env bash
# Set up a fresh Mac from this repo. Idempotent — safe to re-run.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- 1. Homebrew --------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# ponytail: Apple Silicon brew path; setup is mac-only
eval "$(/opt/homebrew/bin/brew shellenv)"

# --- 2. oh-my-zsh (.zshrc sources it, would error if missing) -----------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> Installing oh-my-zsh"
  RUNZSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# --- 3. Brew bundle (CLI tools, casks, VSCode extensions) ---------------------
echo "==> brew bundle"
brew bundle --file="$REPO/Brewfile"

# --- 4. Symlink dotfiles into $HOME -------------------------------------------
# Existing real files are backed up once to *.pre-homedir.bak.
link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$dest.pre-homedir.bak"
    echo "    backed up existing $dest -> $dest.pre-homedir.bak"
  fi
  ln -sfn "$src" "$dest"
}
echo "==> Linking dotfiles"
for f in .zshrc .zprofile .zshenv .gitconfig .gitignore_global; do
  link "$REPO/home/$f" "$HOME/$f"
done
git config --global core.excludesfile "$HOME/.gitignore_global"

# --- 5. Claude Code settings (copy, not symlink — keeps repo portable) --------
echo "==> Claude settings"
mkdir -p "$HOME/.claude"
cp "$REPO/claude/settings.json" "$HOME/.claude/settings.json"

# --- 6. macOS defaults (optional: ./setup.sh --defaults) ----------------------
if [ "${1:-}" = "--defaults" ]; then
  echo "==> macOS defaults"
  bash "$REPO/macos/defaults.sh"
fi

cat <<'EOF'

==> Done.
Manual steps (see README): App Store apps, app logins, SSH keys, ~/.zshrc.local.
Open a new terminal so the shell config takes effect.
EOF
