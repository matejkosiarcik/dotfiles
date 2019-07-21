#!/bin/sh
set -euf
cd "$(dirname "${0}")"

# shellcheck disable=SC2046
npm install -g $(sed -E 's~(\s*)#(.*)~~' <'npm.txt' | grep -vE '^(\s*)$' | tr '\n' ' ')
