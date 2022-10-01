#!/usr/bin/env bash

# TeX {{{1

echo ""
echo "Installing tex packages"
echo ""

sudo tlmgr update --self --all

sudo tlmgr install scheme-medium collection-humanities collection-langgreek \
collection-langother collection-latexextra collection-pictures logreq \
biblatex biber

mkdir -pv ~/Code/LaTeX/Bibliography
mkdir -pv ~/Code/LaTeX/Classes
mkdir -pv ~/Code/LaTeX/Packages
mkdir -pv ~/Library/texmf/tex/latex
mkdir -pv ~/Library/texmf/bibtex

git clone https://github.com/dbmrq/tex-dbmrq.git ~/Code/LaTeX/Classes/dbmrq
git clone https://github.com/abntex/biblatex-abnt.git ~/Code/LaTeX/Packages/biblatex-abnt

ln -s ~/Code/LaTeX/Classes ~/Library/texmf/tex/latex/classes
ln -s ~/Code/LaTeX/Packages ~/Library/texmf/tex/latex/packages
ln -s ~/Code/LaTeX/Bibliography ~/Library/texmf/bibtex/bib

echo ""
echo "Done."
echo ""
echo "---"

# }}}1

