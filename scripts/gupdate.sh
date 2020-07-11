#!/bin/sh
set -euf

update_brew() {
    brew update
    brew upgrade
    brew cask upgrade
    brew cleanup
}

if [ "$(uname -s)" = 'Darwin' ]; then
    printf '%s\n' '--- Brew ---'
    update_brew
    printf '%s\n' '--- macOS ---'
    softwareupdate --install --all
elif [ "$(uname -s)" = 'Linux' ]; then
    if command -v apt-get >/dev/null 2>&1; then
        printf '%s\n' '--- Apt ---'
        apt-get update
        apt-get upgrade --yes
        apt-get clean
    elif command -v apk >/dev/null 2>&1; then
        printf '%s\n' '--- Apk ---'
        apk update
    elif command -v dnf >/dev/null 2>&1; then
        printf '%s\n' '--- Dnf ---'
        dnf upgrade -y
    elif command -v yum >/dev/null 2>&1 && ! command -v dnf >/dev/null 2>&1; then
        printf '%s\n' '--- Yum ---'
        yum update
        yum upgrade
    fi

    # brew can also be installed on linux
    if command -v brew >/dev/null 2>&1; then
        printf '%s\n' '--- Brew ---'
        update_brew
    fi
elif [ "$(uname -s)" = 'Windows' ]; then
    printf '%s\n' '--- Choco ---'
    choco upgrade chocolatey
    choco upgrade all
fi

# Python
printf '%s\n' '--- Pip ---'
pip3 install --upgrade pip setuptools wheel
pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install --upgrade

# JavaScript
printf '%s\n' '--- Npm ---'
npm update -g

# Rust
printf '%s\n' '--- Rustup ---'
rustup update
rustup self update || true # when installed with package manager fails to self-update
printf '%s\n' '--- Cargo ---'
cargo install-update -a

# Haskell
printf '%s\n' '--- Cabal ---'
cabal update
# cabal install cabal-install
printf '%s\n' '--- Stack ---'
stack update
