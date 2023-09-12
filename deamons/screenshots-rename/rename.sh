#!/bin/sh
set -euf

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments\n\n' >&2
    usage >&2
    exit 1
fi

file="$1"
if [ ! -e "$file" ]; then
    printf 'Input file %s does not exist\n' "$file" >&2
    exit 1
fi

cd "$(dirname "$file")"

old_filename="$(basename "$file")"

# Exit on files not in proper format
if printf '%s\n' "$old_filename" | grep -vE '^.+ [0-9\-]+ at [0-9\.]+( \([0-9]+\))?\.png$' >/dev/null; then
    exit 0
fi

date="$(printf '%s\n' "$(basename "$file")" | sed -E 's~^.+ ([0-9]{4})-([0-9]{2})-([0-9]{2}) at ([0-9]{2})\.([0-9]{2})\.([0-9]{2})( \([0-9]+\))?\.png$~\1-\2-\3_\4-\5-\6~')"
new_filename="$date.png"

# Check if the new file already exists (taken screenshots of multiple displays)
if [ -e "$date 2.png" ] || [ -e "$date 3.png" ] || [ -e "$date 4.png" ]; then
    new_filename="$date 1.png"
fi

if printf '%s\n' "$old_filename" | grep -E '^.+ [0-9\-]+ at [0-9\.]+ \([0-9]+\)\.png$' >/dev/null; then
    index="$(printf '%s\n' "$old_filename" | sed -E 's~^.+ [0-9\-]+ at [0-9\.]+ \(([0-9]+)\)\.png$~\1~')"
    new_filename="$date $index.png"

    # Check if the new file already exists (taken screenshots of multiple displays)
    if [ -e "$date.png" ]; then
        mv "$date.png" "$date 1.png"
    fi
fi

if [ "$new_filename" != "$old_filename" ]; then
    mv "$old_filename" "$new_filename"
fi
