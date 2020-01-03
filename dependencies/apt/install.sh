#!/bin/sh
set -euf
cd "$(dirname "${0}")"

if command -v apt-get >/dev/null 2>&1; then
    # shellcheck disable=SC2046
    apt-get install -y $(sed -E 's~(\s*)#(.*)~~' <'apt.txt' | grep -vE '^(\s*)$')
fi
