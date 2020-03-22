#!/bin/sh
set -euf
cd "$(dirname "${0}")"

### System level packages ###

apt-get update || sudo apt-get update
if command -v apt-get >/dev/null 2>&1; then
    # shellcheck disable=SC2046
    tmpfile="$(mktemp)"
    sed -E 's~(\s*)#(.*)~~' <'apt.txt' | grep -vE '^(\s*)$' >"${tmpfile}"
    xargs apt-get install --yes <"${tmpfile}" || sudo xargs apt-get install --yes <"${tmpfile}"
    rm -f "${tmpfile}"
    curl -sL https://deb.nodesource.com/setup_13.x | bash -
    apt-get install --yes nodejs || sudo apt-get install --yes nodejs
else
    printf 'Skipping APT. Reason: No apt-get found.' >&2
fi

if [ "$(uname -s)" = 'Darwin' ]; then
    brew update
    # brew bundle # TODO: this seems to be too long for CI
else
    printf 'Skipping Homebrew. Reason: Not on macOS.' >&2
fi

# TODO: yum, choco

### Individual language packages ###

gem install bundler
bundle install --system

pip3 install --requirement 'requirements.txt'

sed -E 's~(\s*)#(.*)~~' <'npm.txt' | grep -vE '^(\s*)$' | xargs npm install --force --global
