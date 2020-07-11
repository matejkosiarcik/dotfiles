#!/bin/sh
set -euf

if [ "$(uname -s)" = 'Darwin' ]; then
    brew update
    brew upgrade
    brew cask upgrade
    brew cleanup
    softwareupdate --install --all
elif [ "$(uname -s)" = 'Linux' ]; then
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get upgrade --yes
        apt-get clean
    elif command -v apk >/dev/null 2>&1; then
        apk update
    elif command -v dnf >/dev/null 2>&1; then
        dnf upgrade -y
    elif command -v yum >/dev/null 2>&1 && ! command -v dnf >/dev/null 2>&1; then
        yum update
        yum upgrade
    fi
elif [ "$(uname -s)" = 'Windows' ]; then
    choco upgrade chocolatey
    choco upgrade all
fi

# Python
pip3 install --upgrade pip setuptools wheel
pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install --upgrade

# JavaScript
npm update -g

# Rust
rustup update
rustup self update || true
cargo install-update -a

# Haskell
cabal update
stack update
