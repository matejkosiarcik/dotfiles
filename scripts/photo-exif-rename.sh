#!/bin/sh
# Rename picture according to creation date
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

# Get photo creation date
# -CreationDate is found when exporting videos from Apple Photos (.mov)
date="$(exiftool -short -short -short -CreationDate "$file" 2>/dev/null | sed 's~:~-~g;s~\.~-~g;s~ ~_~g' | sed -E 's~\+.+$~~')"
if [ "$date" = '' ] || printf '%s' "$date" | grep '^0000-00-00' >/dev/null 2>&1; then
    # -CreateDate is found when exporting pictures from Apple Photos (.jpg, .jpeg)
    date="$(exiftool -short -short -short -CreateDate "$file" 2>/dev/null | sed 's~:~-~g;s~\.~-~g;s~ ~_~g' | sed -E 's~\+.+$~~')"
fi
if [ "$date" = '' ] || printf '%s' "$date" | grep '^0000-00-00' >/dev/null 2>&1; then
    date="$(exiftool -short -short -short -DateTimeOriginal "$file" 2>/dev/null | sed 's~:~-~g;s~\.~-~g;s~ ~_~g' | sed -E 's~\+.+$~~')"
fi
if [ "$date" = '' ] || printf '%s' "$date" | grep '^0000-00-00' >/dev/null 2>&1; then
    # "-FileModifyDate" is often not reliable, but better than nothing (in case all previous methods yield nothing)
    date="$(exiftool -short -short -short -FileModifyDate "$file" 2>/dev/null | sed 's~:~-~g;s~\.~-~g;s~ ~_~g' | sed -E 's~\+.+$~~')"
fi
if [ "$date" = '' ] || printf '%s' "$date" | grep '^0000-00-00' >/dev/null 2>&1; then
    # unset date when it is nonsense
    date='Unknown'
fi

if [ "$date" = 'Unknown' ]; then
    printf 'ERROR: Unknown date for file %s\n' "$file" >&2
    exit 1
fi

cd "$(dirname "$file")"

old_filename="$(basename "$file")"
old_extension="$(printf '%s' "$old_filename" | sed -E 's~^.*\.~~')"
new_extension="$(printf '%s' "$old_extension" | tr '[:upper:]' '[:lower:]')"
if [ "$new_extension" = 'jpeg' ]; then
    new_extension='jpg'
fi
new_filename="$date.$new_extension"

# Ignore files with properly formatted name
if [ "$new_filename" = "$old_filename" ] || printf '%s\n' "$old_filename" | grep "$date"; then
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
