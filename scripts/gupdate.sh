#!/bin/sh
set -euf

[ "$(uname -s)" = 'Darwin' ] && \
    brew update && \
    brew upgrade && \
    brew cask upgrade && \
    brew cleanup

[ "$(uname -s)" = 'Linux' ] && command -v apt-get >/dev/null 2>&1 && \
    apt-get update --yes && \
    apt-get upgrade --yes

pip install --upgrade pip setuptools wheel
pip3 install --upgrade pip setuptools wheel
pip2 install --upgrade pip setuptools wheel

npm update -g

cargo update
cabal update
stack update
