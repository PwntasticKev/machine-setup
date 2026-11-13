#!/usr/bin/env bash
# One-line Mac bootstrap:
#   curl -fsSL https://raw.githubusercontent.com/PwntasticKev/machine-setup/main/install.sh | bash
# Downloads this repo (no git needed on a fresh Mac) and runs mac/setup.sh.
set -euo pipefail

REPO="PwntasticKev/machine-setup"
BRANCH="${MACHINE_SETUP_BRANCH:-main}"
DEST="${MACHINE_SETUP_DIR:-$HOME/.machine-setup}"
ARCHIVE_URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This installer is for macOS. On Windows run install.ps1 instead." >&2
  exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "==> Downloading $REPO ($BRANCH)"
curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$work"

rm -rf "$DEST"
mv "$work/machine-setup-$BRANCH" "$DEST"

# Under `curl | bash`, stdin is the script itself; give setup the keyboard instead.
if { : </dev/tty; } 2>/dev/null; then
  bash "$DEST/mac/setup.sh" "$@" </dev/tty
else
  bash "$DEST/mac/setup.sh" "$@"
fi
