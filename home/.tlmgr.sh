#!/usr/bin/env bash

# Run after installing BasicTeX

sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || \
    exit; done 2>/dev/null &


sudo tlmgr update --self --all

sudo tlmgr install scheme-medium collection-humanities collection-langgreek \
collection-langother collection-latexextra collection-pictures logreq \
biblatex biber biblatex-abnt abntex2

