#!/usr/bin/env bash
#
# Install LaTeX packages and set up TeX directory structure
# Can be run standalone or called from bootstrap.sh
#
# Usage: tlmgr.sh [tex_directory]
#   If tex_directory is not provided, you will be prompted.
#

set -euo pipefail

echo "Installing TeX packages..."

# Ensure tlmgr is in PATH (BasicTeX location)
export PATH="/Library/TeX/texbin:$PATH"

if ! command -v tlmgr >/dev/null 2>&1; then
    echo "Error: tlmgr not found. Please install BasicTeX first."
    echo "  brew install --cask basictex"
    exit 1
fi

# Get TeX directory from argument or prompt
if [[ $# -ge 1 ]]; then
    texdir="$1"
else
    read -r -p "Choose a directory for your TeX supporting files: " texdir
fi

# Expand tilde
texdir="${texdir/#\~/$HOME}"

if [[ -z "$texdir" ]]; then
    echo "Error: No directory specified."
    exit 1
fi

echo ""
echo "Updating TeX Live..."
sudo tlmgr update --self --all || echo "Warning: Some updates may have failed"

echo ""
echo "Installing TeX packages..."
sudo tlmgr install scheme-medium collection-humanities collection-langgreek \
    collection-langother collection-latexextra collection-pictures logreq \
    biblatex biber || echo "Warning: Some packages may have failed"

echo ""
echo "Setting up directory structure in: $texdir"
mkdir -pv "${texdir%/}/Classes"
mkdir -pv "${texdir%/}/Packages"
mkdir -pv "${texdir%/}/Bibliography"
mkdir -pv ~/Library/texmf/tex/latex
mkdir -pv ~/Library/texmf/bibtex

echo ""
echo "Cloning custom TeX repositories..."
if [[ ! -d "${texdir%/}/Classes/dbmrq" ]]; then
    git clone https://github.com/dbmrq/tex-dbmrq.git "${texdir%/}/Classes/dbmrq"
else
    echo "  dbmrq already exists, skipping"
fi

if [[ ! -d "${texdir%/}/Packages/biblatex-abnt" ]]; then
    git clone https://github.com/abntex/biblatex-abnt.git "${texdir%/}/Packages/biblatex-abnt"
else
    echo "  biblatex-abnt already exists, skipping"
fi

echo ""
echo "Creating symlinks..."
ln -sfv "${texdir%/}/Classes" ~/Library/texmf/tex/latex/classes
ln -sfv "${texdir%/}/Packages" ~/Library/texmf/tex/latex/packages
ln -sfv "${texdir%/}/Bibliography" ~/Library/texmf/bibtex/bib

echo ""
echo "Done."
