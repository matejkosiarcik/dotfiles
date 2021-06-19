#!/bin/sh
set -euf

# Usage is mainly for external HDDs to convert files into sha hashes for comparison with internal HDDs

if [ "${#}" -lt 1 ]; then
    printf 'Not enough arguments. Expected dirpath.\n' >&2
fi
input="$(printf '%s' "$1" | sed 's~/$~~' | tr -d '\n')"

# traverse directory, for each file output it's name and sha1 hash
python3 "$(dirname "$(python3 -c "import os; print(os.path.realpath('$0'))")")/dir2sha.py" "$input" |
    xargs -0 -n1 shasum --binary |
    sed -E "s~^([0-9a-f]+) [ *]$input(.+)\$~\1 \2~"
