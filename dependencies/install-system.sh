#!/bin/sh
set -euf
cd "$(dirname "${0}")"

### System level packages ###

if [ "$(uname -s)" = 'Linux' ] && command -v yum >/dev/null 2>&1; then
    command -v dnf >/dev/null 2>&1 || yum install -y dnf;
fi

if [ "$(uname -s)" = 'Linux' ] && command -v apt-get >/dev/null 2>&1; then
    sed -E 's~(\s*)#(.*)~~g' <'apt.txt' | grep -vE '^(\s*)$' | xargs sudo apt-get install --yes
elif [ "$(uname -s)" = 'Linux' ] && command -v apk >/dev/null 2>&1; then
    sed -E 's~(\s*)#(.*)~~g' <'apt.txt' | grep -vE '^(\s*)$' | xargs apk add
elif [ "$(uname -s)" = 'Linux' ] && command -v dnf >/dev/null 2>&1; then
    sed -E 's~(\s*)#(.*)~~g' <'apt.txt' | grep -vE '^(\s*)$' | xargs dnf install -y
else
    printf 'Skipping APT. (not linux)\n' >&2
fi

if [ "$(uname -s)" = 'Darwin' ]; then
    if command -v brew >/dev/null 2>&1; then
        brew update
        brew bundle
    else
        printf 'Homebrew not found. Make sure Xcode and homebrew are installed.\n' >&2
    fi
else
    printf 'Skipping Homebrew. (not macOS)\n' >&2
fi
