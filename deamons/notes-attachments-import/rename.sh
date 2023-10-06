#!/bin/sh
set -euf

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments to rename file\n' >&2
    usage >&2
    exit 1
fi

file="$1"
if [ ! -e "$file" ]; then
    exit 0
fi

cd "$(dirname "$file")"
old_filename="$(basename "$file")"

# Skip hidden files (leading ".")
if printf '%s' "$old_filename" | grep -E '^\.' >/dev/null; then
    exit 0
fi

# Exit on files already in proper format
if printf '%s\n' "$old_filename" | grep -E '^[0-9]{4}\-[0-9]{2}-[0-9]{2}_[0-9]+\.[a-zA-Z0-9]+$' >/dev/null; then
    exit 0
fi

old_extension="$(printf '%s' "$old_filename" | sed -E 's~^.*\.~~')"
new_extension="$(printf '%s' "$old_extension" | tr '[:upper:]' '[:lower:]')"
date="$(date +"%Y-%m-%d")"

# Check if the new file already exists (2 or more attachments imported on the same day)
i=1
i_padded="00$i"
new_filename="${date}_${i_padded}.$new_extension"
while find . -type f -name "$date\_$i_padded.*" | grep . >/dev/null; do
    i="$((i + 1))"
    if [ "$i" -ge 100 ]; then
        i_padded="$i"
    elif [ "$i" -ge 10 ]; then
        i_padded="0$i"
    else
        i_padded="00$i"
    fi
    new_filename="${date}_${i_padded}.$new_extension"
done

mv "$old_filename" "$new_filename"
