#!/usr/bin/env bash

echo "Installing TeX packages..."

sudo tlmgr update --self --all
sudo tlmgr install scheme-medium collection-humanities collection-langgreek \
    collection-langother collection-latexextra collection-pictures logreq \
    biblatex biber

read -p "Choose a directory for your TeX supporting files: " texdir
echo

mkdir -pv "${texdir%/}/Classes"
mkdir -pv "${texdir%/}/Packages"
mkdir -pv "${texdir%/}/Bibliography"
mkdir -pv ~/Library/texmf/tex/latex
mkdir -pv ~/Library/texmf/bibtex

git clone https://github.com/dbmrq/tex-dbmrq.git "${texdir%/}/Classes/dbmrq"
git clone https://github.com/abntex/biblatex-abnt.git "${texdir%/}/Packages/biblatex-abnt"

ln -s "${texdir%/}/Classes" ~/Library/texmf/tex/latex/classes
ln -s "${texdir%/}/Packages" ~/Library/texmf/tex/latex/packages
ln -s "${texdir%/}/Bibliography" ~/Library/texmf/bibtex/bib

echo "Done."
