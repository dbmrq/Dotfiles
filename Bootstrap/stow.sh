#!/usr/bin/env bash

cd $(dirname `pwd`)
stow --target=$HOME --ignore=\.DS_Store */
