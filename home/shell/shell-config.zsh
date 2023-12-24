#!/usr/bin/env zsh
# shellcheck shell=bash

# shellcheck source=/dev/null
source "$(dirname "$0")/shell-config.sh"

# can not be in ".sh", because builtin is not available in classic sh
cd() {
    builtin cd "$@" && ls -A >&2
}

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias ........='cd ../../../../../..'
