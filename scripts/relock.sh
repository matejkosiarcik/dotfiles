#!/bin/sh
set -euf

# Recreate package-lock.json and reinstall packages
# Works in CWD

find . \( -type d -name 'node_modules' -prune \) -exec rm -rf {} \;
find . -type f -name 'package-lock.json' -print0 | xargs -0 -n1 sh -c 'printf "Relocking %s\n" "${1}" && rm -f "${1}" && npm install --prefix "$(dirname "${1}")" && npm dedupe --prefix "$(dirname "${1}")"' _
