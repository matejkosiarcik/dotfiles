#!/bin/sh
set -euf

if [ "${#}" -lt 1 ]; then
    printf 'Not enough arguments. Expected dirpath.\n' >&2
fi
root="${1}"

find "${root}" -type d -mindepth 1 -maxdepth 1 -not -iname '.git' | while read -r file; do
    filename="$(printf '%s\n' "${file}" | sed "s~${root}~~" | tr '/' '|')"
    printf 'filename: %s\n' "${filename}"
    dir2sha "${file}" >"${filename}"
done
