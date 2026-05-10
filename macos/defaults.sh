#!/usr/bin/env bash
# macos/defaults.sh — apply preferred macOS system settings.
#
# Run after install.sh on a new machine. Some changes require logout / restart.

set -euo pipefail

if [ "$(uname)" != "Darwin" ]; then
  echo "This script is for macOS only." >&2
  exit 1
fi

echo "Applying macOS defaults..."

# ─── Finder ──────────────────────────────────────────────
# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true
# Show path bar
defaults write com.apple.finder ShowPathbar -bool true
# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true
# Default to list view
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
# Disable warning when changing file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# ─── Dock ────────────────────────────────────────────────
# Auto-hide
defaults write com.apple.dock autohide -bool true
# Reduce auto-hide delay
defaults write com.apple.dock autohide-delay -float 0
# Speed up animation
defaults write com.apple.dock autohide-time-modifier -float 0.4
# Don't rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# ─── Keyboard ────────────────────────────────────────────
# Fast key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Disable press-and-hold for accent characters in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# ─── Trackpad ────────────────────────────────────────────
# Tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# ─── Screenshots ─────────────────────────────────────────
mkdir -p "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture location "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture type -string "png"

# ─── Misc ────────────────────────────────────────────────
# Disable .DS_Store on network / USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ─── Apply ───────────────────────────────────────────────
echo "Restarting affected applications (Finder, Dock, SystemUIServer)..."
for app in Finder Dock SystemUIServer; do
  killall "$app" >/dev/null 2>&1 || true
done

echo "Done. Some changes may require a logout / restart to take effect."
