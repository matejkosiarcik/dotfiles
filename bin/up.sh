#!/bin/sh
set -euf
cd "${HOME}"

## System level package managers ##

if command -v brew >/dev/null 2>&1; then
    brew update                            # update brew itself
    brew upgrade && brew cleanup           # update formulas
    brew cask upgrade && brew cask cleanup # update cask formulas
fi

if command -v apt >/dev/null 2>&1; then
    sudo apt update
    sudo apt upgrade
fi

if command -v yum >/dev/null 2>&1; then
    yum update
fi

## Language specific package managers ##

gem update
npm update -g
pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d '=' -f '1' | xargs -n1 pip install --upgrade
