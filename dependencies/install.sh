#!/bin/sh
set -euf
cd "$(dirname "${0}")"

## System-level package managers ##
if command -v brew >/dev/null 2>&1; then
    brew bundle
    find 'brew/' -name 'Brewfile.*' | xargs -n1 cat | brew bundle --file=-
fi

if command -v apt >/dev/null 2>&1; then
    # shellcheck disable=SC2046
    apt install -y $(sed -E 's~(\s*)#(.*)~~' <'apt.txt' | grep -vE '^(\s*)$' | tr '\n' ' ')
fi

## Language-specific package managers ##

# shellcheck disable=SC2046
npm install -g $(sed -E 's~(\s*)#(.*)~~' <'npm.txt' | grep -vE '^(\s*)$' | tr '\n' ' ')

pip3 install -r 'requirements.txt'
