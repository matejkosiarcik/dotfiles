#!/bin/sh
set -euf
cd "$(dirname "${0}")"

### System level packages ###

if command -v apt-get >/dev/null 2>&1; then
    # shellcheck disable=SC2046
    tmpfile="$(mktemp)"
    sed -E 's~(\s*)#(.*)~~' <'apt.txt' | grep -vE '^(\s*)$' >"${tmpfile}"
    xargs apt-get install -y <"${tmpfile}" || sudo xargs apt-get install -y <"${tmpfile}"
    rm -f "${tmpfile}"
else
    printf 'Skipping APT. Reason: No apt-get found.' >&2
fi

if [ "$(uname -s)" = 'Darwin' ]; then
    brew bundle
else
    printf 'Skipping Homebrew. Reason: Not on macOS.' >&2
fi

# TODO: yum, choco

### Individual language packages ###

bundle install --system

pip3 install --requirement 'requirements.txt'

sed -E 's~(\s*)#(.*)~~' <'npm.txt' | grep -vE '^(\s*)$' | xargs npm install --force --global
