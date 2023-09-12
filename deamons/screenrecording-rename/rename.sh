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
if printf '%s\n' "$old_filename" | grep -vE '^.+ [0-9\-]+ at [0-9\.]+\.[a-zA-Z0-9]+$' >/dev/null; then
    printf 'Skip %s\n' "$old_filename"
    exit 0
fi

date="$(printf '%s\n' "$(basename "$file")" | sed -E 's~^.+ ([0-9]{4})-([0-9]{2})-([0-9]{2}) at ([0-9]{2})\.([0-9]{2})\.([0-9]{2})( \([0-9]+\))?\.[a-zA-Z0-9]+$~\1-\2-\3_\4-\5-\6~')"
extension="$(printf '%s\n' "$(basename "$file")" | sed -E 's~^.+\.([a-zA-Z0-9]+)$~\1~')"
new_filename="$date.$extension"

if [ "$new_filename" != "$old_filename" ]; then
    mv "$old_filename" "$new_filename"
fi
