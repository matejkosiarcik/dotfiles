#!/bin/sh
set -euf
cd "$(dirname "${0}")"

## System-level package managers ##
if [ "$(uname)" = 'Darwin' ]; then
    brew bundle
    find '.' -name 'Brewfile.*' | xargs -n1 cat | brew bundle --file=-
fi
