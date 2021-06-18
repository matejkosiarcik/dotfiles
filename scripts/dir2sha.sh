#!/bin/sh
set -euf

# Usage is mainly for external HDDs to convert files into sha hashes for comparison with internal HDDs

if [ "${#}" -lt 1 ]; then
    printf 'Not enough arguments. Expected dirpath.\n' >&2
fi
input="${1}"

# traverse directory, for each file output it's name and sha1 hash
# [sorted by filenames]
find "$input" -type f -print0 |
    xargs -0 -n1 python3 -c 'import unicodedata; import sys; print(unicodedata.normalize("NFC", sys.argv[1]), end="\0")' |
    sort --version-sort --ignore-case -s --zero-terminated |
    xargs -0 -n1 shasum --binary |
    sed -E "s~^([0-9a-f]+) [ *]$input(.+)\$~\1 \2~"
