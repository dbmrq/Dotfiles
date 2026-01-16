#!/usr/bin/env bash
#
# Symlink dotfiles to home directory using GNU Stow
# Can be run standalone or called from bootstrap.sh
#

set -euo pipefail

# Get the dotfiles directory (parent of Bootstrap)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

echo "Symlinking dotfiles from: $DOTFILES_DIR"

if ! command -v stow >/dev/null 2>&1; then
    echo "Error: stow is not installed."
    echo "  brew install stow"
    exit 1
fi

cd "$DOTFILES_DIR"

# Get all directories (package folders for stow), excluding Bootstrap
packages=()
for dir in */; do
    [[ "$dir" == "Bootstrap/" ]] && continue
    packages+=("${dir%/}")
done

if [[ ${#packages[@]} -eq 0 ]]; then
    echo "No packages found to stow."
    exit 0
fi

echo "Stowing packages: ${packages[*]}"
stow -v --target="$HOME" --ignore='\.DS_Store' "${packages[@]}"

echo ""
echo "Done."
