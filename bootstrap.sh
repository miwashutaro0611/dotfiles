#!/usr/bin/env bash
# bootstrap.sh — set up a fresh macOS machine end to end.
#
# Idempotent: re-running skips steps that are already done.

set -euo pipefail

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'; C_BLUE='\033[0;34m'; C_RESET='\033[0m'
log()  { printf "${C_BLUE}==>${C_RESET} %s\n" "$*"; }
ok()   { printf "${C_GREEN}✓${C_RESET} %s\n" "$*"; }
warn() { printf "${C_YELLOW}!${C_RESET} %s\n" "$*"; }

confirm() {
  read -r -p "$1 [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

# 1. Xcode Command Line Tools
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools..."
  xcode-select --install || true
  warn "Re-run this script after CLT installation completes."
  exit 0
else
  ok "Xcode Command Line Tools already installed"
fi

# 2. Homebrew
if ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  ok "Homebrew already installed"
fi

# 3. brew bundle
log "Installing packages from Brewfile..."
brew bundle --file="$DOTFILES_DIR/Brewfile"
ok "Brewfile installed"

# 4. Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  ok "Oh My Zsh already installed"
fi

# 5. mise activation (no-op if already in shell)
if command -v mise >/dev/null 2>&1; then
  ok "mise installed (run 'mise install' inside a project to install runtimes)"
fi

# 6. install.sh — symlinks + external repos (zsh-autosuggestions etc.)
log "Creating symlinks and cloning external repos..."
"$DOTFILES_DIR/install.sh"

# 7. macOS defaults (optional, prompt)
if confirm "Apply macOS system defaults (Finder/Dock/keyboard)?"; then
  "$DOTFILES_DIR/macos/defaults.sh"
fi

# 8. .gitconfig.local reminder
if [ ! -f "$HOME/.gitconfig.local" ]; then
  warn "Don't forget to create ~/.gitconfig.local from the template:"
  warn "  cp \"$DOTFILES_DIR/git/.gitconfig.local.example\" ~/.gitconfig.local"
fi

ok "Bootstrap complete. Open a new terminal to load your shell config."
