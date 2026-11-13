#!/usr/bin/env bash
# Mac setup. Usually started by install.sh; can also be run directly:
#   bash mac/setup.sh            install everything
#   bash mac/setup.sh --dry-run  print what would happen, change nothing
set -uo pipefail

MAC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$MAC_DIR/../config" && pwd)"
export MAC_DIR CONFIG_DIR

for arg in "$@"; do
  case "$arg" in
    --dry-run) export DRY_RUN=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

# shellcheck source=lib/common.sh
source "$MAC_DIR/lib/common.sh"
for file in "$MAC_DIR"/steps/*.sh; do
  # shellcheck source=/dev/null
  source "$file"
done

preflight() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script is for macOS. On Windows run install.ps1." >&2
    exit 1
  fi
  if [[ "$EUID" -eq 0 ]]; then
    echo "Run this as your normal user, not with sudo." >&2
    exit 1
  fi
  [[ "$DRY_RUN" == "1" ]] && { log "Dry run: nothing will be installed"; return 0; }

  log "Asking for your password once (needed by Homebrew and app installers)"
  sudo -v </dev/tty || exit 1
  # Keep sudo alive until this script exits.
  while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
}

main() {
  preflight
  step "Homebrew"                 install_homebrew
  step "Steam (log in when it opens)" install_and_open_steam
  step "Apps from Brewfile"       install_brewfile
  step "Dia"                      install_dia
  step "Navi"                     install_navi
  step "Default browser: Dia"     set_default_browser
  step "Claude Code skills"       install_skills
  step "Queue Steam games"        queue_steam_games

  todo "Log into: Slack, Discord, Spotify, Tailscale, Claude, ChatGPT/Codex, Dia"
  todo "Run 'claude' once in a terminal to log into Claude Code"
  todo "Grant BetterTouchTool, Navi and Logitech G HUB their permissions in System Settings > Privacy & Security"
  print_summary
}

main
