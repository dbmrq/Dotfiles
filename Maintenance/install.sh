#!/usr/bin/env bash
#
# Install or remove the dev-clean launchd job.
#
# The executable is copied (not symlinked) to ~/.local/bin because macOS TCC
# blocks launchd jobs from opening files under ~/Documents. The dotfiles copy
# remains the source of truth; re-run this script after editing it.
#
# Usage:
#   ./install.sh            # install/update the script and weekly job
#   ./install.sh --uninstall
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABEL="top.abacate.dev-clean"
BIN="$HOME/.local/bin/dev-clean"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
SOURCE="$SCRIPT_DIR/dev-clean"
SOURCE_PLIST="$SCRIPT_DIR/Library/LaunchAgents/$LABEL.plist"
UID_NUM="$(id -u)"

if [[ "${1:-}" == "--uninstall" ]]; then
    launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
    rm -f "$PLIST" "$BIN"
    echo "Removed $LABEL and $BIN"
    exit 0
fi

[[ -f "$SOURCE" ]] || { echo "missing $SOURCE" >&2; exit 1; }
[[ -f "$SOURCE_PLIST" ]] || { echo "missing $SOURCE_PLIST" >&2; exit 1; }

mkdir -p "$HOME/.local/bin" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
install -m 755 "$SOURCE" "$BIN"
sed "s|__HOME__|$HOME|g" "$SOURCE_PLIST" > "$PLIST"
chmod 644 "$PLIST"

launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID_NUM" "$PLIST"
launchctl enable "gui/$UID_NUM/$LABEL"

echo "Installed $LABEL"
echo "  executable: $BIN"
echo "  plist:      $PLIST"
echo "  log:        $HOME/Library/Logs/dev-clean.log"
echo
echo "Preview:   dev-clean --dry-run"
echo "Workspace: dev-clean --only ralph,swift-build   # from a terminal (TCC)"
