#!/usr/bin/env bash
# macOS defaults. Run by setup.sh (skip with --no-defaults). Idempotent.
# Add a `defaults write` line here when you change a setting you want on every Mac.
set -euo pipefail
echo "==> macOS defaults"

# --- Finder -------------------------------------------------------------------
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv        # list view
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string SCcf        # search current folder
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder NewWindowTarget -string PfHm             # new window = home
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# --- Dock (apps are set once by setup.sh) -------------------------------------
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 49
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false

# --- Keyboard -----------------------------------------------------------------
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2                 # Tab moves through all controls

# --- Trackpad / mouse ---------------------------------------------------------
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1   # login screen
defaults write NSGlobalDomain com.apple.mouse.scaling -float 3
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3

# --- Energy (minutes; 0 = never) ----------------------------------------------
# Power adapter: display off after 60 min, Mac never sleeps, wake for network.
sudo pmset -c displaysleep 60 sleep 0 womp 1 powernap 1 lowpowermode 0
# Battery (laptops only): display off after 2 min, sleep allowed, dim, Low Power Mode.
if pmset -g batt | grep -q InternalBattery; then
  sudo pmset -b displaysleep 2 sleep 1 powernap 1 lowpowermode 1 lessbright 1
fi

# --- Screen saver + lock ------------------------------------------------------
defaults -currentHost write com.apple.screensaver idleTime -int 900     # 15 min
# Password 5 s after screen saver / display sleep. Not scriptable: askForPassword
# is ignored on modern macOS and `sysadminctl -screenLock` fails (MKBDeviceSetGracePeriod -14).
case "$(sysadminctl -screenLock status 2>&1)" in
  *"5 seconds"*) ;;
  *) echo "    !! set \"Require password\" to 5 seconds in the Lock Screen settings (opening)"
     open "x-apple.systempreferences:com.apple.Lock-Screen-Settings.extension" ;;
esac

# --- Shortcuts: screenshots are handled by Vorssaint --------------------------
# 28/29 = ⌘⇧3 file/clipboard, 30/31 = ⌘⇧4 file/clipboard, 184 = ⌘⇧5
for id in 28 29 30 31 184; do
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
    -dict-add "$id" "<dict><key>enabled</key><false/></dict>"
done
# ponytail: undocumented; reliable fallback is logging out once
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true

killall Finder Dock SystemUIServer 2>/dev/null || true
