# shellcheck shell=bash
# Mac apps: everything in the Brewfile, plus Dia and Navi (not in Homebrew).

DIA_DMG_URL="https://releases.diabrowser.com/release/Dia-latest.dmg"
NAVI_ZIP_URL="https://github.com/donovanhiland/navi/releases/latest/download/Navi.zip"
APPLICATIONS_DIR="/Applications"

install_brewfile() {
  run brew bundle --file="$MAC_DIR/Brewfile"
}

install_dia() {
  if [[ -d "$APPLICATIONS_DIR/Dia.app" ]]; then
    info "Dia already installed."
    return 0
  fi
  [[ "$DRY_RUN" == "1" ]] && { info "[dry-run] download and copy Dia.app"; return 0; }

  local work mount
  work="$(mktemp -d)" || return 1
  mount="$work/mount"
  mkdir -p "$mount" || return 1
  curl -fL --progress-bar -o "$work/Dia.dmg" "$DIA_DMG_URL" || return 1
  hdiutil attach "$work/Dia.dmg" -nobrowse -quiet -mountpoint "$mount" || return 1
  cp -R "$mount/Dia.app" "$APPLICATIONS_DIR/"
  local copied=$?
  hdiutil detach "$mount" -quiet
  rm -rf "$work"
  return "$copied"
}

install_navi() {
  if [[ -d "$APPLICATIONS_DIR/Navi.app" ]]; then
    info "Navi already installed."
    return 0
  fi
  [[ "$DRY_RUN" == "1" ]] && { info "[dry-run] download and copy Navi.app"; return 0; }

  local work
  work="$(mktemp -d)" || return 1
  curl -fL --progress-bar -o "$work/Navi.zip" "$NAVI_ZIP_URL" || return 1
  ditto -x -k "$work/Navi.zip" "$work" || return 1
  mv "$work/Navi.app" "$APPLICATIONS_DIR/" || return 1
  rm -rf "$work"
}

set_default_browser() {
  if ! command -v defaultbrowser >/dev/null 2>&1; then
    [[ "$DRY_RUN" == "1" ]] && { info "[dry-run] defaultbrowser dia"; return 0; }
    warn "defaultbrowser is not installed."
    return 1
  fi
  run defaultbrowser dia || return 1
  todo "Confirm \"Use Dia\" in the macOS default browser dialog"
}
