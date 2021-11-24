#!/bin/sh
# Get creation date from EXIF data for input file
set -euf

usage() {
    printf 'Usage: exif-file [-h] <file>\n'
    printf ' file   filepath to analyze\n'
    printf ' -h     show help message\n'
}

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments\n\n' >&2
    usage >&2
    exit 1
fi

file="$1"
if [ ! -e "$file" ]; then
    printf 'File %s does not exist' "$file" >&2
fi

# Get photo creation date
date="$(exiftool -short -short -short -CreateDate "$file" 2>/dev/null | sed 's~:~-~g;s~\.~-~g;s~ ~_~g')"
if [ "$date" = '' ] || [ "$date" = '0000-00-00_00-00-00' ] || [ "$date" = '0000-00-00' ]; then
    date="$(exiftool -short -short -short -DateTimeOriginal "$file" 2>/dev/null | sed 's~:~-~g;s~\.~-~g;s~ ~_~g')"
fi
if [ "$date" = '' ] || [ "$date" = '0000-00-00_00-00-00' ] || [ "$date" = '0000-00-00' ]; then
    # "-FileModifyDate" is often not reliable, but better than nothing if the previous methods yield nothing
    date="$(exiftool -short -short -short -FileModifyDate "$file" 2>/dev/null | sed 's~:~-~g;s~\.~-~g;s~ ~_~g' | sed -E 's~\+.+$~~')"
fi
if [ "$date" = '0000-00-00_00-00-00' ] || [ "$date" = '0000-00-00' ]; then
    # unset date when it is bogus
    date='unknown'
fi

printf '%s\n' "$date"
