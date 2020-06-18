#!/bin/sh
set -euf

if [ "$(uname -s)" = 'Darwin' ]; then
    brew update
    brew upgrade
    brew cask upgrade
    brew cleanup
fi

if [ "$(uname -s)" = 'Linux' ]; then
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update --yes
        apt-get upgrade --yes
    fi
fi

pip install --upgrade pip setuptools wheel
pip3 install --upgrade pip setuptools wheel
pip2 install --upgrade pip setuptools wheel

npm update -g

cargo update
cabal update
stack update
