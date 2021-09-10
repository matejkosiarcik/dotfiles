#!/bin/sh
set -euf

# Wrapper around dir2sha for multiple root directories

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments. Expected dirpath.\n' >&2
fi
root="${1}"

find "$root" -mindepth 1 -maxdepth 1 -type d -not -iname '.git' | sort --version-sort --ignore-case -s | while read -r directory; do
    filename="$(basename "$directory")"
    printf 'Reading: %s\n' "$filename"
    dir2sha "$directory" >"$filename.txt"
done
