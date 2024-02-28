#!/bin/sh
set -euf

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments to rename file\n' >&2
    usage >&2
    exit 1
fi

file="$1"
if [ ! -e "$file" ]; then
    printf 'Skipping file (not found) - %s\n' "$(basename "$file")"
    exit 0
fi

filename="$(basename "$file")"

# Exit on files not in proper format
if printf '%s\n' "$filename" | grep -vE '^.+ [0-9\-]+ at [0-9\.]+\.[a-zA-Z0-9]+$' >/dev/null; then
    printf 'Skipping file (wrong filename format) - %s\n' "$filename"
    exit 0
fi
if printf '%s\n' "$filename" | grep -vE '^Screenshot ' >/dev/null; then
    printf 'Skipping file (filename prefix mismatch) - %s\n' "$filename"
    exit 0
fi

targetdir="$HOME/Movies/Screenrecording"

mv "$file" "$targetdir/$filename"
