#!/usr/bin/env bash
# Set up a Mac from this repo. Idempotent — safe to re-run.
#   --no-defaults  skip macOS defaults
#   --force        re-apply one-time steps (Dock layout, Vorssaint import)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Private config (kubeconfig, Claude settings, Vorssaint) lives in iCloud Drive, not in this public repo.
ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
PRIV="$ICLOUD/homedir"
STATE="$HOME/.config/homedir"     # markers for one-time steps
VORSSAINT=/Applications/Vorssaint.app/Contents/MacOS/Vorssaint
export GH_PAGER=cat               # no `less` popping up mid-setup

NO_DEFAULTS=0 FORCE=0
for a in "$@"; do
  case "$a" in
    --no-defaults) NO_DEFAULTS=1 ;;
    --force) FORCE=1 ;;
    *) echo "unknown flag: $a" >&2; exit 1 ;;
  esac
done
mkdir -p "$STATE"
once() { [ "$FORCE" = 1 ] || [ ! -e "$STATE/$1" ]; }

# --- 1. sudo once, keep it alive until we exit --------------------------------
echo "==> sudo (asked once)"
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

# --- 2. Computer name (also used as SSH key title) ----------------------------
NAME="$(scutil --get ComputerName)"
read -rp "Computer name [$NAME]: " input
NAME="${input:-$NAME}"
HOST="$(printf '%s' "$NAME" | tr ' ' '-' | tr -cd 'A-Za-z0-9-')"
sudo scutil --set ComputerName "$NAME"
sudo scutil --set HostName "$HOST"
sudo scutil --set LocalHostName "$HOST"

# --- 3. Apple Account + iCloud Drive (required for private config) ------------
until [ -d "$ICLOUD" ]; do
  echo "==> Sign in to your Apple Account and turn on iCloud Drive."
  open "x-apple.systempreferences:com.apple.systempreferences.AppleIDSettings" \
    || open -b com.apple.systempreferences
  read -rp "Press Enter when done… "
done

# --- 4. Homebrew + oh-my-zsh --------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> Installing oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "==> brew bundle"
# mas apps fail when not signed in to the App Store — don't abort the rest.
brew bundle --file="$REPO/Brewfile" || echo "    !! brew bundle had errors (App Store sign-in?) — re-run later"

# --- 5. Symlinks --------------------------------------------------------------
# Existing real files are backed up once to *.pre-homedir.bak.
link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$dest.pre-homedir.bak"
    echo "    backed up $dest -> $dest.pre-homedir.bak"
  fi
  ln -sfn "$src" "$dest"
}

echo "==> Linking dotfiles"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
for f in .zshrc .zprofile .gitconfig .gitignore_global .ssh/config; do
  link "$REPO/home/$f" "$HOME/$f"
done

# Link a file from iCloud. If iCloud has none yet but this Mac does, seed iCloud with it.
private_link() {
  local src="$PRIV/$1" dest="$2"
  mkdir -p "$(dirname "$src")"
  if [ ! -e "$src" ] && [ -f "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$src"
    echo "    moved $dest into iCloud"
  fi
  # Fresh Mac: iCloud may still be syncing.
  local i=0
  while [ ! -e "$src" ] && [ $i -lt 12 ]; do sleep 5; i=$((i + 1)); done
  if [ ! -e "$src" ]; then
    echo "    !! $src not in iCloud yet — re-run setup later"
    return 0
  fi
  brctl download "$src" 2>/dev/null || true
  link "$src" "$dest"
}

echo "==> Linking private config from iCloud"
private_link kube/config "$HOME/.kube/config"
chmod 700 "$HOME/.kube"
private_link claude/settings.json "$HOME/.claude/settings.json"

# --- 6. Vorssaint settings (one-time; save changes with `homedir-save`) -------
if [ -x "$VORSSAINT" ] && [ -f "$PRIV/vorssaint.plist" ] && once vorssaint; then
  echo "==> Importing Vorssaint settings"
  osascript -e 'quit app "Vorssaint"' 2>/dev/null || true
  sleep 2
  "$VORSSAINT" --import-settings "$PRIV/vorssaint.plist"
  open -a Vorssaint
  touch "$STATE/vorssaint"
fi

# --- 7. GitHub login + SSH key ------------------------------------------------
echo "==> GitHub"
gh auth status >/dev/null 2>&1 \
  || gh auth login --web --git-protocol https --scopes admin:public_key
# Captured, not piped: grep -q + pipefail would misreport on SIGPIPE.
case "$(gh auth status 2>&1)" in
  *admin:public_key*) ;;
  *) gh auth refresh -h github.com --scopes admin:public_key ;;
esac

KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$KEY" ]; then
  echo "    generating SSH key (choose a passphrase — stored in Keychain)"
  ssh-keygen -t ed25519 -C "$NAME" -f "$KEY"
fi
ssh-add --apple-use-keychain "$KEY" 2>/dev/null || true
if ! grep -qxF "$(cut -d' ' -f1,2 "$KEY.pub")" <<<"$(gh api user/keys --jq '.[].key')"; then
  gh ssh-key add "$KEY.pub" --title "$NAME"
fi

# --- 8. Security --------------------------------------------------------------
echo "==> Security"
# sudo_local survives macOS updates (unlike editing /etc/pam.d/sudo).
grep -q pam_tid /etc/pam.d/sudo_local 2>/dev/null \
  || echo "auth       sufficient     pam_tid.so" | sudo tee -a /etc/pam.d/sudo_local >/dev/null
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on >/dev/null
fdesetup isactive >/dev/null || echo "    !! FileVault is OFF — turn it on in System Settings > Privacy & Security"

# --- 9. macOS defaults + Dock -------------------------------------------------
[ "$NO_DEFAULTS" = 1 ] || bash "$REPO/macos/defaults.sh"

if once dock; then
  echo "==> Dock"
  # Via `defaults` (cfprefsd), not dockutil: editing the plist file directly gets
  # overwritten by cfprefsd's cached copy right after defaults.sh touched the Dock.
  defaults write com.apple.dock persistent-apps -array
  for app in \
    "/Applications/Microsoft Edge.app" \
    /Applications/Safari.app \
    /System/Applications/Mail.app \
    /System/Applications/Calendar.app \
    /System/Applications/Notes.app \
    /System/Applications/Utilities/Terminal.app \
    "/Applications/Visual Studio Code.app" \
    /Applications/Claude.app \
    "/System/Applications/System Settings.app"; do
    [ -e "$app" ] || continue
    app="$(realpath "$app")"   # Safari is a symlink into a Cryptex
    defaults write com.apple.dock persistent-apps -array-add \
      "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
  done
  killall Dock
  touch "$STATE/dock"
fi

# --- 10. Permissions that can't be scripted (TCC) -----------------------------
if once permissions; then
  echo "==> Grant Vorssaint: Accessibility + Screen Recording"
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
  touch "$STATE/permissions"
fi

echo
echo "==> SSH keys on your GitHub account (delete old Macs at github.com/settings/keys):"
# Not `gh ssh-key list`: it also queries signing keys, which needs an extra scope.
gh api user/keys --jq '.[] | "    \(.title)\t\(.created_at[:10])"'

echo
echo "==> Done. A restart is needed for keyboard shortcuts and some defaults."
read -rp "Restart now? [y/N] " answer
case "$answer" in
  [yY]*) sudo shutdown -r now ;;
  *) echo "    Restart later. Open a new terminal meanwhile." ;;
esac
