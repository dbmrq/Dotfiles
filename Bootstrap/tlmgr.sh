#!/usr/bin/env bash

# TeX {{{1

echo ""
echo "Installing tex packages"
echo ""

sudo tlmgr update --self --all

sudo tlmgr install scheme-medium collection-humanities collection-langgreek \
collection-langother collection-latexextra collection-pictures logreq \
biblatex biber

read -p "Choose a directory for your TeX supporting files" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    osascript -e "tell application \"Terminal\" to do script \"source ${PWD}/mas.sh\""
fi

mkdir -pv ${REPLY%/}/Classes
mkdir -pv ${REPLY%/}/Packages
mkdir -pv ${REPLY%/}/Bibliography
mkdir -pv ~/Library/texmf/tex/latex
mkdir -pv ~/Library/texmf/bibtex

git clone https://github.com/dbmrq/tex-dbmrq.git ${REPLY%/}/Classes/dbmrq
git clone https://github.com/abntex/biblatex-abnt.git ${REPLY%/}/Packages/biblatex-abnt

ln -s ${REPLY%/}/Classes ~/Library/texmf/tex/latex/classes
ln -s ${REPLY%/}/Packages ~/Library/texmf/tex/latex/packages
ln -s ${REPLY%/}/Bibliography ~/Library/texmf/bibtex/bib

echo ""
echo "Done."
echo ""
echo "---"

# }}}1

