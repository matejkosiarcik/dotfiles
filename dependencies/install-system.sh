#!/bin/sh
set -euf
cd "$(dirname "${0}")"

### System level packages ###

if [ "$(uname -s)" = 'Linux' ] && command -v yum >/dev/null 2>&1; then
    command -v dnf >/dev/null 2>&1 || yum install -y dnf
fi

if [ "$(uname -s)" = 'Linux' ]; then
    if command -v apt-get >/dev/null 2>&1; then
        sed -E 's~(\s*)#(.*)~~g' <'apt.txt' | grep -vE '^(\s*)$' | xargs sudo apt-get install --yes
    elif command -v apk >/dev/null 2>&1; then
        sed -E 's~(\s*)#(.*)~~g' <'apt.txt' | grep -vE '^(\s*)$' | xargs apk add
    elif command -v dnf >/dev/null 2>&1; then
        sed -E 's~(\s*)#(.*)~~g' <'apt.txt' | grep -vE '^(\s*)$' | xargs dnf install -y
    fi
fi

if [ "$(uname -s)" = 'Darwin' ]; then
    brew update
    brew bundle
fi
