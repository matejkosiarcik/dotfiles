#!/bin/sh
set -euf

if [ "${#}" -lt 1 ]; then
    printf 'Not enough arguments. Expected dirpath.\n' "${PWD}" >&2
fi
input="${1}"

# traverse directory, for each file output it's name and sha1 hash
# [sorted by filenames]
find "${input}" -type f -print0 | \
    xargs -0n1 shasum | \
    sed -E "s~^([0-9a-f]+)  ${1}(.+)$~\2 \1~" | \
    sort -n | \
    sed -E 's~^(.+) ([0-9a-f]+)$~\2 \1~'
