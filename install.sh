#!/usr/bin/env bash
# install.sh — create symlinks from this repo into $HOME
#
# Usage:
#   ./install.sh             # create symlinks (backs up existing files)
#   ./install.sh --dry-run   # show planned actions without executing

set -euo pipefail

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
    --help|-h)
      sed -n '2,8p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

# Color helpers
if [ -t 1 ]; then
  C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'; C_BLUE='\033[0;34m'; C_RED='\033[0;31m'; C_RESET='\033[0m'
else
  C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_RED=''; C_RESET=''
fi

log()   { printf "${C_BLUE}[info]${C_RESET} %s\n" "$*"; }
warn()  { printf "${C_YELLOW}[warn]${C_RESET} %s\n" "$*"; }
ok()    { printf "${C_GREEN}[ ok ]${C_RESET} %s\n" "$*"; }
err()   { printf "${C_RED}[err ]${C_RESET} %s\n" "$*" >&2; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "  ${C_YELLOW}DRY${C_RESET} %s\n" "$*"
  else
    eval "$@"
  fi
}

# Mapping: "<source-relative-to-repo>::<target-absolute>"
# Files only — directories are linked as a whole.
LINKS=(
  "zsh/.zshrc::$HOME/.zshrc"
  "zsh/.zshenv::$HOME/.zshenv"
  "zsh/.zprofile::$HOME/.zprofile"

  "git/.gitconfig::$HOME/.gitconfig"
  "git/.gitignore_global::$HOME/.gitignore_global"

  "claude/settings.json::$HOME/.claude/settings.json"
  "claude/statusline.py::$HOME/.claude/statusline.py"
  "claude/statusline-command.sh::$HOME/.claude/statusline-command.sh"
  "claude/.mcp.json::$HOME/.claude/.mcp.json"
  "claude/agents::$HOME/.claude/agents"

  "codex/config.toml::$HOME/.codex/config.toml"
  "gemini/settings.json::$HOME/.gemini/settings.json"

  "ai/AGENTS.md::$HOME/AGENTS.md"

  "starship/starship.toml::$HOME/.config/starship.toml"

  "cursor/settings.json::$HOME/Library/Application Support/Cursor/User/settings.json"
  "cursor/keybindings.json::$HOME/Library/Application Support/Cursor/User/keybindings.json"
)

# External git repositories to clone into specific locations (sourced by .zshrc etc.)
# Format: "<git-url>::<target-path>"
EXTERNAL_REPOS=(
  "https://github.com/zsh-users/zsh-autosuggestions::$HOME/.zsh/zsh-autosuggestions"
)

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mkdir -p "$BACKUP_DIR"
    local rel="${target#$HOME/}"
    local backup_path="$BACKUP_DIR/$rel"
    run "mkdir -p \"$(dirname "$backup_path")\""
    run "mv \"$target\" \"$backup_path\""
    warn "backed up: $target -> $backup_path"
  fi
}

clone_repo() {
  local url="$1" target="$2"

  if [ -d "$target/.git" ]; then
    ok "repo present: $target"
    return 0
  fi

  if [ -e "$target" ]; then
    err "target exists but is not a git repo: $target"
    return 1
  fi

  if ! command -v git >/dev/null 2>&1; then
    err "git not found — install it first (brew install git)"
    return 1
  fi

  run "mkdir -p \"$(dirname "$target")\""
  run "git clone --depth=1 \"$url\" \"$target\""
  ok "cloned: $url -> $target"
}

create_link() {
  local src="$1" target="$2"

  if [ ! -e "$src" ]; then
    err "source does not exist: $src"
    return 1
  fi

  # Already correct symlink → skip
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
    ok "linked: $target"
    return 0
  fi

  run "mkdir -p \"$(dirname "$target")\""
  backup_if_exists "$target"

  # Replace existing symlink (if pointing elsewhere) atomically
  run "ln -snf \"$src\" \"$target\""
  ok "linked: $target -> $src"
}

main() {
  log "dotfiles dir: $DOTFILES_DIR"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY RUN — no changes will be made"
  fi

  for entry in "${LINKS[@]}"; do
    local src_rel="${entry%%::*}"
    local target="${entry#*::}"
    local src="$DOTFILES_DIR/$src_rel"
    create_link "$src" "$target"
  done

  for entry in "${EXTERNAL_REPOS[@]}"; do
    local url="${entry%%::*}"
    local target="${entry#*::}"
    clone_repo "$url" "$target"
  done

  if [ -d "$BACKUP_DIR" ]; then
    log "existing files backed up to: $BACKUP_DIR"
  fi

  if [ ! -f "$HOME/.gitconfig.local" ]; then
    warn "~/.gitconfig.local not found"
    warn "  cp \"$DOTFILES_DIR/git/.gitconfig.local.example\" ~/.gitconfig.local"
    warn "  then edit user.name / user.email"
  fi

  ok "done"
}

main "$@"
