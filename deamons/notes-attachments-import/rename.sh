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

old_extension="$(printf '%s' "$old_filename" | sed -E 's~^.*\.~~')"
new_extension="$(printf '%s' "$old_extension" | tr '[:upper:]' '[:lower:]')"
date="$(date +"%Y-%m-%d_%H-%M-%S")"
new_filename="$date.$new_extension"

# Exit on files not in proper format
if printf '%s\n' "$old_filename" | grep -E '^[0-9_\-]+( [0-9]+)?\.[a-z0-9]+$' >/dev/null; then
    exit 0
fi

# Check if the new file already exists (2 photos with the exact date taken)
i=1
if [ -e "$new_filename" ] || [ -e "$date 1.$new_extension" ] || [ -e "$date 01.$new_extension" ] || [ -e "$date 001.$new_extension" ]; then
    # If we are adding "A.jpg", but it already exists, we will add "A 2.jpg"
    # But we need to rename the former image to "A 1.jpg"
    if [ -e "$new_filename" ]; then
        if [ ! -e "$date 1.$new_extension" ] && [ ! -e "$date 01.$new_extension" ] && [ ! -e "$date 001.$new_extension" ]; then
            mv "$new_filename" "$date 1.$new_extension"
        fi
    fi
    i=2
    new_filename="$date $i.$new_extension"
fi

# Determine full filename (increment index until it doesn't exists)
while [ -e "$new_filename" ]; do
    if [ "$new_filename" = "$old_filename" ]; then
        break
    fi
    i="$((i + 1))"
    new_filename="$date $i.$new_extension"
done

if [ "$new_filename" != "$old_filename" ]; then
    mv "$old_filename" "$new_filename"
fi
