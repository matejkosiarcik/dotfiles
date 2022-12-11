#!/bin/sh
set -euf
# This file updates all package-managers
# both system type and language specific

cd "$HOME" # to be sure we don't update project instead of system

update_brew() {
    brew update
    brew upgrade
    brew cleanup
}

if [ "$(uname -s)" = 'Darwin' ]; then
    printf '%s\n' '--- Brew ---'
    update_brew
    printf '%s\n' '--- macOS ---'
    softwareupdate --install --all --agree-to-license --force
elif [ "$(uname -s)" = 'Linux' ]; then
    if command -v yum >/dev/null 2>&1 && ! command -v dnf >/dev/null 2>&1; then
        printf '%s\n' '--- Yum ---'
        yum update
        yum upgrade
    fi

    if command -v apt-get >/dev/null 2>&1; then
        printf '%s\n' '--- Apt ---'
        apt-get update
        apt-get upgrade --yes
        apt-get clean
    elif command -v apk >/dev/null 2>&1; then
        printf '%s\n' '--- Apk ---'
        apk update --no-cache
    elif command -v dnf >/dev/null 2>&1; then
        printf '%s\n' '--- Dnf ---'
        dnf upgrade -y
    elif command -v pacman >/dev/null 2>&1; then
        printf '%s\n' '--- Pacman ---'
        pacman --noconfirm -Suy python python-pip make
    elif command -v swupd >/dev/null 2>&1; then
        printf '%s\n' '--- Swupd ---'
        swupd update
    elif command -v zypper >/dev/null 2>&1; then
        printf '%s\n' '--- Zypper ---'
        zypper update
    fi

    # brew can also be installed on linux
    if command -v brew >/dev/null 2>&1; then
        printf '%s\n' '--- Brew ---'
        update_brew
    fi
elif [ "$(uname -s)" = 'Windows' ]; then
    printf '%s\n' '--- Chocolatey ---'
    choco upgrade chocolatey
    choco upgrade all
fi

# JavaScript
printf '%s\n' '--- NodeJS ---'
npm update -g

# Python
printf '%s\n' '--- Python ---'
python3 -m pip install --upgrade pip setuptools wheel
# python3 -m pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 python3 -m pip install --upgrade

# Ruby
printf '%s\n' '--- Ruby ---'
gem update --system --quiet
gem update --quiet

# Rust
printf '%s\n' '--- Rust ---'
rustup update
rustup self update || true # when installed with package manager fails to self-update
cargo install-update -a

# Haskell
# printf '%s\n' '--- Haskell ---'
# cabal update
# stack update
