#!/bin/sh
set -euf

# macOS
if [ "$(uname -s)" = 'Darwin' ]; then
    brew update
    brew upgrade
    brew cask upgrade
    brew cleanup
fi

# Linux
if [ "$(uname -s)" = 'Linux' ]; then
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update --yes
        apt-get upgrade --yes
    fi
fi

# Python
pip3 install --upgrade pip setuptools wheel
pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip install --upgrade

# JavaScript
npm update -g

# Rust
rustup update
rustup self update || true
cargo install-update -a

# Haskell
cabal update
stack update
