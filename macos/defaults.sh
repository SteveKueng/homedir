#!/usr/bin/env bash
# Optional macOS tweaks. Run via: ./setup.sh --defaults
# Add your own `defaults write` lines as you discover them (backup.sh does NOT
# capture these automatically — macOS has no clean "dump my settings").
set -euo pipefail

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true
# Show file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Don't write .DS_Store on network/USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
# Faster key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

killall Finder 2>/dev/null || true
echo "==> macOS defaults applied (some need logout/restart)."
