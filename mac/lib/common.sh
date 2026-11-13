# shellcheck shell=bash
# Shared helpers for the Mac setup scripts. Sourced, not executed.

DRY_RUN="${DRY_RUN:-0}"
FAILURES=()
CHECKLIST=()

log()  { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# Run a command, or only print it when DRY_RUN=1.
run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '    [dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

# Run one step; record it as failed instead of aborting the whole setup.
step() {
  local name="$1"; shift
  log "$name"
  if ! "$@"; then
    warn "$name failed (continuing)"
    FAILURES+=("$name")
  fi
}

todo() { CHECKLIST+=("$*"); }

# Print config lines without comments or blank lines.
config_lines() {
  grep -vE '^[[:space:]]*(#|$)' "$1"
}

# Ask a question on the terminal even when the script is piped into bash.
ask() {
  local prompt="$1" reply=""
  if [[ "$DRY_RUN" == "1" ]] || [[ ! -r /dev/tty ]]; then
    return 0
  fi
  read -r -p "$prompt" reply </dev/tty || true
  printf '%s' "$reply"
}

print_summary() {
  log "Done"
  if ((${#FAILURES[@]})); then
    warn "Steps that failed (re-run setup to retry, it skips what is already installed):"
    printf '    - %s\n' "${FAILURES[@]}" >&2
  else
    info "Every step succeeded."
  fi
  if ((${#CHECKLIST[@]})); then
    log "Your checklist"
    printf '    [ ] %s\n' "${CHECKLIST[@]}"
  fi
}
