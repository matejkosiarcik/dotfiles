#!/bin/sh
# A script to get creation date from exif data for given file (most likely for pictures)
set -euf

usage() {
    printf 'Usage: exiff [-h] [-f] [-v] <file>\n'
    printf ' file   filepath to analyze\n'
    printf ' -h     show help message\n'
    printf ' -f     force rename (auto confirm renaming files)\n'
    printf ' -v     verbose logging\n'
}

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments\n\n' >&2
    usage >&2
    exit 1
fi

mode='n'
verbose='0'
while getopts "h?n?f?v?" opt; do
    case "$opt" in
    h)
        usage
        ;;
    n)
        mode='n'
        ;;
    f)
        mode='f'
        ;;
    v)
        verbose='1'
        ;;
    *)
        usage >&2
        exit 1
        ;;
    esac
done
shift "$((OPTIND - 1))"

file="$1"
if [ ! -e "$file" ]; then
    printf 'File %s does not exist\n' "$file" >&2
    exit 1
fi

if [ "$verbose" = '1' ]; then
    printf 'file: %s\n' "$file"
    printf 'mode: %s\n' "$mode"
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
    # unset date when it is nonsense
    date='unknown'
fi

filedir="$(dirname "$file")"
filename="$(basename "$file")"
file_extension_old="$(printf '%s' "$filename" | sed -E 's~^.*\.~~')"
file_extension_new="$(printf '%s' "$file_extension_old" | tr '[:upper:]' '[:lower:]')"
cd "$filedir"

printf '%s\n' "$date"

if [ "$mode" = 'n' ]; then
    printf '%s: %s\n' "$date" "$filename" >&2
elif [ "$mode" = 'f' ]; then

    if [ "$date" != 'unknown' ]; then
        printf '%s: %s\n' "$date" "$filename" >&2

        if [ "$mode" = 'f' ]; then
            newfilename="$date.$file_extension_new"

            if [ "$newfilename" != "$filename" ]; then
                # Check if the new file already exists (2 photos with the exact date taken)
                # In such case name the second photo with an iterator suffix
                i=0
                while [ -e "$newfilename" ]; do
                    i="$((i + 1))"
                    newfilename="$date $i.$file_extension_new"
                done

                mv "$filename" "$newfilename"
            fi
        fi
    else
        printf 'ERROR: No date for %s\n' "$filename" >&2
    fi
fi
