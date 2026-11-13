# shellcheck shell=bash
# Install Homebrew (also installs the Xcode Command Line Tools).

HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

brew_prefix() {
  if [[ "$(uname -m)" == "arm64" ]]; then echo /opt/homebrew; else echo /usr/local; fi
}

install_homebrew() {
  local prefix
  prefix="$(brew_prefix)"

  if ! command -v brew >/dev/null 2>&1 && [[ ! -x "$prefix/bin/brew" ]]; then
    run env NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALL_URL")" || return 1
  else
    info "Homebrew already installed."
  fi

  if [[ "$DRY_RUN" != "1" ]]; then
    eval "$("$prefix/bin/brew" shellenv)" || return 1
    # Make brew available in new terminals too.
    local line="eval \"\$($prefix/bin/brew shellenv)\""
    grep -qxF "$line" "$HOME/.zprofile" 2>/dev/null || printf '%s\n' "$line" >>"$HOME/.zprofile"
  fi
}
