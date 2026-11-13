# shellcheck shell=bash
# Steam: install it first, open it so you can log in, then queue games.

STEAM_LOGIN_FILE="$HOME/Library/Application Support/Steam/config/loginusers.vdf"
STEAM_LOGIN_TIMEOUT_SECONDS=1800
STEAM_POLL_SECONDS=5
STEAM_QUEUE_DELAY_SECONDS=3

install_and_open_steam() {
  run brew install --cask steam || return 1
  run open -a Steam || return 1
  info "Steam is opening. Log in now; installs keep going in the meantime."
}

steam_logged_in() {
  [[ -f "$STEAM_LOGIN_FILE" ]] && grep -q '"MostRecent"[[:space:]]*"1"' "$STEAM_LOGIN_FILE"
}

wait_for_steam_login() {
  [[ "$DRY_RUN" == "1" ]] && return 0
  local waited=0
  until steam_logged_in; do
    if ((waited >= STEAM_LOGIN_TIMEOUT_SECONDS)); then
      warn "Timed out waiting for a Steam login."
      return 1
    fi
    ((waited % 60 == 0)) && info "Waiting for you to log into Steam..."
    sleep "$STEAM_POLL_SECONDS"
    waited=$((waited + STEAM_POLL_SECONDS))
  done
  info "Steam login detected."
}

# Prints "<app id> <name>" for every game that runs on this platform.
steam_games_for() {
  local platform="$1" id platforms name
  while read -r id platforms name; do
    [[ ",$platforms," == *",$platform,"* ]] && printf '%s %s\n' "$id" "$name"
  done < <(config_lines "$CONFIG_DIR/steam-games.txt")
}

queue_steam_games() {
  local games
  games="$(steam_games_for mac)"
  if [[ -z "$games" ]]; then
    info "No Steam games are listed for Mac."
    return 0
  fi

  if [[ "$DRY_RUN" != "1" && ! -d "/Applications/Steam.app" ]]; then
    warn "Steam is not installed, so games cannot be queued."
    return 1
  fi

  if ! wait_for_steam_login; then
    while read -r id name; do todo "Install $name in Steam: steam://install/$id"; done <<<"$games"
    return 1
  fi

  while read -r id name; do
    info "Queueing $name ($id)"
    run open "steam://install/$id"
    [[ "$DRY_RUN" == "1" ]] || sleep "$STEAM_QUEUE_DELAY_SECONDS"
  done <<<"$games"
  todo "Click Install in each Steam dialog"
}
