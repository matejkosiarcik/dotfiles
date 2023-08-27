#!/bin/sh
set -euf
# This file updates all package-managers
# both system type and language specific

cd "$HOME" # to be sure we don't update project instead of system

# TODO: Add chronic from moreutils

update_brew() {
    brew update --quiet
    brew upgrade --quiet
    brew cleanup --quiet
}

if command -v brew >/dev/null 2>&1; then
    printf '%s\n' '--- Brew ---'
    update_brew
fi

if [ "$(uname -s)" = 'Linux' ]; then
    if command -v yum >/dev/null 2>&1 && ! command -v dnf >/dev/null 2>&1; then
        printf '%s\n' '--- Yum ---'
        yum update
        yum upgrade
    fi

    if command -v apt-get >/dev/null 2>&1; then
        printf '%s\n' '--- Apt ---'
        apt-get update -qq
        DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get upgrade -qq --yes
        apt-get clean -qq
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
elif [ "$(uname -s)" = 'Windows' ]; then
    printf '%s\n' '--- Chocolatey ---'
    choco upgrade chocolatey
    choco upgrade all
fi

# JavaScript
printf '%s\n' '--- NodeJS ---'
NODE_OPTIONS=--dns-result-order=ipv4first npm update -g

# Python
printf '%s\n' '--- Python ---'
python3 -m pip install --upgrade pip setuptools wheel
python3 -m pip list --outdated | tail -n +3 | cut -d ' ' -f 1 | xargs -n1 python3 -m pip install --upgrade

# Ruby
printf '%s\n' '--- Ruby ---'
gem update --system --quiet
gem update --quiet

# Rust
printf '%s\n' '--- Rust ---'
rustup update
rustup self update || true # when installed with package manager rustup fails to self-update
cargo install-update -a

# Haskell
# printf '%s\n' '--- Haskell ---'
# cabal update
# stack update

# if [ "$(uname -s)" = 'Darwin' ]; then
#     printf '%s\n' '--- macOS ---'
#     softwareupdate --install --all --agree-to-license --force
# fi
