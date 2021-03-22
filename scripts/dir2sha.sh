#!/bin/sh
set -euf

# Usage is mainly for external HDDs to convert files into sha hashes for comparison with internal HDDs

if [ "${#}" -lt 1 ]; then
    printf 'Not enough arguments. Expected dirpath.\n' >&2
fi
input="${1}"

# traverse directory, for each file output it's name and sha1 hash
# [sorted by filenames]
find "${input}" -type f -print0 |
    xargs -0n1 shasum |
    sed -E "s~^([0-9a-f]+)  ${input}(.+)\$~\2 \1~" |
    sort -n |
    sed -E 's~^(.+) ([0-9a-f]+)$~\2 \1~'
