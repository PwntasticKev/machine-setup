# shellcheck shell=bash
# Claude Code skills, installed globally into ~/.claude/skills.

install_skills() {
  if ! command -v npx >/dev/null 2>&1 && [[ "$DRY_RUN" != "1" ]]; then
    warn "npx not found; Node did not install."
    return 1
  fi

  local repo failed=0
  while read -r repo; do
    info "Installing skills from $repo"
    run npx -y skills@latest add "$repo" --global --agent claude-code --skill '*' --yes </dev/null || {
      warn "Skills from $repo failed"
      failed=1
    }
  done < <(config_lines "$CONFIG_DIR/skills.txt")
  return "$failed"
}
