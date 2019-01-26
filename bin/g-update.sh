#!/bin/sh
set -euf
cd "${HOME}"

# System level package managers

if command -v brew >/dev/null 2>&1; then
    brew update                            # update brew itself
    brew upgrade && brew cleanup           # update formulas
    brew cask upgrade && brew cask cleanup # update cask formulas
    # TODO: considre removing cleanup (should be automatic in recent brew versions)
fi

# TODO: apt, yum,

# Language specific package managers

if command -v gem >/dev/null 2>&1; then
    gem update
fi

if command -v npm >/dev/null 2>&1; then
    npm update -g
fi

if command -v pip >/dev/null 2>&1; then
    pip list --outdated --format=freeze | grep -v '^\-e' | cut -d '=' -f '1' | xargs -n1 pip install -U
fi
if command -v pip2 >/dev/null 2>&1; then
    pip2 list --outdated --format=freeze | grep -v '^\-e' | cut -d '=' -f '1' | xargs -n1 pip install -U
fi
if command -v pip3 >/dev/null 2>&1; then
    pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d '=' -f '1' | xargs -n1 pip install -U
fi
